//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

struct CommandError: Error {
  var commandStack: [ParsableCommand.Type]
  var parserError: ParserError
}

struct HelpRequested: Error {}

struct CommandParser {
  let commandTree: Tree<ParsableCommand.Type>
  var currentNode: Tree<ParsableCommand.Type>
  var decodedArguments: [DecodedArguments] = []
  
  var commandStack: [ParsableCommand.Type] {
    let result = decodedArguments.compactMap { $0.commandType }
    if currentNode.element == result.last {
      return result
    } else {
      return result + [currentNode.element]
    }
  }
  
  init(_ rootCommand: ParsableCommand.Type) {
    self.commandTree = Tree(root: rootCommand)
    self.currentNode = commandTree
    
    // A command tree that has a depth greater than zero gets a `help`
    // subcommand.
    if !commandTree.isLeaf {
      commandTree.addChild(Tree(HelpCommand.self))
    }
  }
}

extension CommandParser {
  /// Consumes the next argument in `split` if it matches a subcommand at the
  /// current node of the command tree.
  ///
  /// If a matching subcommand is found, the subcommand argument is consumed
  /// in `split`.
  ///
  /// - Returns: A node for the matched subcommand if one was found;
  ///   otherwise, `nil`.
  fileprivate func consumeNextCommand(split: inout SplitArguments) -> Tree<ParsableCommand.Type>? {
    guard let (origin, element) = split.peekNext(),
      element.isValue,
      let value = split.originalInput(at: origin),
      let subcommandNode = currentNode.firstChild(withName: value)
    else { return nil }
    _ = split.popNextValue()
    return subcommandNode
  }
  
  /// Throws a `HelpRequested` error if the user has specified either of the
  /// built in help flags.
  func checkForBuiltInFlags(_ split: SplitArguments) throws {
    // Look for help flags
    guard !split.contains(anyOf: self.commandTree.element.getHelpNames()) else {
      throw HelpRequested()
    }

    // Look for --version if any commands in the stack define a version
    if commandStack.contains(where: { !$0.configuration.version.isEmpty }) {
      guard !split.contains(Name.long("version")) else {
        throw CommandError(commandStack: commandStack, parserError: .versionRequested)
      }
    }
    
    if let completionArgument = split.argument(named: Name.long("generate-completion")) {
      switch completionArgument {
      case .name:
        throw CommandError(commandStack: commandStack, parserError: .completionScriptRequested(shell: nil))
      case .nameWithValue(_, let value):
        throw CommandError(commandStack: commandStack, parserError: .completionScriptRequested(shell: value))
      }
      
    }
  }
  
  func handleCustomCompletion(_ arguments: [String]) throws {
    // Completion functions use a custom format:
    //
    // <command> ---completion [<subcommand> ...] -- <argument-name> [<completion-text>]
    //
    // The triple-dash prefix makes '---completion' invalid syntax for regular
    // arguments, so it's safe to use for this internal purpose.
    guard arguments.first == "---completion"
      else { return }
    
    var args = arguments.dropFirst()
    var current = commandTree
    while let subcommandName = args.popFirst() {
      // A double dash separates the subcommands from the argument information
      if subcommandName == "--" { break }
      
      guard let nextCommandNode = current.firstChild(withName: subcommandName)
        else { throw ParserError.invalidState }
      current = nextCommandNode
    }
    
    // Some kind of argument name is the next required element
    guard let argToMatch = args.popFirst() else {
      throw ParserError.invalidState
    }
    // Completion text is optional here
    let completionValue = args.popFirst() ?? ""
    
    // There should be no more arguments remaining at this point
    guard args.isEmpty else { throw ParserError.invalidState }

    // Generate the argument set and parse the argument to find in the set
    let argset = ArgumentSet(current.element)
    let (index, parsedArgument) = try! parseIndividualArg(argToMatch, at: 0).first!
    
    // Look up the specified argument and retrieve its custom completion function
    guard case .option(let parsed) = parsedArgument,
      let matchedArgument = try? argset.first(matching: parsed, at: .argumentIndex(index)),
      case .custom(let completionFunction) = matchedArgument.completion
      else { throw ParserError.invalidState }
    
    // Parsing and retrieval successful! We don't want to continue with any
    // other parsing here, so after printing the result of the completion
    // function, exit with a success code.
    print(completionFunction(completionValue).joined(separator: "\n"))
    throw ParserError.userValidationError(ExitCode.success)
  }
  
  /// Returns the last parsed value if there are no remaining unused arguments.
  ///
  /// If there are remaining arguments or if no commands have been parsed,
  /// this throws an error.
  fileprivate func extractLastParsedValue(_ split: SplitArguments) throws -> ParsableCommand {
    try checkForBuiltInFlags(split)
    
    // We should have used up all arguments at this point:
    guard split.isEmpty else {
      // Check if one of the arguments is an unknown option
      for (index, element) in split.elements {
        if case .option(let argument) = element {
          throw ParserError.unknownOption(InputOrigin.Element.argumentIndex(index), argument.name)
        }
      }
       
      let extra = split.coalescedExtraElements()
      throw ParserError.unexpectedExtraValues(extra)
    }
    
    guard let lastCommand = decodedArguments.lazy.compactMap({ $0.command }).last else {
      throw ParserError.invalidState
    }
    
    return lastCommand
  }
  
