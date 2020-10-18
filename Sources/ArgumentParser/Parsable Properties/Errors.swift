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

#if canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#elseif canImport(CRT)
import CRT
#endif

#if os(Windows)
import let WinSDK.ERROR_BAD_ARGUMENTS
#endif

/// An error type that is presented to the user as an error with parsing their
/// command-line input.
public struct ValidationError: Error, CustomStringConvertible {
  /// The error message represented by this instance, this string is presented to
  /// the user when a `ValidationError` is thrown from either; `run()`,
  /// `validate()` or a transform closure.
  public internal(set) var message: String
  
  /// Creates a new validation error with the given message.
  public init(_ message: String) {
    self.message = message
  }
  
  public var description: String {
    message
  }
}

/// An error type that only includes an exit code.
///
/// If you're printing custom errors messages yourself, you can throw this error
/// to specify the exit code without adding any additional output to standard
/// out or standard error.
public struct ExitCode: Error, RawRepresentable, Hashable {
  /// The exit code represented by this instance.
  public var rawValue: Int32

  /// Creates a new `ExitCode` with the given code.
  public init(_ code: Int32) {
    self.rawValue = code
  }
  
  public init(rawValue: Int32) {
    self.init(rawValue)
  }
  
  /// An exit code that indicates successful completion of a command.
  public static let success = ExitCode(EXIT_SUCCESS)
  
  /// An exit code that indicates that the command failed.
  public static let failure = ExitCode(EXIT_FAILURE)
  
  /// An exit code that indicates that the user provided invalid input.
#if os(Windows)
  public static let validationFailure = ExitCode(ERROR_BAD_ARGUMENTS)
#else
  public static let validationFailure = ExitCode(EX_USAGE)
#endif

  /// A Boolean value indicating whether this exit code represents the
  /// successful completion of a command.
  public var isSuccess: Bool {
    self == Self.success
  }
}

/// An error type that represents a clean (i.e. non-error state) exit of the
/// utility.
///
/// Throwing a `CleanExit` instance from a `validate` or `run` method, or
/// passing it to `exit(with:)`, exits the program with exit code `0`.
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
