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
  func checkForHelpFlag(_ split: SplitArguments) throws {
    guard !split.contains(anyOf: self.commandTree.element.getHelpNames()) else {
      throw HelpRequested()
    }
  }
  
  /// Returns the last parsed value if there are no remaining unused arguments.
  ///
  /// If there are remaining arguments or if no commands have been parsed,
  /// this throws an error.
  fileprivate func extractLastParsedValue(_ split: SplitArguments) throws -> ParsableCommand {
    try checkForHelpFlag(split)
    
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
  fileprivate mutating func parseCurrent(_ split: inout SplitArguments) throws {
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
      try checkForHelpFlag(split)
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
  }
  
  /// Starting with the current node, extracts commands out of `split` and
  /// descends into subcommands as far as possible.
  internal mutating func descendingParse(_ split: inout SplitArguments) throws {
    while true {
      try parseCurrent(&split)
      
      // Look for next command in the argument list.
      if let nextCommand = consumeNextCommand(split: &split) {
        currentNode = nextCommand
        continue
      }
      
      // Look for the help flag before falling back to a default command.
      try checkForHelpFlag(split)
      
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
