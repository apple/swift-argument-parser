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
import Testing

@Suite struct SubcommandEndToEndTests {}

// MARK: Single value String

private struct Foo: ParsableCommand {
  static let configuration =
    CommandConfiguration(subcommands: [CommandA.self, CommandB.self])

  @Option() var name: String
}

private struct CommandA: ParsableCommand {
  static let configuration = CommandConfiguration(commandName: "a")

  @OptionGroup() var foo: Foo

  @Option() var bar: Int
}

private struct CommandB: ParsableCommand {
  static let configuration = CommandConfiguration(commandName: "b")

  @OptionGroup() var foo: Foo

  @Option() var baz: String
}

// swift-format-ignore: AlwaysUseLowerCamelCase
extension SubcommandEndToEndTests {
  @Test func parsing_SubCommand() throws {
    expectParseCommand(
      Foo.self, CommandA.self, ["--name", "Foo", "a", "--bar", "42"]
    ) { a in
      #expect(a.bar == 42)
      #expect(a.foo.name == "Foo")
    }

    expectParseCommand(
      Foo.self, CommandB.self, ["--name", "A", "b", "--baz", "abc"]
    ) { b in
      #expect(b.baz == "abc")
      #expect(b.foo.name == "A")
    }
  }

  @Test func parsing_SubCommand_manual() throws {
    expectParseCommand(
      Foo.self, CommandA.self, ["--name", "Foo", "a", "--bar", "42"]
    ) { a in
      #expect(a.bar == 42)
      #expect(a.foo.name == "Foo")
    }

    expectParseCommand(Foo.self, Foo.self, ["--name", "Foo"]) { foo in
      #expect(foo.name == "Foo")
    }
  }

  @Test func parsing_SubCommand_help() throws {
    let helpFoo = Foo.message(for: CleanExit.helpRequest())
    let helpA = Foo.message(for: CleanExit.helpRequest(CommandA.self))
    let helpB = Foo.message(for: CleanExit.helpRequest(CommandB.self))

    expectEqualStrings(
      actual: helpFoo,
      expected: """
        USAGE: foo --name <name> <subcommand>

        OPTIONS:
          --name <name>
          -h, --help              Show help information.

        SUBCOMMANDS:
          a
          b

          See 'foo help <subcommand>' for detailed help.
        """)
    expectEqualStrings(
      actual: helpA,
      expected: """
        USAGE: foo a --name <name> --bar <bar>

        OPTIONS:
          --name <name>
          --bar <bar>
          -h, --help              Show help information.

        """)
    expectEqualStrings(
      actual: helpB,
      expected: """
        USAGE: foo b --name <name> --baz <baz>

        OPTIONS:
          --name <name>
          --baz <baz>
          -h, --help              Show help information.

        """)
  }

  @Test func parsing_SubCommand_fails() throws {
    #expect(throws: (any Error).self) {
      try Foo.parse(["--name", "Foo", "a", "--baz", "42"])
    }
    #expect(throws: (any Error).self) {
      try Foo.parse(["--name", "Foo", "b", "--bar", "42"])
    }
  }
}

private struct Math: ParsableCommand {
  enum Operation: String, ExpressibleByArgument {
    case add
    case multiply
  }

  @Option(help: "The operation to perform")
  var operation: Operation = .add

  @Flag(name: [.short, .long])
  var verbose: Bool = false

  @Argument(help: "The first operand")
  var operands: [Int] = []

  var didRun = false

  mutating func run() {
    #expect(operation == .multiply)
    #expect(verbose)
    #expect(operands == [5, 11])
    didRun = true
  }
}

// swift-format-ignore: AlwaysUseLowerCamelCase
extension SubcommandEndToEndTests {
  @Test func parsing_SingleCommand() throws {
    var mathCommand =
      try Math.parseAsRoot(["--operation", "multiply", "-v", "5", "11"])
      as! Math
    #expect(!mathCommand.didRun)
    mathCommand.run()
    #expect(mathCommand.didRun)
  }
}

// MARK: Nested Command Arguments Validated

struct BaseCommand: ParsableCommand {
  enum BaseCommandError: Error {
    case baseCommandFailure
    case subCommandFailure
  }

  static let baseFlagValue = "base"

  static let configuration = CommandConfiguration(
    commandName: "base",
    subcommands: [SubCommand.self]
  )

  @Option()
  var baseFlag: String

  mutating func validate() throws {
    guard baseFlag == BaseCommand.baseFlagValue else {
      throw BaseCommandError.baseCommandFailure
    }
  }
}

extension BaseCommand {
  struct SubCommand: ParsableCommand {
    static let subFlagValue = "sub"

    static let configuration = CommandConfiguration(
      commandName: "sub",
      subcommands: [SubSubCommand.self]
    )

    @Option()
    var subFlag: String

    mutating func validate() throws {
      guard subFlag == SubCommand.subFlagValue else {
        throw BaseCommandError.subCommandFailure
      }
    }
  }
}

extension BaseCommand.SubCommand {
  struct SubSubCommand: ParsableCommand, TestableSwiftTestingParsableArguments {
    let didValidateExpectation = TestExpectation()

    static let configuration = CommandConfiguration(
      commandName: "subsub"
    )

    @Flag
    var subSubFlag: Bool = false

    private enum CodingKeys: CodingKey {
      case subSubFlag
    }
  }
}

// swift-format-ignore: AlwaysUseLowerCamelCase
// https://github.com/apple/swift-argument-parser/issues/710
extension SubcommandEndToEndTests {
  @Test func validate_subcommands() throws {
    // provide a value to base-flag that will throw
    expectErrorMessage(
      BaseCommand.self,
      ["--base-flag", "foo", "sub", "--sub-flag", "foo", "subsub"],
      "baseCommandFailure"
    )

    // provide a value to sub-flag that will throw
    expectErrorMessage(
      BaseCommand.self,
      [
        "--base-flag", BaseCommand.baseFlagValue, "sub", "--sub-flag", "foo",
        "subsub",
      ],
      "subCommandFailure"
    )

    // provide a valid command and make sure both validates succeed
    expectParseCommand(
      BaseCommand.self,
      BaseCommand.SubCommand.SubSubCommand.self,
      [
        "--base-flag", BaseCommand.baseFlagValue, "sub", "--sub-flag",
        BaseCommand.SubCommand.subFlagValue, "subsub", "--sub-sub-flag",
      ]
    ) { cmd in
      #expect(cmd.subSubFlag)

      // make sure that the instance of SubSubCommand provided
      // had its validate method called, not just that any instance of SubSubCommand was validated
      #expect(cmd.didValidateExpectation.fulfilled)
    }
  }
}

// MARK: Version flags

private struct A: ParsableCommand {
  static let configuration = CommandConfiguration(
    version: "1.0.0",
    subcommands: [HasVersionFlag.self, NoVersionFlag.self])

  struct HasVersionFlag: ParsableCommand {
    @Flag var version: Bool = false
  }

  struct NoVersionFlag: ParsableCommand {
    @Flag var hello: Bool = false
  }
}

extension SubcommandEndToEndTests {
  @Test func parsingVersionFlags() throws {
    expectErrorMessage(A.self, ["--version"], "1.0.0")
    expectErrorMessage(A.self, ["no-version-flag", "--version"], "1.0.0")

    expectParseCommand(
      A.self, A.HasVersionFlag.self, ["has-version-flag", "--version"]
    ) { cmd in
      #expect(cmd.version)
    }
  }
}
