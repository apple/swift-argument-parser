//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020-2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import ArgumentParser
import ArgumentParserTestHelpers
import Foundation
import Testing

@Suite struct ValidationEndToEndTests {}

private enum UserValidationError: LocalizedError {
  case userValidationError

  var errorDescription: String? {
    switch self {
    case .userValidationError:
      return "UserValidationError"
    }
  }
}

private struct Foo: ParsableArguments {
  static let usageString: String = """
    Usage: foo [--count <count>] [<names> ...] [--version] [--throw]
      See 'foo --help' for more information.
    """

  static let helpString: String = """
    USAGE: foo [--count <count>] [<names> ...] [--version] [--throw]

    ARGUMENTS:
      <names>

    OPTIONS:
      --count <count>
      --version
      --throw
      -h, --help              Show help information.
    """

  @Option()
  var count: Int?

  @Argument()
  var names: [String] = []

  @Flag
  var version: Bool = false

  @Flag(name: [.customLong("throw")])
  var throwCustomError: Bool = false

  @Flag(help: .hidden)
  var showUsageOnly: Bool = false

  @Flag(help: .hidden)
  var failValidationSilently: Bool = false

  @Flag(help: .hidden)
  var failSilently: Bool = false

  mutating func validate() throws {
    if version {
      throw CleanExit.message("0.0.1")
    }

    if names.isEmpty {
      throw ValidationError("Must specify at least one name.")
    }

    if let count = count, names.count != count {
      throw ValidationError(
        "Number of names (\(names.count)) doesn't match count (\(count)).")
    }

    if throwCustomError {
      throw UserValidationError.userValidationError
    }

    if showUsageOnly {
      throw ValidationError("")
    }

    if failValidationSilently {
      throw ExitCode.validationFailure
    }

    if failSilently {
      throw ExitCode.failure
    }
  }
}

// swift-format-ignore: AlwaysUseLowerCamelCase
// https://github.com/apple/swift-argument-parser/issues/710
extension ValidationEndToEndTests {
  @Test func validation() throws {
    expectParse(Foo.self, ["Joe"]) { foo in
      #expect(foo.names == ["Joe"])
      #expect(foo.count == nil)
    }

    expectParse(Foo.self, ["Joe", "Moe", "--count", "2"]) { foo in
      #expect(foo.names == ["Joe", "Moe"])
      #expect(foo.count == 2)
    }
  }

  @Test func validation_Version() throws {
    expectErrorMessage(Foo.self, ["--version"], "0.0.1")
    expectFullErrorMessage(Foo.self, ["--version"], "0.0.1")
  }

  @Test func validation_Fails() throws {
    expectErrorMessage(Foo.self, [], "Must specify at least one name.")
    expectFullErrorMessage(
      Foo.self, [],
      """
      Error: Must specify at least one name.

      \(Foo.helpString)

      """)

    expectErrorMessage(
      Foo.self, ["--count", "3", "Joe"],
      """
      Number of names (1) doesn't match count (3).
      """)
    expectFullErrorMessage(
      Foo.self, ["--count", "3", "Joe"],
      """
      Error: Number of names (1) doesn't match count (3).
      \(Foo.usageString)
      """)
  }

  @Test func customErrorValidation() {
    // verify that error description is printed if available via LocalizedError
    expectErrorMessage(
      Foo.self, ["--throw", "Joe"],
      UserValidationError.userValidationError.errorDescription!)
  }

  @Test func emptyErrorValidation() {
    expectErrorMessage(Foo.self, ["--show-usage-only", "Joe"], "")
    expectFullErrorMessage(
      Foo.self, ["--show-usage-only", "Joe"], Foo.usageString)
    expectFullErrorMessage(Foo.self, ["--fail-validation-silently", "Joe"], "")
    expectFullErrorMessage(Foo.self, ["--fail-silently", "Joe"], "")
  }
}

private struct FooCommand: ParsableCommand {
  @Flag(help: .hidden)
  var foo = false
  @Flag(help: .hidden)
  var bar = false

  mutating func validate() throws {
    if foo {
      // --foo implies --bar
      bar = true
    }
  }

  func run() throws {
    #expect(foo == bar)
  }
}

extension ValidationEndToEndTests {
  @Test func mutationsPreserved() throws {
    var foo = try FooCommand.parseAsRoot(["--foo"])
    try foo.run()
  }
}