  /// Extracts the current command from `split`, throwing if decoding isn't
  /// possible.
  fileprivate mutating func parseCurrent(_ split: inout SplitArguments) throws -> ParsableCommand {
    // Build the argument set (i.e. information on how to parse):
    let commandArguments = ArgumentSet(currentNode.element)
    
    // Parse the arguments into a ParsedValues:
    let parsedResult = try commandArguments.lenientParse(split)
    
    let values: ParsedValues
    switch parsedResult {
    case .success(let v):
      values = v
    case .partial(let v, let e):
      values = v
      if currentNode.isLeaf {
        throw e
      }
    }
    
    // Decode the values from ParsedValues into the ParsableCommand:
    let decoder = ArgumentDecoder(values: values, previouslyDecoded: decodedArguments)
    var decodedResult: ParsableCommand
    do {
      decodedResult = try currentNode.element.init(from: decoder)
    } catch let error {
      // If decoding this command failed, see if they were asking for
      // help before propagating that parsing failure.
      try checkForBuiltInFlags(split)
      throw error
    }
    
    // Decoding was successful, so remove the arguments that were used
    // by the decoder.
    split.removeAll(in: decoder.usedOrigins)
    
    // Save the decoded results to add to the next command.
    let newDecodedValues = decoder.previouslyDecoded
      .filter { prev in !decodedArguments.contains(where: { $0.type == prev.type })}
    decodedArguments.append(contentsOf: newDecodedValues)
    decodedArguments.append(DecodedArguments(type: currentNode.element, value: decodedResult))

    return decodedResult
  }
  
  /// Starting with the current node, extracts commands out of `split` and
  /// descends into subcommands as far as possible.
  internal mutating func descendingParse(_ split: inout SplitArguments) throws {
    while true {
      var parsedCommand = try parseCurrent(&split)

      // after decoding a command, make sure to validate it
      do {
        try parsedCommand.validate()
      } catch {
        throw CommandError(commandStack: commandStack, parserError: ParserError.userValidationError(error))
      }

      // Look for next command in the argument list.
      if let nextCommand = consumeNextCommand(split: &split) {
        currentNode = nextCommand
        continue
      }
      
      // Look for the help flag before falling back to a default command.
      try checkForBuiltInFlags(split)
      
      // No command was found, so fall back to the default subcommand.
      if let defaultSubcommand = currentNode.element.configuration.defaultSubcommand {
        guard let subcommandNode = currentNode.firstChild(equalTo: defaultSubcommand) else {
          throw ParserError.invalidState
        }
        currentNode = subcommandNode
        continue
      }
      
      // No more subcommands to parse.
      return
    }
  }
  
  /// Returns the fully-parsed matching command for `arguments`, or an
  /// appropriate error.
  ///
  /// - Parameter arguments: The array of arguments to parse. This should not
  ///   include the command name as the first argument.
  mutating func parse(arguments: [String]) -> Result<ParsableCommand, CommandError> {
    do {
      try handleCustomCompletion(arguments)
    } catch {
      return .failure(CommandError(commandStack: [commandTree.element], parserError: error as! ParserError))
    }
    
    var split: SplitArguments
    do {
      split = try SplitArguments(arguments: arguments)
    } catch let error as ParserError {
      return .failure(CommandError(commandStack: [commandTree.element], parserError: error))
    } catch {
      return .failure(CommandError(commandStack: [commandTree.element], parserError: .invalidState))
    }
    
    do {
      try descendingParse(&split)
      let result = try extractLastParsedValue(split)
      
      // HelpCommand is a valid result, but needs extra information about
      // the tree from the parser to build its stack of commands.
      if var helpResult = result as? HelpCommand {
        try helpResult.buildCommandStack(with: self)
        return .success(helpResult)
      }
      return .success(result)
    } catch let error as CommandError {
      return .failure(error)
    } catch let error as ParserError {
      return .failure(CommandError(commandStack: commandStack, parserError: error))
    } catch is HelpRequested {
      return .success(HelpCommand(commandStack: commandStack))
    } catch {
      return .failure(CommandError(commandStack: commandStack, parserError: .invalidState))
    }
  }
}

extension CommandParser {
  /// Builds an array of commands that matches the given command names.
  ///
  /// This stops building the stack if it encounters any command names that
  /// aren't in the command tree, so it's okay to pass a list of arbitrary
  /// commands. Will always return at least the root of the command tree.
  func commandStack(for commandNames: [String]) -> [ParsableCommand.Type] {
    var node = commandTree
    var result = [node.element]
    
    for name in commandNames {
      guard let nextNode = node.firstChild(withName: name) else {
        // Reached a non-command argument.
        // Ignore anything after this point
        return result
      }
      result.append(nextNode.element)
      node = nextNode
    }
    
    return result
  }
  
  func commandStack(for subcommand: ParsableCommand.Type) -> [ParsableCommand.Type] {
    let path = commandTree.path(to: subcommand)
    return path.isEmpty
      ? [commandTree.element]
      : path
  }
}

extension SplitArguments {
  func contains(_ needle: Name) -> Bool {
    self.elements.contains {
      switch $0.element {
      case .option(.name(let name)),
           .option(.nameWithValue(let name, _)):
        return name == needle
      default:
        return false
      }
    }
  }

  func argument(named needle: Name) -> ParsedArgument? {
    guard let element = elements.first(where: {
      switch $0.element {
      case .option(.name(let name)),
           .option(.nameWithValue(let name, _)):
        return name == needle
      default:
        return false
      }
    })?.element else {
      return nil
    }
    
    switch element {
    case .option(let argument):
      return argument
    case .value, .terminator:
      return nil
    }
  }
  
  func contains(anyOf names: [Name]) -> Bool {
    self.elements.contains {
      switch $0.element {
      case .option(.name(let name)),
           .option(.nameWithValue(let name, _)):
        return names.contains(name)
      default:
        return false
      }
    }
  }
}
