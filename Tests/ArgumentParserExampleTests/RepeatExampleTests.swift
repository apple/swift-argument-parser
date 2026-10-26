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

import ArgumentParserTestHelpers
import Testing

@testable import ArgumentParser

@Suite(
  .serialized
) struct RepeatExampleTests {
  init() {
    Platform.Environment[.columns] = nil
  }

  @Test func repeatBasic() throws {
    try requireExecuteCommand(
      command: "repeat hello",
      expected: """
        hello
        hello

        """)
  }

  @Test func repeat_include_counter() throws {
    try requireExecuteCommand(
      command: "repeat --include-counter hello",
      expected: """
        1: hello
        2: hello

        """)
  }

  @Test func repeat_Count() throws {
    try requireExecuteCommand(
      command: "repeat hello --count 6",
      expected: """
        hello
        hello
        hello
        hello
        hello
        hello

        """)
  }

  @Test(arguments: [false, true])
  func repeat_ZeroCount(includeCounter: Bool) throws {
    var arguments = ["repeat", "hello", "--count", "0"]
    if includeCounter {
      arguments.append("--include-counter")
    }
    try requireExecuteCommand(command: arguments, expected: "")
  }

  @Test(arguments: [-1, Int.min])
  func repeat_NegativeCount(count: Int) throws {
    try requireExecuteCommand(
      command: ["repeat", "hello", "--count=\(count)"],
      expected: """
        Error: Count must be zero or greater.
        Usage: repeat [--count <count>] [--include-counter] <phrase>
          See 'repeat --help' for more information.

        """,
      exitCode: .validationFailure)
  }

  @Test func repeat_OneCountWithCounter() throws {
    try requireExecuteCommand(
      command: "repeat hello --count 1 --include-counter",
      expected: "1: hello\n")
  }

  @Test func repeat_Help() throws {
    let helpText = """
      USAGE: repeat [--count <count>] [--include-counter] <phrase>

      ARGUMENTS:
        <phrase>                The phrase to repeat.

      OPTIONS:
        --count <count>         How many times to repeat 'phrase'.
        --include-counter       Include a counter with each repetition.
        -h, --help              Show help information.


      """

    try requireExecuteCommand(command: "repeat -h", expected: helpText)
    try requireExecuteCommand(command: "repeat --help", expected: helpText)
  }

  @Test func repeat_Fail() throws {
    try requireExecuteCommand(
      command: "repeat",
      expected: """
        Error: Missing expected argument '<phrase>'

        USAGE: repeat [--count <count>] [--include-counter] <phrase>

        ARGUMENTS:
          <phrase>                The phrase to repeat.

        OPTIONS:
          --count <count>         How many times to repeat 'phrase'.
          --include-counter       Include a counter with each repetition.
          -h, --help              Show help information.


        """,
      exitCode: .validationFailure)

    try requireExecuteCommand(
      command: "repeat hello --count",
      expected: """
        Error: Missing value for '--count <count>'
        Help:  --count <count>  How many times to repeat 'phrase'.
        Usage: repeat [--count <count>] [--include-counter] <phrase>
          See 'repeat --help' for more information.

        """,
      exitCode: .validationFailure)

    try requireExecuteCommand(
      command: "repeat hello --count ZZZ",
      expected: """
        Error: The value 'ZZZ' is invalid for '--count <count>'
        Help:  --count <count>  How many times to repeat 'phrase'.
        Usage: repeat [--count <count>] [--include-counter] <phrase>
          See 'repeat --help' for more information.

        """,
      exitCode: .validationFailure)

    try requireExecuteCommand(
      command: "repeat --version hello",
      expected: """
        Error: Unknown option '--version'
        Usage: repeat [--count <count>] [--include-counter] <phrase>
          See 'repeat --help' for more information.

        """,
      exitCode: .validationFailure)
  }
}
