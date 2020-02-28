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

@_implementationOnly import Foundation

struct UsageGenerator {
  var toolName: String
  var definition: ArgumentSet
}

extension UsageGenerator {
  init(definition: ArgumentSet) {
    let toolName = CommandLine.arguments[0].split(separator: "/").last.map(String.init) ?? "<command>"
    self.init(toolName: toolName, definition: definition)
  }
  
  init(toolName: String, parsable: ParsableArguments) {
    self.init(toolName: toolName, definition: ArgumentSet(type(of: parsable)))
  }
  
  init(toolName: String, definition: [ArgumentSet]) {
    self.init(toolName: toolName, definition: ArgumentSet(additive: definition))
  }
}

extension UsageGenerator {
  /// The tool synopsis.
  ///
  /// In `roff`.
  var synopsis: String {
    let definitionSynopsis = definition.synopsis
    switch definitionSynopsis.count {
    case 0:
      return toolName
    case let x where x > 12:
      return "\(toolName) <options>"
    default:
      return "\(toolName) \(definition.synopsis.joined(separator: " "))"
    }
  }
}

extension ArgumentSet {
  var synopsis: [String] {
    return self
      .compactMap { $0.synopsis }
  }
}

extension ArgumentDefinition {
  var synopsisForHelp: String? {
    guard help.help?.shouldDisplay != false else {
      return nil
    }
    
    switch kind {
    case .named:
      let joinedSynopsisString = sortedNames
        .map { $0.synopsisString }
        .joined(separator: ", ")
      
      switch update {
      case .unary:
        return "\(joinedSynopsisString) <\(synopsisValueName ?? "")>"
      case .nullary:
        return joinedSynopsisString
      }
    case .positional:
      return "<\(valueName)>"
    }
  }
  
  var unadornedSynopsis: String? {
    switch kind {
    case .named:
      guard let name = preferredNameForSynopsis else { return nil }
      
      switch update {
      case .unary:
        return "\(name.synopsisString) <\(synopsisValueName ?? "value")>"
      case .nullary:
        return name.synopsisString
      }
    case .positional:
      return "<\(valueName)>"
    }
  }
  
  var synopsis: String? {
    guard help.help?.shouldDisplay != false else {
      return nil
    }
    
    guard !help.options.contains(.isOptional) else {
      var n = self
      n.help.options.remove(.isOptional)
      return n.synopsis.flatMap { "[\($0)]" }
    }
    guard !help.options.contains(.isRepeating) else {
      var n = self
      n.help.options.remove(.isRepeating)
      return n.synopsis.flatMap { "\($0) ..." }
    }
    
    return unadornedSynopsis
  }
  
  var sortedNames: [Name] {
    return names
      .sorted { (lhs, rhs) -> Bool in
        switch (lhs, rhs) {
        case let (.long(l), .long(r)):
          return l < r
        case (_, .long):
          return true
        case (.long, _):
          return false
        case let (.short(l), .short(r)):
          return l < r
        case (_, .short):
          return true
        case (.short, _):
          return false
        case let (.longWithSingleDash(l), .longWithSingleDash(r)):
          return l < r
        }
    }
  }
  
  var preferredNameForSynopsis: Name? {
    sortedNames.last
  }
  
  var synopsisValueName: String? {
    valueName
  }
}

extension ArgumentSet {
  func helpMessage(for error: Swift.Error) -> String {
    return errorDescription(error: error) ?? ""
  }
  
  /// Will generate a descriptive help message if possible.
  ///
  /// If no descriptive help message can be generated `nil` will be returned.
  ///
  /// - Parameter error: the parse error that occurred.
  func errorDescription(error: Swift.Error) -> String? {
    switch error {
    case let parserError as ParserError:
      return ErrorMessageGenerator(arguments: self, error: parserError)
        .makeErrorMessage()
    case let commandError as CommandError:
      return ErrorMessageGenerator(arguments: self, error: commandError.parserError)
        .makeErrorMessage()
    default:
      return nil
    }
  }
}

struct ErrorMessageGenerator {
  var arguments: ArgumentSet
  var error: ParserError
}

