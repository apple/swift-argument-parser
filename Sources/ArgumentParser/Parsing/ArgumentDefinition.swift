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

struct ArgumentDefinition {
  /// A closure that modifies a `ParsedValues` instance to include this
  /// argument's value.
  enum Update {
    typealias Nullary = (InputOrigin, Name?, inout ParsedValues) throws -> Void
    typealias Unary = (InputOrigin, Name?, String, inout ParsedValues) throws -> Void
    
    /// An argument that gets its value solely from its presence.
    case nullary(Nullary)
    
    /// An argument that takes a string as its value.
    case unary(Unary)
  }
  
  typealias Initial = (InputOrigin, inout ParsedValues) throws -> Void
  
  enum Kind {
    /// An option or flag, with a name and an optional value.
    case named([Name])
    
    /// A positional argument.
    case positional
    
    /// A pseudo-argument that takes its value from a property's default value
    /// instead of from command-line arguments.
    case `default`
  }
  
  struct Help {
    var options: Options

    // `ArgumentHelp` members
    var abstract: String = ""
    var discussion: String = ""
    var valueName: String = ""
    var shouldDisplay: Bool = true

    var defaultValue: String?
    var keys: [InputKey]
    var allValues: [String] = []
    var isComposite: Bool = false
    
    struct Options: OptionSet {
      var rawValue: UInt
      
      static let isOptional = Options(rawValue: 1 << 0)
      static let isRepeating = Options(rawValue: 1 << 1)
    }
    
    init(options: Options = [], help: ArgumentHelp? = nil, defaultValue: String? = nil, key: InputKey, isComposite: Bool = false) {
      self.options = options
      self.defaultValue = defaultValue
      self.keys = [key]
      self.isComposite = isComposite
      updateArgumentHelp(help: help)
    }
    
    init<T: ExpressibleByArgument>(type: T.Type, options: Options = [], help: ArgumentHelp? = nil, defaultValue: String? = nil, key: InputKey) {
      self.options = options

      self.defaultValue = defaultValue
      self.keys = [key]
      self.allValues = type.allValueStrings
      updateArgumentHelp(help: help)
    }

    mutating func updateArgumentHelp(help: ArgumentHelp?) {
      self.abstract = help?.abstract ?? ""
      self.discussion = help?.discussion ?? ""
      self.valueName = help?.valueName ?? ""
      self.shouldDisplay = help?.shouldDisplay ?? true
    }
  }
  
  /// This folds the public `ArrayParsingStrategy` and `SingleValueParsingStrategy`
  /// into a single enum.
  enum ParsingStrategy {
    /// Expect the next `SplitArguments.Element` to be a value and parse it. Will fail if the next
    /// input is an option.
    case `default`
    /// Parse the next `SplitArguments.Element.value`
    case scanningForValue
    /// Parse the next `SplitArguments.Element` as a value, regardless of its type.
    case unconditional
    /// Parse multiple `SplitArguments.Element.value` up to the next non-`.value`
    case upToNextOption
    /// Parse all remaining `SplitArguments.Element` as values, regardless of its type.
    case allRemainingInput
  }
  
  var kind: Kind
  var help: Help
  var completion: CompletionKind
  var parsingStrategy: ParsingStrategy
  var update: Update
  var initial: Initial
  
  var names: [Name] {
    switch kind {
    case .named(let n): return n
    case .positional, .default: return []
    }
  }
  
  var valueName: String {
    help.valueName.mapEmpty {
      names.preferredName?.valueString
        ?? help.keys.first?.rawValue.convertedToSnakeCase(separator: "-")
        ?? "value"
    }
  }

  init(
    kind: Kind,
    help: Help,
    completion: CompletionKind,
    parsingStrategy: ParsingStrategy = .default,
    update: Update,
    initial: @escaping Initial = { _, _ in }
  ) {
    if case (.positional, .nullary) = (kind, update) {
      preconditionFailure("Can't create a nullary positional argument.")
    }
    
    self.kind = kind
    self.help = help
    self.completion = completion
    self.parsingStrategy = parsingStrategy
    self.update = update
    self.initial = initial
  }
}

extension ArgumentDefinition: CustomDebugStringConvertible {
  var debugDescription: String {
    switch (kind, update) {
    case (.named(let names), .nullary):
      return names
        .map { $0.synopsisString }
        .joined(separator: ",")
    case (.named(let names), .unary):
      return names
        .map { $0.synopsisString }
        .joined(separator: ",")
        + " <\(valueName)>"
    case (.positional, _):
      return "<\(valueName)>"
    case (.default, _):
      return ""
    }
  }
}

extension ArgumentDefinition {
  var optional: ArgumentDefinition {
    var result = self
    result.help.options.insert(.isOptional)
    return result
  }
  
  var nonOptional: ArgumentDefinition {
    var result = self
    result.help.options.remove(.isOptional)
    return result
  }
}

extension ArgumentDefinition {
  var isPositional: Bool {
    if case .positional = kind {
      return true
    }
    return false
  }
  
  var isRepeatingPositional: Bool {
    isPositional && help.options.contains(.isRepeating)
  }

  var isNullary: Bool {
    if case .nullary = update {
      return true
    } else {
      return false
    }
  }
  
  var allowsJoinedValue: Bool {
    names.contains(where: { $0.allowsJoined })
  }
}

extension ArgumentDefinition.Kind {
  static func name(key: InputKey, specification: NameSpecification) -> ArgumentDefinition.Kind {
    let names = specification.makeNames(key)
    return ArgumentDefinition.Kind.named(names)
  }
}

extension ArgumentDefinition.Update {
  static func appendToArray<A: ExpressibleByArgument>(forType type: A.Type, key: InputKey) -> ArgumentDefinition.Update {
    return ArgumentDefinition.Update.unary {
      (origin, name, value, values) in
      guard let v = A(argument: value) else {
        throw ParserError.unableToParseValue(origin, name, value, forKey: key)
      }
      values.update(forKey: key, inputOrigin: origin, initial: [A](), closure: {
        $0.append(v)
      })
    }
  }
}

// MARK: - Help Options

protocol ArgumentHelpOptionProvider {
  static var helpOptions: ArgumentDefinition.Help.Options { get }
}

extension Optional: ArgumentHelpOptionProvider {
  static var helpOptions: ArgumentDefinition.Help.Options {
    return [.isOptional]
  }
}

extension ArgumentDefinition.Help.Options {
  init<A>(type: A.Type) {
    if let t = type as? ArgumentHelpOptionProvider.Type {
      self = t.helpOptions
    } else {
      self = []
    }
  }
}
