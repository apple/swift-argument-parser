//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import ArgumentParserTestHelpers
import XCTest

@testable import ArgumentParser

extension HelpGenerationTests {

  struct BasicDefaultAsFlag: ParsableArguments {
    @Option(
      defaultAsFlag: "default", help: "A string option with defaultAsFlag.")
    var stringFlag: String?

    @Option(defaultAsFlag: 42, help: "An integer option with defaultAsFlag.")
    var numberFlag: Int?

    @Option(defaultAsFlag: true, help: "A boolean option with defaultAsFlag.")
    var boolFlag: Bool?

    @Option(
      defaultAsFlag: "transformed",
      help: "A string option with defaultAsFlag and transform.")
    var transformFlag: String?

    @Option(name: .shortAndLong, help: "A regular option for comparison.")
    var regular: String?
  }

  func testDefaultAsFlagHelpOutput() {
    AssertHelp(
      .default, for: BasicDefaultAsFlag.self,
      equals: """
        USAGE: basic_default_as_flag [--string-flag [<string-flag>]] [--number-flag [<number-flag>]] [--bool-flag [<bool-flag>]] [--transform-flag [<transform-flag>]] [--regular <regular>]

        OPTIONS:
          --string-flag [<string-flag>]
                                  A string option with defaultAsFlag. (default as flag:
                                  default)
          --number-flag [<number-flag>]
                                  An integer option with defaultAsFlag. (default as
                                  flag: 42)
          --bool-flag [<bool-flag>]
                                  A boolean option with defaultAsFlag. (default as
                                  flag: true)
          --transform-flag [<transform-flag>]
                                  A string option with defaultAsFlag and transform.
                                  (default as flag: transformed)
          -r, --regular <regular> A regular option for comparison.
          -h, --help              Show help information.

        """)
  }

  struct DefaultAsFlagWithShortNames: ParsableArguments {
    @Option(
      name: .shortAndLong, defaultAsFlag: "short", help: "Short and long names."
    )
    var shortAndLong: String?

    @Option(
      name: [.customShort("o")], defaultAsFlag: "s",
      help: "Different short name.")
    var shortOnly: String?
  }

  func testDefaultAsFlagWithShortNames() {
    AssertHelp(
      .default, for: DefaultAsFlagWithShortNames.self,
      equals: """
        USAGE: default_as_flag_with_short_names [--short-and-long [<short-and-long>]] [-o [<o>]]

        OPTIONS:
          -s, --short-and-long [<short-and-long>]
                                  Short and long names. (default as flag: short)
          -o [<o>]                Different short name. (default as flag: s)
          -h, --help              Show help information.

        """)
  }

  struct MixedOptionTypes: ParsableArguments {
    @Flag(help: "A regular flag.")
    var flag: Bool = false

    @Option(defaultAsFlag: "mixed", help: "A defaultAsFlag option.")
    var defaultAsFlag: String?

    @Option(help: "A regular option.")
    var regular: String?

    @Argument(help: "A positional argument.")
    var positional: String?
  }

  func testMixedOptionTypes() {
    AssertHelp(
      .default, for: MixedOptionTypes.self,
      equals: """
        USAGE: mixed_option_types [--flag] [--default-as-flag [<default-as-flag>]] [--regular <regular>] [<positional>]

        ARGUMENTS:
          <positional>            A positional argument.

        OPTIONS:
          --flag                  A regular flag.
          --default-as-flag [<default-as-flag>]
                                  A defaultAsFlag option. (default as flag: mixed)
          --regular <regular>     A regular option.
          -h, --help              Show help information.

        """)
  }
}
