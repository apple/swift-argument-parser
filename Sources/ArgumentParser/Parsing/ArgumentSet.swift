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

/// A nested tree of argument definitions.
///
/// The main reason for having a nested representation is to build help output.
/// For output like:
///
///     Usage: mytool [-v | -f] <input> <output>
///
/// The `-v | -f` part is one *set* that’s optional, `<input> <output>` is
/// another. Both of these can then be combined into a third set.
struct ArgumentSet {
  enum Content {
    /// A leaf list of arguments.
    case arguments([ArgumentDefinition])
    /// A node with additional `[ArgumentSet]`
    case sets([ArgumentSet])
  }
  var content: Content
  var kind: Kind
  
  /// Used to generate _help_ text.
  enum Kind {
    /// Independent
    case additive
    /// Mutually exclusive
    case exclusive
    /// Several ways of achieving the same behavior. Should only display one.
    case alternatives
  }
  
  init(arguments: [ArgumentDefinition], kind: Kind) {
    self.content = .arguments(arguments)
    self.kind = kind
    // TODO: Move this check into a separate validation pass for completed
    // argument sets.
    precondition(
      self.hasValidArguments,
      "Can't have a positional argument following an array of positional arguments.")
  }
  
  init(sets: [ArgumentSet], kind: Kind) {
    self.content = .sets(sets)
    self.kind = kind
    precondition(
      self.hasValidArguments,
      "Can't have a positional argument following an array of positional arguments.")
  }
}

extension ArgumentSet: CustomDebugStringConvertible {
  var debugDescription: String {
    switch content {
    case .arguments(let args):
      return args
        .map { $0.debugDescription }
        .joined(separator: " / ")
    case .sets(let sets):
      return sets
        .map { "{\($0.debugDescription)}" }
        .joined(separator: " / ")
    }
  }
}

extension ArgumentSet {
  init() {
    self.init(arguments: [], kind: .additive)
  }
  
  init(_ arg: ArgumentDefinition) {
    self.init(arguments: [arg], kind: .additive)
  }
  
  init(additive args: [ArgumentDefinition]) {
    self.init(arguments: args, kind: .additive)
  }
  
  init(exclusive args: [ArgumentDefinition]) {
    self.init(arguments: args, kind: args.count == 1 ? .additive : .exclusive)
  }
  
  init(alternatives args: [ArgumentDefinition]) {
    self.init(arguments: args, kind: args.count == 1 ? .additive : .alternatives)
  }
  
  init(additive sets: [ArgumentSet]) {
    self.init(sets: sets, kind: .additive)
  }
}

extension ArgumentSet {
  var hasPositional: Bool {
    switch content {
    case .arguments(let arguments):
      return arguments.contains(where: { $0.isPositional })
    case .sets(let sets):
      return sets.contains(where: { $0.hasPositional })
    }
  }
  
  var hasRepeatingPositional: Bool {
    switch content {
    case .arguments(let arguments):
      return arguments.contains(where: { $0.isRepeatingPositional })
    case .sets(let sets):
      return sets.contains(where: { $0.hasRepeatingPositional })
    }
  }
  
  /// A Boolean value indicating whether this set has valid positional
  /// arguments.
  ///
  /// For positional arguments to be valid, there must be at most one
  /// positional array argument, and it must be the last positional argument
  /// in the argument list. Any other configuration leads to ambiguity in
  /// parsing the arguments.
  var hasValidArguments: Bool {
    // Exclusive and alternative argument sets must each individually
    // satisfy this requirement.
    guard kind == .additive else {
      switch content {
      case .arguments: return true
      case .sets(let sets): return sets.allSatisfy({ $0.hasValidArguments })
      }
    }
    
    switch content {
    case .arguments(let arguments):
      guard let repeatedPositional = arguments.firstIndex(where: { $0.isRepeatingPositional })
        else { return true }
      
      let hasPositionalFollowingRepeated = arguments[repeatedPositional...]
        .dropFirst()
        .contains(where: { $0.isPositional })
      return !hasPositionalFollowingRepeated
      
    case .sets(let sets):
      guard let repeatedPositional = sets.firstIndex(where: { $0.hasRepeatingPositional })
        else { return true }
      let hasPositionalFollowingRepeated = sets[repeatedPositional...]
        .dropFirst()
        .contains(where: { $0.hasPositional })
      
      return !hasPositionalFollowingRepeated
    }
  }
}

// MARK: Flag

extension ArgumentSet {
  /// Creates an argument set for a single Boolean flag.
  static func flag(key: InputKey, name: NameSpecification, help: ArgumentHelp?) -> ArgumentSet {
    let help = ArgumentDefinition.Help(options: .isOptional, help: help, key: key)
    let arg = ArgumentDefinition(kind: .name(key: key, specification: name), help: help, update: .nullary({ (origin, name, values) in
      values.set(true, forKey: key, inputOrigin: origin)
    }), initial: { origin, values in
      values.set(false, forKey: key, inputOrigin: origin)
    })
    return ArgumentSet(arg)
  }

