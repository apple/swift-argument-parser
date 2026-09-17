//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import ArgumentParser
import ArgumentParserTestHelpers
import Testing

@Suite struct HelpNameCollisionEndToEndTests {}

// MARK: - Short name collision

private struct ShortCollision: ParsableCommand {
  static let configuration = CommandConfiguration(commandName: "repeat")

  @Option(name: .shortAndLong, help: "The name of the talking horse.")
  var horse: String

  @Argument(help: "The phrase to repeat.")
  var phrase: String
}

extension HelpNameCollisionEndToEndTests {
  /// `-h` belongs to the declared option, not to the built-in help flag.
  @Test func declaredShortNameWins() throws {
    expectParseCommand(
      ShortCollision.self, ShortCollision.self, ["-h", "Secretariat", "hello"]
    ) { command in
      #expect(command.horse == "Secretariat")
      #expect(command.phrase == "hello")
    }
  }

  /// An incomplete command line that uses the declared `-h` reports the
  /// missing argument instead of silently printing the help screen and
  /// exiting successfully.
  @Test func declaredShortNameDoesNotSwallowParseErrors() throws {
    let error = try #require(
      throws: (any Error).self,
      performing: { _ = try ShortCollision.parseAsRoot(["-h", "Secretariat"]) })
    #expect(
      ShortCollision.message(for: error)
        == "Missing expected argument '<phrase>'")
    #expect(ShortCollision.exitCode(for: error) == .validationFailure)
  }

  /// The built-in help is still reachable through `--help`, and the help
  /// screen no longer lists `-h` twice.
  @Test func declaredShortNameLeavesLongHelpName() throws {
    try requireHelp(
      .default, for: ShortCollision.self,
      equals: """
        USAGE: repeat --horse <horse> <phrase>

        ARGUMENTS:
          <phrase>                The phrase to repeat.

        OPTIONS:
          -h, --horse <horse>     The name of the talking horse.
          --help                  Show help information.

        """)
  }
}

// MARK: - Long name collision

private struct LongCollision: ParsableCommand {
  static let configuration = CommandConfiguration(commandName: "assist")

  @Flag(help: "Ask a human for help.")
  var help: Bool = false
}

extension HelpNameCollisionEndToEndTests {
  /// `--help` belongs to the declared flag, not to the built-in help flag.
  @Test func declaredLongNameWins() throws {
    expectParseCommand(
      LongCollision.self, LongCollision.self, ["--help"]
    ) { command in
      #expect(command.help == true)
    }
  }

  /// The built-in help is still reachable through `-h`.
  @Test func declaredLongNameLeavesShortHelpName() throws {
    let message = LongCollision.helpMessage(columns: 80)
    expectEqualStrings(
      actual: message,
      expected: """
        USAGE: assist [--help]

        OPTIONS:
          --help                  Ask a human for help.
          -h                      Show help information.

        """)
  }
}

// MARK: - Custom help names

private struct CustomHelpNameCollision: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "custom",
    helpNames: [.customLong("assist"), .customShort("?")])

  @Flag(name: .customLong("assist"), help: "Not the help flag.")
  var assist: Bool = false
}

extension HelpNameCollisionEndToEndTests {
  /// The collision check covers configured `helpNames`, not just the
  /// default `-h`/`--help` pair.
  @Test func declaredNameWinsOverCustomHelpName() throws {
    expectParseCommand(
      CustomHelpNameCollision.self, CustomHelpNameCollision.self, ["--assist"]
    ) { command in
      #expect(command.assist == true)
    }

    let message = CustomHelpNameCollision.helpMessage(columns: 80)
    expectEqualStrings(
      actual: message,
      expected: """
        USAGE: custom [--assist]

        OPTIONS:
          --assist                Not the help flag.
          -?                      Show help information.

        """)
  }
}
