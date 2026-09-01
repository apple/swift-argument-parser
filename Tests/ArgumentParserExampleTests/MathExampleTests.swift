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
) struct MathExampleTests {
  init() {
    Platform.Environment[.columns] = nil
  }

  @Test func math_Simple() throws {
    try requireExecuteCommand(command: "math 1 2 3 4 5", expected: "15\n")
    try requireExecuteCommand(
      command: "math multiply 1 2 3 4 5", expected: "120\n")
  }

  @Test func math_Help() throws {
    let helpText = """
      OVERVIEW: A utility for performing maths.

      USAGE: math <subcommand>

      OPTIONS:
        --version               Show the version.
        -h, --help              Show help information.

      SUBCOMMANDS:
        add (default)           Print the sum of the values.
        multiply, mul           Print the product of the values.
        stats                   Calculate descriptive statistics.

        See 'math help <subcommand>' for detailed help.

      """

    try requireExecuteCommand(command: "math -h", expected: helpText)
    try requireExecuteCommand(command: "math --help", expected: helpText)
    try requireExecuteCommand(command: "math help", expected: helpText)
  }

  @Test func math_AddHelp() throws {
    let helpText = """
      OVERVIEW: Print the sum of the values.

      USAGE: math add [--hex-output] [<values> ...]

      ARGUMENTS:
        <values>                A group of integers to operate on.

      OPTIONS:
        -x, --hex-output        Use hexadecimal notation for the result.
        --version               Show the version.
        -h, --help              Show help information.


      """

    try requireExecuteCommand(command: "math add -h", expected: helpText)
    try requireExecuteCommand(command: "math add --help", expected: helpText)
    try requireExecuteCommand(command: "math help add", expected: helpText)

    // Verify that extra help flags are ignored.
    try requireExecuteCommand(command: "math help add -h", expected: helpText)
    try requireExecuteCommand(
      command: "math help add -help", expected: helpText)
    try requireExecuteCommand(
      command: "math help add --help", expected: helpText)
  }

  @Test func math_StatsMeanHelp() throws {
    let helpText = """
      OVERVIEW: Print the average of the values.

      USAGE: math stats average [--kind <kind>] [<values> ...]

      ARGUMENTS:
        <values>                A group of floating-point values to operate on.

      OPTIONS:
        --kind <kind>           The kind of average to provide. (values: mean,
                                median, mode; default: mean)
        --version               Show the version.
        -h, --help              Show help information.


      """

    try requireExecuteCommand(
      command: "math stats average -h", expected: helpText)
    try requireExecuteCommand(
      command: "math stats average --help", expected: helpText)
    try requireExecuteCommand(
      command: "math help stats average", expected: helpText)
  }

  @Test func math_StatsQuantilesHelp() throws {
    let helpText = """
      OVERVIEW: Print the quantiles of the values (TBD).

      USAGE: math stats quantiles [<one-of-four>] [<custom-arg>] [<custom-deprecated-arg>] [<values> ...] [--file <file>] [--directory <directory>] [--shell <shell>] [--custom <custom>] [--custom-deprecated <custom-deprecated>]

      ARGUMENTS:
        <one-of-four>
        <custom-arg>
        <custom-deprecated-arg>
        <values>                A group of floating-point values to operate on.

      OPTIONS:
        --file <file>
        --directory <directory>
        --shell <shell>
        --custom <custom>
        --custom-deprecated <custom-deprecated>
        --version               Show the version.
        -h, --help              Show help information.


      """

    // The "quantiles" subcommand's run() method is unimplemented, so it
    // just generates the help text.
    try requireExecuteCommand(
      command: "math stats quantiles", expected: helpText)

    try requireExecuteCommand(
      command: "math stats quantiles -h", expected: helpText)
    try requireExecuteCommand(
      command: "math stats quantiles --help", expected: helpText)
    try requireExecuteCommand(
      command: "math help stats quantiles", expected: helpText)
  }

  @Test func math_CustomValidation() throws {
    try requireExecuteCommand(
      command: "math stats average --kind mode",
      expected: """
        Error: Please provide at least one value to calculate the mode.
        Usage: math stats average [--kind <kind>] [<values> ...]
          See 'math stats average --help' for more information.

        """,
      exitCode: .validationFailure)
  }

  @Test func math_Versions() throws {
    try requireExecuteCommand(
      command: "math --version",
      expected: "1.0.0\n")
    try requireExecuteCommand(
      command: "math stats --version",
      expected: "1.0.0\n")
    try requireExecuteCommand(
      command: "math stats average --version",
      expected: "1.5.0-alpha\n")
  }

  @Test func math_ExitCodes() throws {
    try requireExecuteCommand(
      command: "math stats quantiles --test-success-exit-code",
      expected: "",
      exitCode: .success)
    try requireExecuteCommand(
      command: "math stats quantiles --test-failure-exit-code",
      expected: "",
      exitCode: .failure)
    try requireExecuteCommand(
      command: "math stats quantiles --test-validation-exit-code",
      expected: "",
      exitCode: .validationFailure)
    try requireExecuteCommand(
      command: "math stats quantiles --test-custom-exit-code 42",
      expected: "",
      exitCode: ExitCode(42))
  }

  @Test func math_Fail() throws {
    try requireExecuteCommand(
      command: "math --foo",
      expected: """
        Error: Unknown option '--foo'
        Usage: math add [--hex-output] [<values> ...]
          See 'math add --help' for more information.

        """,
      exitCode: .validationFailure)

    try requireExecuteCommand(
      command: "math ZZZ",
      expected: """
        Error: The value 'ZZZ' is invalid for '<values>'
        Help:  <values>  A group of integers to operate on.
        Usage: math add [--hex-output] [<values> ...]
          See 'math add --help' for more information.

        """,
      exitCode: .validationFailure)
  }
}