  static func updateFlag<Value: Equatable>(key: InputKey, value: Value, origin: InputOrigin, values: inout ParsedValues, hasUpdated: Bool, exclusivity: FlagExclusivity) throws -> Bool {
    switch (hasUpdated, exclusivity) {
    case (true, .exclusive):
      // This value has already been set.
      if let previous = values.element(forKey: key) {
        if (previous.value as? Value) == value {
          // setting the value again will consume the argument
          values.set(value, forKey: key, inputOrigin: origin)
        }
        else {
          throw ParserError.duplicateExclusiveValues(previous: previous.inputOrigin, duplicate: origin, originalInput: values.originalInput)
        }
      }
    case (true, .chooseFirst):
      values.update(forKey: key, inputOrigin: origin, initial: value, closure: { _ in })
    case (false, _), (_, .chooseLast):
      values.set(value, forKey: key, inputOrigin: origin)
    }
    return true
  }
  
  /// Creates an argument set for a pair of inverted Boolean flags.
  static func flag(key: InputKey, name: NameSpecification, default initialValue: Bool?, inversion: FlagInversion, exclusivity: FlagExclusivity, help: ArgumentHelp?) -> ArgumentSet {
    // The flag is required if initialValue is `nil`, otherwise it's optional
    let helpOptions: ArgumentDefinition.Help.Options = initialValue != nil ? .isOptional : []
    
    let help = ArgumentDefinition.Help(options: helpOptions, help: help, defaultValue: initialValue.map(String.init), key: key)
    let (enableNames, disableNames) = inversion.enableDisableNamePair(for: key, name: name)

    var hasUpdated = false
    let enableArg = ArgumentDefinition(kind: .named(enableNames),help: help, update: .nullary({ (origin, name, values) in
        hasUpdated = try ArgumentSet.updateFlag(key: key, value: true, origin: origin, values: &values, hasUpdated: hasUpdated, exclusivity: exclusivity)
    }), initial: { origin, values in
      if let initialValue = initialValue {
        values.set(initialValue, forKey: key, inputOrigin: origin)
      }
    })
    let disableArg = ArgumentDefinition(kind: .named(disableNames), help: ArgumentDefinition.Help(options: [.isOptional], key: key), update: .nullary({ (origin, name, values) in
        hasUpdated = try ArgumentSet.updateFlag(key: key, value: false, origin: origin, values: &values, hasUpdated: hasUpdated, exclusivity: exclusivity)
    }), initial: { _, _ in })
    return ArgumentSet(exclusive: [enableArg, disableArg])
  }
  
  /// Creates an argument set for an incrementing integer flag.
  static func counter(key: InputKey, name: NameSpecification, help: ArgumentHelp?) -> ArgumentSet {
    let help = ArgumentDefinition.Help(options: [.isOptional, .isRepeating], help: help, key: key)
    let arg = ArgumentDefinition(kind: .name(key: key, specification: name), help: help, update: .nullary({ (origin, name, values) in
      guard let a = values.element(forKey: key)?.value, let b = a as? Int else {
        throw ParserError.invalidState
      }
      values.set(b + 1, forKey: key, inputOrigin: origin)
    }), initial: { origin, values in
      values.set(0, forKey: key, inputOrigin: origin)
    })
    return ArgumentSet(arg)
  }
}

// MARK: -

extension ArgumentSet {
  /// Create a unary / argument that parses the string as `A`.
  init<A: ExpressibleByArgument>(key: InputKey, kind: ArgumentDefinition.Kind, parsingStrategy: ArgumentDefinition.ParsingStrategy = .nextAsValue, parseType type: A.Type, name: NameSpecification, default initial: A?, help: ArgumentHelp?) {
    var arg = ArgumentDefinition(key: key, kind: kind, parsingStrategy: parsingStrategy, parser: A.init(argument:), default: initial)
    arg.help.help = help
    arg.help.defaultValue = initial.map { "\($0.defaultValueDescription)" }
    self.init(arg)
  }
}

