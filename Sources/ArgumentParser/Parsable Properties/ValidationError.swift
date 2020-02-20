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

/// An error type that is presented to the user as an error with parsing their
/// command-line input.
public struct ValidationError: Error, CustomStringConvertible {
  var message: String
  
  /// Creates a new validation error with the given message.
  public init(_ message: String) {
    self.message = message
  }
  
  public var description: String {
    message
  }
}

/// An error type that represents a clean (i.e. non-error state) exit of the
/// utility.
///
/// Throwing a `CleanExit` instance from a `validate` or `run` method, or
/// passing it to `exit(with:)`, exits a program with exit code `0`.
public enum CleanExit: Error, CustomStringConvertible {
  /// Treat this error as a help request and display the full help message.
  ///
  /// You can use this case to simulate the user specifying one of the help
  /// flags or subcommands.
  ///
  /// - Parameter command: The command type to offer help for, if different
  ///   from the root command.
  case helpRequest(ParsableCommand.Type? = nil)
  
  /// Treat this error as a clean exit with the given message.
  case message(String)
  
  public var description: String {
    switch self {
    case .helpRequest: return "--help"
    case .message(let message): return message
    }
  }
  
  /// Treat this error as a help request and display the full help message.
  ///
  /// You can use this case to simulate the user specifying one of the help
  /// flags or subcommands.
  ///
  /// - Parameter command: A command to offer help for, if different from
  ///   the root command.
  public static func helpRequest(_ command: ParsableCommand) -> CleanExit {
    return .helpRequest(type(of: command))
  }
}
