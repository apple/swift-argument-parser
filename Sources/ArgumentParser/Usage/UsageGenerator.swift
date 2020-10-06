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
    let toolName = CommandLine.arguments[0].split(separator: "/").last.map(String.init) ?? NSLocalizedString("<command>", bundle: .module, comment: "Command placeholder")
    self.init(toolName: toolName, definition: definition)
  }
  
  init(toolName: String, parsable: ParsableArguments) {
    self.init(toolName: toolName, definition: ArgumentSet(type(of: parsable)))
  }
  
  init(toolName: String, definition: [ArgumentSet]) {
    self.init(toolName: toolName, definition: ArgumentSet(sets: definition))
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
      return NSLocalizedString(String(format: "%@ <options>", toolName), bundle: .module, comment: "Command options help")
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
      let joinedSynopsisString = partitionedNames
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
        return "\(name.synopsisString) <\(synopsisValueName ?? NSLocalizedString("value", bundle: .module, comment: "Placeholder"))>"
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
  
  var partitionedNames: [Name] {
    return names.filter{ $0.isShort } + names.filter{ !$0.isShort }
  }
  
  var preferredNameForSynopsis: Name? {
    names.first{ !$0.isShort } ?? names.first
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
  /// If no descriptive help message can be generated, `nil` will be returned.
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
    case .helpRequested, .versionRequested, .completionScriptRequested, .completionScriptCustomResponse:
      return nil

    case .unsupportedShell(let shell?):
      return unsupportedShell(shell)
    case .unsupportedShell:
      return unsupportedAutodetectedShell
      
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
    case .duplicateExclusiveValues(previous: let previous, duplicate: let duplicate, originalInput: let arguments):
      return duplicateExclusiveValues(previous: previous, duplicate: duplicate, arguments: arguments)
    case .noValue(forKey: let k):
      return noValueMessage(key: k)
    case .unableToParseValue(let o, let n, let v, forKey: let k, originalError: let e):
      return unableToParseValueMessage(origin: o, name: n, value: v, key: k, error: e)
    case .invalidOption(let str):
      return NSLocalizedString(String(format: "Invalid option: %@", str), bundle: .module, comment: "Error message")
    case .nonAlphanumericShortOption(let c):
      return NSLocalizedString(String(format: "Invalid option: -%@", c as! CVarArg), bundle: .module, comment: "Error message")
    case .missingSubcommand:
      return NSLocalizedString("Missing required subcommand.", bundle: .module, comment: "Error message")
    case .userValidationError(let error):
      switch error {
      case let error as LocalizedError:
        return error.errorDescription
      default:
        return String(describing: error)
      }
    case .noArguments(let error):
      switch error {
      case let error as ParserError:
        return ErrorMessageGenerator(arguments: self.arguments, error: error).makeErrorMessage()
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
    return NSLocalizedString("Internal error. Parsing command-line arguments hit unimplemented code path.", bundle: .module, comment: "Error message")
  }
  var invalidState: String {
    return NSLocalizedString("Internal error. Invalid state while parsing command-line arguments.", bundle: .module, comment: "Error message")
  }

  var unsupportedAutodetectedShell: String {
    NSLocalizedString(String(format: """
    Can't autodetect a supported shell.
    Please use --generate-completion-script=<shell> with one of:
        %@
    """, CompletionShell.allCases.map { $0.rawValue }.joined(separator: " ")), bundle: .module, comment: "Error message")
  }

  func unsupportedShell(_ shell: String) -> String {
    NSLocalizedString(String(format: """
    Can't generate completion scripts for '%1$@'.
    Please use --generate-completion-script=<shell> with one of:
        %2$@
    """, shell, CompletionShell.allCases.map { $0.rawValue }.joined(separator: " ")), bundle: .module, comment: "Error message")
  }

  func unknownOptionMessage(origin: InputOrigin.Element, name: Name) -> String {
    if case .short = name {
      return NSLocalizedString(String(format: "Unknown option '%@'.", name.synopsisString), bundle: .module, comment: "Error message")
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
      return NSLocalizedString(String(format: "Unknown option '%1$@'. Did you mean '%2$@'?", name.synopsisString, suggestion.synopsisString), bundle: .module, comment: "Error message")
    }
    return NSLocalizedString(String(format: "Unknown option '%@'.", name.synopsisString), bundle: .module, comment: "Error message")
  }
  
  func missingValueForOptionMessage(origin: InputOrigin, name: Name) -> String {
    if let valueName = valueName(for: name) {
      return NSLocalizedString(String(format: "Missing value for '%1$@ <%2$@>'", name.synopsisString, valueName), bundle: .module, comment: "Error message")
    } else {
      return NSLocalizedString(String(format: "Missing value for '%@'", name.synopsisString), bundle: .module, comment: "Error message")
    }
  }
  
  func unexpectedValueForOptionMessage(origin: InputOrigin.Element, name: Name, value: String) -> String? {
    return NSLocalizedString(String(format: "The option '%1$@' does not take any value, but '%2$@' was specified.", name.synopsisString, value), bundle: .module, comment: "Error message")
  }
  
  func unexpectedExtraValuesMessage(values: [(InputOrigin, String)]) -> String? {
    switch values.count {
    case 0:
      return nil
    case 1:
      return NSLocalizedString(String(format: "Unexpected argument '%@'", values.first!.1), bundle: .module, comment: "Error message")
    default:
      let v = values.map { $0.1 }.joined(separator: "', '")
      return NSLocalizedString(String(format: "%1$@ unexpected arguments: '%2$@'", values.count, v), bundle: .module, comment: "Error message")
    }
  }
  
  func duplicateExclusiveValues(previous: InputOrigin, duplicate: InputOrigin, arguments: [String]) -> String? {
    func elementString(_ origin: InputOrigin, _ arguments: [String]) -> String? {
      guard case .argumentIndex(let split) = origin.elements.first else { return nil }
      var argument = "\'\(arguments[split.inputIndex.rawValue])\'"
      if case let .sub(offsetIndex) = split.subIndex {
        let stringIndex = argument.index(argument.startIndex, offsetBy: offsetIndex+2)
        argument = "\'\(argument[stringIndex])\' in \(argument)"
      }
      return NSLocalizedString(String(format: "flag \(argument)", argument), bundle: .module, comment: "Info text")
    }

    // Note that the RHS of these coalescing operators cannot be reached at this time.
    let dupeString = elementString(duplicate, arguments) ?? NSLocalizedString(String(format: "position %@", duplicate as! CVarArg), bundle: .module, comment: "Position message")
    let origString = elementString(previous, arguments) ?? NSLocalizedString(String(format: "position %@", previous as! CVarArg), bundle: .module, comment: "Position message")

    //TODO: review this message once environment values are supported.
    return NSLocalizedString(String(format: "Value to be set with %1$@ had already been set with %2$@", dupeString, origString), bundle: .module, comment: "Error message, uses above string as argument")
  }
  
  func noValueMessage(key: InputKey) -> String? {
    let args = arguments(for: key)
    let possibilities = args.compactMap {
      $0.nonOptional.synopsis
    }
    switch possibilities.count {
    case 0:
      return NSLocalizedString("Missing expected argument", bundle: .module, comment: "Error message")
    case 1:
      return NSLocalizedString(String(format: "Missing expected argument '%@'", possibilities.first!), bundle: .module, comment: "Error message")
    default:
      let p = possibilities.joined(separator: "', '")
      return NSLocalizedString(String(format: "Missing one of: '%@'", p), bundle: .module, comment: "Error message")
    }
  }
  
  func unableToParseValueMessage(origin: InputOrigin, name: Name?, value: String, key: InputKey, error: Error?) -> String {
    let valueName = arguments(for: key).first?.valueName
    
    // We want to make the "best effort" in producing a custom error message.
    // We favour `LocalizedError.errorDescription` and fall back to
    // `CustomStringConvertible`. To opt in, return your custom error message
    // as the `description` property of `CustomStringConvertible`.
    let customErrorMessage: String = {
      switch error {
      case let err as LocalizedError where err.errorDescription != nil:
        return ": " + err.errorDescription! // !!! Checked above that this will not be nil
      case let err?:
        return ": " + String(describing: err)
      default:
        return ""
      }
    }()
    
    switch (name, valueName) {
    case let (n?, v?):
      return NSLocalizedString(String(format: "The value '%1$@' is invalid for '%2$@ <%3$@>'%4$@", value, n.synopsisString, v, customErrorMessage), bundle: .module, comment: "Error message")
    case let (_, v?):
      return NSLocalizedString(String(format: "The value '%1$@' is invalid for '<%2$@>'%3$@", value, v, customErrorMessage), bundle: .module, comment: "Error message")
    case let (n?, _):
      return NSLocalizedString(String(format: "The value '%1$@' is invalid for '%2$@'%3$@", value, n.synopsisString, customErrorMessage), bundle: .module, comment: "Error message")
    case (nil, nil):
      return NSLocalizedString(String(format: "The value '%1$@' is invalid.%2$@", value, customErrorMessage), bundle: .module, comment: "Error message")
    }
  }
}