extension ArgumentDefinition {
  /// Create a unary / argument that parses using the given closure.
  fileprivate init<A>(key: InputKey, kind: ArgumentDefinition.Kind, parsingStrategy: ParsingStrategy = .nextAsValue, parser: @escaping (String) -> A?, parseType type: A.Type = A.self, default initial: A?) {
    let initialValueCreator: (InputOrigin, inout ParsedValues) throws -> Void
    if let initialValue = initial {
      initialValueCreator = { origin, values in
        values.set(initialValue, forKey: key, inputOrigin: origin)
      }
    } else {
      initialValueCreator = { _, _ in }
    }
    
    self.init(kind: kind, help: ArgumentDefinition.Help(key: key), parsingStrategy: parsingStrategy, update: .unary({ (origin, name, value, values) in
      guard let v = parser(value) else {
        throw ParserError.unableToParseValue(origin, name, value, forKey: key)
      }
      values.set(v, forKey: key, inputOrigin: origin)
    }), initial: initialValueCreator)
    
    help.options.formUnion(ArgumentDefinition.Help.Options(type: type))
    help.defaultValue = initial.map { "\($0)" }
    if initial != nil {
      self = self.optional
    }
  }
}

// MARK: - Parsing from SplitArguments
extension ArgumentSet {
  /// Parse the given input (`SplitArguments`) for the given `commandStack` of previously parsed commands.
  ///
  /// This method will gracefully fail if there are extra arguments that it doesn’t understand. Hence the
  /// *lenient* name. If so, it will return `.partial`.
  ///
  /// When dealing with commands, this will be called iteratively in order to find
  /// the matching command(s).
  ///
  /// - Parameter all: The input (from the command line) that needs to be parsed
  /// - Parameter commandStack: commands that have been parsed
  func lenientParse(_ all: SplitArguments) throws -> LenientParsedValues {
    // Create a local, mutable copy of the arguments:
    var inputArguments = all
    
    func parseValue(
      _ argument: ArgumentDefinition,
      _ parsed: ParsedArgument,
      _ originElement: InputOrigin.Element,
      _ update: ArgumentDefinition.Update.Unary,
      _ result: inout ParsedValues,
      _ usedOrigins: inout InputOrigin
    ) throws {
      let origin = InputOrigin(elements: [originElement])
      switch argument.parsingStrategy {
      case .nextAsValue:
        // We need a value for this option.
        if let value = parsed.value {
          // This was `--foo=bar` style:
          try update(origin, parsed.name, value, &result)
        } else if let (origin2, value) = inputArguments.popNextElementIfValue(after: originElement) {
          // Use `popNextElementIfValue(after:)` to handle cases where short option
          // labels are combined
          let origins = origin.inserting(origin2)
          try update(origins, parsed.name, value, &result)
          usedOrigins.formUnion(origins)
        } else {
          throw ParserError.missingValueForOption(origin, parsed.name)
        }
        
      case .scanningForValue:
        // We need a value for this option.
        if let value = parsed.value {
          // This was `--foo=bar` style:
          try update(origin, parsed.name, value, &result)
        } else if let (origin2, value) = inputArguments.popNextValue(after: originElement) {
          // Use `popNext(after:)` to handle cases where short option
          // labels are combined
          let origins = origin.inserting(origin2)
          try update(origins, parsed.name, value, &result)
          usedOrigins.formUnion(origins)
        } else {
          throw ParserError.missingValueForOption(origin, parsed.name)
        }
        
      case .unconditional:
        // Use an attached value if it exists...
        if let value = parsed.value {
          // This was `--foo=bar` style:
          try update(origin, parsed.name, value, &result)
          usedOrigins.formUnion(origin)
        } else {
          guard let (origin2, value) = inputArguments.popNextElementAsValue(after: originElement) else {
            throw ParserError.missingValueForOption(origin, parsed.name)
          }
          let origins = origin.inserting(origin2)
          try update(origins, parsed.name, value, &result)
          usedOrigins.formUnion(origins)
        }
        
      case .allRemainingInput:
        // Reset initial value with the found input origins:
        try argument.initial(origin, &result)
        
        // Use an attached value if it exists...
        if let value = parsed.value {
          // This was `--foo=bar` style:
          try update(origin, parsed.name, value, &result)
          usedOrigins.formUnion(origin)
        }
        
        // ...and then consume the rest of the arguments
        while let (origin2, value) = inputArguments.popNextElementAsValue(after: originElement) {
          let origins = origin.inserting(origin2)
          try update(origins, parsed.name, value, &result)
          usedOrigins.formUnion(origins)
        }
        
      case .upToNextOption:
        // Reset initial value with the found source index
        try argument.initial(origin, &result)
        
        // Use an attached value if it exists...
        if let value = parsed.value {
          // This was `--foo=bar` style:
          try update(origin, parsed.name, value, &result)
          usedOrigins.formUnion(origin)
        }
        
        // ...and then consume the arguments until hitting an option
        while let (origin2, value) = inputArguments.popNextElementIfValue() {
          let origins = origin.inserting(origin2)
          try update(origins, parsed.name, value, &result)
          usedOrigins.formUnion(origins)
        }
      }
    }
    
    var result = ParsedValues(elements: [], originalInput: all.originalInput)
    var positionalValues: [(InputOrigin.Element, String)] = []
    var unusedOptions: [(InputOrigin.Element, String)] = []
    var usedOrigins = InputOrigin()
    
    try setInitialValues(into: &result)
    
    // Loop over all arguments:
    while let (origin, next) = inputArguments.popNext() {
      defer {
        inputArguments.removeAll(in: usedOrigins)
      }
      
      switch next {
      case let .value(v):
        positionalValues.append((origin, v))
      case let .option(parsed):
        // Look for an argument that matches this `--option` or `-o`-style
        // input. If we can't find one, just move on to the next input. We
        // defer catching leftover arguments until we've fully extracted all
        // the information for the selected command.
        guard
          let argument: ArgumentDefinition = try? first(matching: parsed, at: origin)
          else {
            unusedOptions.append((origin, all.originalInput(at: origin)))
            continue
          }
        
        switch argument.update {
        case let .nullary(update):
          // We don’t expect a value for this option.
          guard parsed.value == nil else {
            throw ParserError.unexpectedValueForOption(origin, parsed.name, parsed.value!)
          }
          try update([origin], parsed.name, &result)
          usedOrigins.insert(origin)
        case let .unary(update):
          try parseValue(argument, parsed, origin, update, &result, &usedOrigins)
        }
      case .terminator:
        // Mark the terminator as used:
        result.set(ParsedValues.Element(key: .terminator, value: 0, inputOrigin: [origin]))
        unusedOptions.append((origin, all.originalInput(at: origin)))
      }
    }
    
    // We have parsed all non-positional values at this point.
    // Next: parse / consume the positional values.
    do {
      try parsePositionalValues(positionalValues, unusedOptions: unusedOptions, into: &result)
    } catch {
      switch error {
      case ParserError.unexpectedExtraValues:
        // There were more positional values than we could parse.
        // If we‘re using subcommands, that could be expected.
        return .partial(result, error)
      default:
        throw error
      }
    }
    return .success(result)
  }
}