// MARK: - Completion Script

// swift-format-ignore: AlwaysUseLowerCamelCase
extension MathExampleTests {
  @Test(
    .requiresProcessExecution
  ) func mathBashCompletionScript() throws {
    let script = try requireExecuteCommand(
      command: "math --generate-completion-script bash")
    try expectSnapshot(actual: script, extension: "bash")
  }

  @Test(
    .requiresProcessExecution
  ) func mathZshCompletionScript() throws {
    let script = try requireExecuteCommand(
      command: "math --generate-completion-script zsh")
    try expectSnapshot(actual: script, extension: "zsh")
  }

  @Test(
    .requiresProcessExecution
  ) func mathFishCompletionScript() throws {
    let script = try requireExecuteCommand(
      command: "math --generate-completion-script fish")
    try expectSnapshot(actual: script, extension: "fish")
  }

  @Test func math_BashCustomCompletion() throws {
    try runMathCustomCompletion(forShell: .bash)
  }

  @Test func math_FishCustomCompletion() throws {
    try runMathCustomCompletion(forShell: .fish)
  }

  @Test func math_ZshCustomCompletion() throws {
    try runMathCustomCompletion(forShell: .zsh)
  }

  private func runMathCustomCompletion(
    forShell shell: CompletionShell
  ) throws {
    try requireExecuteCommand(
      command: "math ---completion stats quantiles -- --custom 0 0",
      expected: shell.format(completions: [
        "hello",
        "helicopter",
        "heliotrope",
      ]) + "\n",
      environment: [
        Platform.Environment.Key.shellName.rawValue: shell.rawValue
      ]
    )

    try requireExecuteCommand(
      command: "math ---completion stats quantiles -- --custom 0 1 h",
      expected: shell.format(completions: [
        "hello",
        "helicopter",
        "heliotrope",
      ]) + "\n",
      environment: [
        Platform.Environment.Key.shellName.rawValue: shell.rawValue
      ]
    )

    try requireExecuteCommand(
      command: "math ---completion stats quantiles -- --custom 0 1 a",
      expected: shell.format(completions: [
        "aardvark",
        "aaaaalbert",
      ]) + "\n",
      environment: [
        Platform.Environment.Key.shellName.rawValue: shell.rawValue
      ]
    )
  }
}
