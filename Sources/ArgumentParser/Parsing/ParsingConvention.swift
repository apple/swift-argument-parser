//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020-2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// A type representing different conventions for parsing command lines.
public enum ParsingConvention {
  /// POSIX-style command-line parsing.
  ///
  /// This parsing convention matches the one typically used on POSIX-compliant
  /// systems and Apple platforms. For example:
  ///
  /// ```
  /// command --argument-name 123
  /// ```
  case posix

  /// DOS-style command-line parsing.
  ///
  /// This parsing convention matches the one historically used by DOS and
  /// Windows. For example:
  ///
  /// ```
  /// command /ArgumentName 123
  /// ```
  case dos

  /// The default parsing convention used by Swift Argument Parser.
  ///
  /// Clients of Swift Argument Parser that wish to set the parsing convention
  /// it uses should set `.current` before calling `main()` or other Swift
  /// Argument Parser interfaces.
  ///
  /// - Bug: For compatibility with existing Swift Argument Parser clients,
  ///   the POSIX convention is the default value for this property even on
  ///   platforms such as Windows where a different convention might be in use.
  ///   Callers that wish to use a different parsing convention should set the
  ///   value of this property in their root command's configuration.
  public static var `default`: Self { return .posix }

  /// The parsing convention to use when parsing command-line input.
  ///
  /// The value of this property is consulted when Swift Argument Parser parses
  /// a command line to determine how to convert argument names between their
  /// Swift representations and their command-line representations.
  ///
  /// - Bug: This value is effectively a global and cannot realistically be made
  ///   thread-safe since we do not know how client code will be implemented.
  ///   This is unlikely to be an issue in practice: it seems unlikely that
  ///   many (if any) clients need to run multiple commands concurrently _and_
  ///   apply different parsing conventions to them.
  public static var current: Self = .default
}

// MARK: - Internal-only conveniences and extensions

extension ParsingConvention {
  /// The naming convention for arguments passed while using this parsing
  /// convention.
  ///
  /// - Note: Callers interested in constructing an argument name should
  ///   generally use `convertStringToArgumentNamingConvention(_:from:)` instead
  ///   of this property.
  var argumentNamingConvention: String.NamingConvention {
    switch self {
    case .posix:
      return .snakeCase(separator: "-")
    case .dos:
      return .camelCase(lowercaseFirstWord: false)
    }
  }

  /// Convert a string from an arbitrary naming convention to the one used by
  /// this parsing convention for argument names.
  ///
  /// - Parameters:
  ///   - string: The string to convert.
  ///   - oldConvention: The naming convention currently used by `string`. By
  ///     default, Swift variable case is assumed.
  ///
  /// - Returns: A string derived from `string` suitable for use as an argument
  ///   name. The string does not include a leading prefix such as `"--"`.
  func convertStringToArgumentNamingConvention(_ string: String, from oldConvention: String.NamingConvention = .swiftVariableCase) -> String {
    var result = string.converted(from: oldConvention, to: argumentNamingConvention)
    if self == .posix {
      result = result.lowercased()
    }
    return result
  }

  /// The prefixes to use before argument names.
  var argumentPrefixes: (long: String, short: String) {
    switch self {
    case .posix:
      return ("--", "-")
    case .dos:
      return ("/", "+")
    }
  }

  /// The raw value of an argument that a user would enter to terminate a list
  /// of arguments.
  var terminatorArgument: String {
    switch self {
    case .posix:
      return "--"
    case .dos:
      return "--" // FIXME: does Windows use something else by convention?
    }
  }

  /// The set of characters that separate an argument from its value.
  ///
  /// This collection does not include whitespace characters.
  var argumentValueSeparators: [Character] {
    switch self {
    case .posix:
      return [ "=" ]
    case .dos:
      return [ "=", ":" ]
    }
  }
}