extension ArgumentSet {
  /// Fills the given `ParsedValues` instance with initial values from this
  /// argument set.
  func setInitialValues(into parsed: inout ParsedValues) throws {
    for arg in self {
      try arg.initial(InputOrigin(), &parsed)
    }
  }
}

extension ArgumentSet {
  /// Find an `ArgumentDefinition` that matches the given `ParsedArgument`.
  ///
  /// As we iterate over the values from the command line, we try to find a
  /// definition that matches the particular element.
  /// - Parameters:
  ///   - parsed: The argument from the command line
  ///   - origin: Where `parsed` came from.
  /// - Returns: The matching definition.
  func first(
    matching parsed: ParsedArgument,
    at origin: InputOrigin.Element
  ) throws -> ArgumentDefinition {
    guard let match = first(where: { $0.names.contains(parsed.name) }) else {
      throw ParserError.unknownOption(origin, parsed.name)
    }
    return match
  }
  
  func parsePositionalValues(
    _ positionalValues: [(InputOrigin.Element, String)],
    unusedOptions: [(InputOrigin.Element, String)],
    into result: inout ParsedValues
  ) throws {
    guard !positionalValues.isEmpty || !unusedOptions.isEmpty else { return }
    var positionalValues = positionalValues[...]
    var unusedOptions = unusedOptions[...]
    
    /// Pops the next origin / string pair to use.
    /// If `unconditional` is false, this always pops from `positionalValues`;
    /// if true, then it pops from whichever of `positionalValues` or
    /// `unusedOptions` has the element that came first in the original input.
    func next(unconditional: Bool) -> (InputOrigin.Element, String)? {
      guard unconditional, let firstUnusedOption = unusedOptions.first else {
        return positionalValues.popFirst()
      }
      guard let firstPositional = positionalValues.first else {
        return unusedOptions.popFirst()
      }
      return firstPositional.0 < firstUnusedOption.0
        ? positionalValues.popFirst()
        : unusedOptions.popFirst()
    }
    
    ArgumentLoop:
    for argumentDefinition in self {
      guard case .positional = argumentDefinition.kind else { continue }
      guard case let .unary(update) = argumentDefinition.update else {
        preconditionFailure("Shouldn't see a nullary positional argument.")
      }
      let allowOptionsAsInput = argumentDefinition.parsingStrategy == .allRemainingInput
      
      repeat {
        guard let (origin, value) = next(unconditional: allowOptionsAsInput) else {
          break ArgumentLoop
        }
        try update([origin], nil, value, &result)
      } while argumentDefinition.isRepeatingPositional
    }
    
    // Finished with the defined arguments; are there leftover values to parse?
    guard positionalValues.isEmpty else {
      let extraValues = positionalValues.map { (InputOrigin(element: $0.0), $0.1) }
      throw ParserError.unexpectedExtraValues(extraValues)
    }
  }
}