extension ErrorMessageGenerator {
  func makeErrorMessage() -> String? {
    switch error {
    case .notImplemented:
      return notImplementedMessage
    case .invalidState:
      return invalidState
    case .unknownOption(let o, let n):
      return unknownOptionMessage(origin: o, name: n)
    case .missingValueForOption(let o, let n):
      return missingValueForOptionMessage(origin: o, name: n)
    case .unexpectedValueForOption(let o, let n, let v):
      return unexpectedValueForOptionMessage(origin: o, name: n, value: v)
    case .unexpectedExtraValues(let v):
      return unexpectedExtraValuesMessage(values: v)
    case .duplicateExclusiveValues(previous: let previous, duplicate: let duplicate):
      return duplicateExclusiveValues(previous: previous, duplicate: duplicate)
    case .noValue(forKey: let k):
      return noValueMessage(key: k)
    case .unableToParseValue(let o, let n, let v, forKey: let k):
      return unableToParseValueMessage(origin: o, name: n, value: v, key: k)
    case .helpRequested:
      return nil
    case .invalidOption(let str):
      return "Invalid option: \(str)"
    case .nonAlphanumericShortOption(let c):
      return "Invalid option: -\(c)"
    case .missingSubcommand:
      return "Missing required subcommand."
    case .userValidationError(let error):
      switch error {
      case let error as LocalizedError:
        return error.errorDescription
      default:
        return String(describing: error)
      }
    }
  }
}

extension ErrorMessageGenerator {
  func arguments(for key: InputKey) -> [ArgumentDefinition] {
    return arguments
      .filter {
        $0.help.keys.contains(key)
    }
  }
  
  func help(for key: InputKey) -> ArgumentDefinition.Help? {
    return arguments
      .first { $0.help.keys.contains(key) }
      .map { $0.help }
  }
  
  func valueName(for name: Name) -> String? {
    for arg in arguments {
      guard
        arg.names.contains(name),
        let v = arg.synopsisValueName
        else { continue }
      return v
    }
    return nil
  }
}

extension ErrorMessageGenerator {
  var notImplementedMessage: String {
    return "Internal error. Parsing command line arguments hit unimplemented code path."
  }
  var invalidState: String {
    return "Internal error. Invalid state while parsing command line arguments."
  }


  func unknownOptionMessage(origin: InputOrigin.Element, name: Name) -> String {
    if case .short = name {
      return "Unknown option '\(name.synopsisString)'"
    }
    
    // An empirically derived magic number
    let SIMILARITY_FLOOR = 4

    let notShort: (Name) -> Bool = { (name: Name) in
      switch name {
      case .short: return false
      case .long: return true
      case .longWithSingleDash: return true
      }
    }
    let suggestion = arguments
      .flatMap({ $0.names })
      .filter({ $0.synopsisString.editDistance(to: name.synopsisString) < SIMILARITY_FLOOR }) // only include close enough suggestion
      .filter(notShort) // exclude short option suggestions
      .min(by: { lhs, rhs in // find the suggestion closest to the argument
        lhs.synopsisString.editDistance(to: name.synopsisString) < rhs.synopsisString.editDistance(to: name.synopsisString)
      })
    
    if let suggestion = suggestion {
        return "Unknown option '\(name.synopsisString)'. Did you mean '\(suggestion.synopsisString)'?"
    }
    return "Unknown option '\(name.synopsisString)'"
  }
  
  func missingValueForOptionMessage(origin: InputOrigin, name: Name) -> String {
    if let valueName = valueName(for: name) {
      return "Missing value for '\(name.synopsisString) <\(valueName)>'"
    } else {
      return "Missing value for '\(name.synopsisString)'"
    }
  }
  
  func unexpectedValueForOptionMessage(origin: InputOrigin.Element, name: Name, value: String) -> String? {
    return "The option '\(name.synopsisString)' does not take any value, but '\(value)' was specified."
  }
  
  func unexpectedExtraValuesMessage(values: [(InputOrigin, String)]) -> String? {
    switch values.count {
    case 0:
      return nil
    case 1:
      return "Unexpected argument '\(values.first!.1)'"
    default:
      let v = values.map { $0.1 }.joined(separator: "', '")
      return "\(values.count) unexpected arguments: '\(v)'"
    }
  }
  
  func duplicateExclusiveValues(previous: InputOrigin, duplicate: InputOrigin) -> String? {
    return "Value at position \(duplicate) has already been set from value at position \(previous)."
  }
  
  func noValueMessage(key: InputKey) -> String? {
    let args = arguments(for: key)
    let possibilities = args.compactMap {
      $0.nonOptional.synopsis
    }
    switch possibilities.count {
    case 0:
      return "Missing expected argument"
    case 1:
      return "Missing expected argument '\(possibilities.first!)'"
    default:
      let p = possibilities.joined(separator: "', '")
      return "Missing one of: '\(p)'"
    }
  }
  
  func unableToParseValueMessage(origin: InputOrigin, name: Name?, value: String, key: InputKey) -> String {
    let valueName = arguments(for: key).first?.valueName
    switch (name, valueName) {
    case let (n?, v?):
      return "The value '\(value)' is invalid for '\(n.synopsisString) <\(v)>'"
    case let (_, v?):
      return "The value '\(value)' is invalid for '<\(v)>'"
    case let (n?, _):
      return "The value '\(value)' is invalid for '\(n.synopsisString)'"
    case (nil, nil):
      return "The value '\(value)' is invalid."
    }
  }
}
