//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// Represents supported OpenCLI schema versions.
public enum DumpHelpVersion: String, CaseIterable, Sendable {
  // swift-format-ignore: AlwaysUseLowerCamelCase
  case v0 = "v0"

  // swift-format-ignore: AlwaysUseLowerCamelCase
  case v1 = "v1"

  public var flagName: String {
    return switch self {
    case .v0:
      "experimental-dump-help"
    default:
      "help-dump-tool-info-\(self.rawValue)"
    }
  }

  public func render(commandStack: [ParsableCommand.Type]) -> String {
    return switch self {
    case .v0:
      DumpHelpGeneratorV0(commandStack: commandStack).rendered()
    case .v1:
      DumpHelpGeneratorV1(commandStack: commandStack).rendered()
    }
  }

  public func render(_ type: any ParsableArguments.Type) -> String {
    return switch self {
    case .v0:
      DumpHelpGeneratorV0(type).rendered()
    case .v1:
      DumpHelpGeneratorV1(type).rendered()
    }
  }
}

/// Gets thrown while parsing and will be handled by the error output generation.
enum ParserError: Error {
  case helpRequested(visibility: ArgumentVisibility)
  case versionRequested
  case dumpHelpRequested(DumpHelpVersion)

  case completionScriptRequested(shell: String?)
  case completionScriptCustomResponse(String)
  case unsupportedShell(String? = nil)

  case notImplemented
  case invalidState
  case unknownOption(InputOrigin.Element, Name)
  case invalidOption(String)
  case nonAlphanumericShortOption(Character)
  /// The option was there, but its value is missing, e.g. `--name` but no value for the `name`.
  case missingValueForOption(InputOrigin, Name)
  case missingValueOrUnknownCompositeOption(InputOrigin, Name, Name)
  case unexpectedValueForOption(InputOrigin.Element, Name, String)
  case unexpectedExtraValues([(InputOrigin, String)])
  case duplicateExclusiveValues(
    previous: InputOrigin, duplicate: InputOrigin, originalInput: [String])
  /// We need a value for the given key, but it’s not there. Some non-optional option or argument is missing.
  case noValue(forKey: InputKey)
  case unableToParseValue(
    InputOrigin, Name?, String, forKey: InputKey, originalError: Error?)
  case missingSubcommand
  case userValidationError(Error)
  case noArguments(Error)
  case notParentCommand(String)
}

/// These are errors used internally to the parsing, and will not be exposed to the help generation.
enum InternalParseError: Error {
  case wrongType(valueRepresentation: String, forKey: InputKey)
  case subcommandNameMismatch
  case subcommandLevelMismatch(Int, Int)
  case subcommandLevelMissing(Int)
  case subcommandLevelDuplicated(Int)
  case expectedCommandButNoneFound
}
