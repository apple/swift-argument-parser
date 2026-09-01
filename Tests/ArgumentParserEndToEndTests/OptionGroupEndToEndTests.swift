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

@Suite struct OptionGroupEndToEndTests {}

private enum ValidationConfirmations {
  @TaskLocal static var inner: Confirmation?
  @TaskLocal static var outer: Confirmation?
  @TaskLocal static var command: Confirmation?
}

private struct Inner: ParsableArguments {
  @Flag(name: [.short, .long])
  var extraVerbiage: Bool = false
  @Option
  var size: Int = 0
  @Argument()
  var name: String

  mutating func validate() throws {
    ValidationConfirmations.inner?()
  }
}

private struct Outer: ParsableArguments {
  @Flag
  var verbose: Bool = false
  @Argument()
  var before: String
  @OptionGroup()
  var inner: Inner
  @Argument()
  var after: String

  mutating func validate() throws {
    ValidationConfirmations.outer?()
  }
}

private struct Command: ParsableCommand {
  static let configuration = CommandConfiguration(commandName: "testCommand")

  @OptionGroup()
  var outer: Outer

  mutating func validate() throws {
    ValidationConfirmations.command?()
  }
}

// swift-format-ignore: AlwaysUseLowerCamelCase
// https://github.com/apple/swift-argument-parser/issues/710
extension OptionGroupEndToEndTests {
  @Test func optionGroup_Defaults() throws {
    expectParse(Outer.self, ["prefix", "name", "postfix"]) { options in
      #expect(options.verbose == false)
      #expect(options.before == "prefix")
      #expect(options.after == "postfix")

      #expect(options.inner.extraVerbiage == false)
      #expect(options.inner.size == 0)
      #expect(options.inner.name == "name")
    }

    expectParse(
      Outer.self,
      [
        "prefix", "--extra-verbiage", "name", "postfix", "--verbose", "--size",
        "5",
      ]
    ) { options in
      #expect(options.verbose == true)
      #expect(options.before == "prefix")
      #expect(options.after == "postfix")

      #expect(options.inner.extraVerbiage == true)
      #expect(options.inner.size == 5)
      #expect(options.inner.name == "name")
    }
  }

  @Test func optionGroup_isValidated() async throws {
    // Parse the command, this should cause validation to be called once each
    // on:
    // - command.outer.inner
    // - command.outer
    // - command
    await confirmation("Command validated") { commandValidated in
      await confirmation("Outer validated") { outerValidated in
        await confirmation("Inner validated") { innerValidated in
          ValidationConfirmations.$command.withValue(commandValidated) {
            ValidationConfirmations.$outer.withValue(outerValidated) {
              ValidationConfirmations.$inner.withValue(innerValidated) {
                expectParseCommand(
                  Command.self, Command.self, ["prefix", "name", "postfix"]
                ) { _ in }
              }
            }
          }
        }
      }
    }
  }

  @Test func optionGroup_Fails() throws {
    #expect(throws: (any Error).self) { try Outer.parse([]) }
    #expect(throws: (any Error).self) { try Outer.parse(["prefix"]) }
    #expect(throws: (any Error).self) { try Outer.parse(["prefix", "name"]) }
    #expect(throws: (any Error).self) {
      try Outer.parse(["prefix", "name", "postfix", "extra"])
    }
    #expect(throws: (any Error).self) {
      try Outer.parse(["prefix", "name", "postfix", "--size", "a"])
    }
  }
}

private struct DuplicatedFlagGroupCustom: ParsableArguments {
  @Flag(name: .customLong("duplicated-option"))
  var duplicated: Bool = false
}

private struct DuplicatedFlagGroupCustomCommand: ParsableCommand {
  @Flag var duplicated: Bool = false
  @OptionGroup var option: DuplicatedFlagGroupCustom
}

private struct DuplicatedFlagGroupLong: ParsableArguments {
  @Flag var duplicated: Bool = false
}

private struct DuplicatedFlagGroupLongCommand: ParsableCommand {
  @Flag(name: .customLong("duplicated-option"))
  var duplicated: Bool = false
  @OptionGroup var option: DuplicatedFlagGroupLong
}

// swift-format-ignore: AlwaysUseLowerCamelCase
// https://github.com/apple/swift-argument-parser/issues/710
extension OptionGroupEndToEndTests {
  @Test func uniqueNamesForDuplicatedFlag_NoFlags() throws {
    expectParse(DuplicatedFlagGroupCustomCommand.self, []) { command in
      #expect(!command.duplicated)
      #expect(!command.option.duplicated)
    }
    expectParse(DuplicatedFlagGroupLongCommand.self, []) { command in
      #expect(!command.duplicated)
      #expect(!command.option.duplicated)
    }
  }

  @Test func uniqueNamesForDuplicatedFlag_RootOnly() throws {
    expectParse(DuplicatedFlagGroupCustomCommand.self, ["--duplicated"]) {
      command in
      #expect(command.duplicated)
      #expect(!command.option.duplicated)
    }
    expectParse(DuplicatedFlagGroupLongCommand.self, ["--duplicated"]) {
      command in
      #expect(!command.duplicated)
      #expect(command.option.duplicated)
    }
  }

  @Test func uniqueNamesForDuplicatedFlag_OptionOnly() throws {
    expectParse(DuplicatedFlagGroupCustomCommand.self, ["--duplicated-option"])
    { command in
      #expect(!command.duplicated)
      #expect(command.option.duplicated)
    }
    expectParse(DuplicatedFlagGroupLongCommand.self, ["--duplicated-option"]) {
      command in
      #expect(command.duplicated)
      #expect(!command.option.duplicated)
    }
  }

  @Test func uniqueNamesForDuplicatedFlag_RootAndOption() throws {
    expectParse(
      DuplicatedFlagGroupCustomCommand.self,
      ["--duplicated", "--duplicated-option"]
    ) { command in
      #expect(command.duplicated)
      #expect(command.option.duplicated)
    }
    expectParse(
      DuplicatedFlagGroupLongCommand.self,
      ["--duplicated", "--duplicated-option"]
    ) { command in
      #expect(command.duplicated)
      #expect(command.option.duplicated)
    }
  }
}
