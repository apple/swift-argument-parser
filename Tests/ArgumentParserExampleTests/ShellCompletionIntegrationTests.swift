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

#if !os(Windows) && !os(WASI) && canImport(Darwin)

import ArgumentParserTestHelpers
import XCTest

// MARK: Test Fixtures

let completionTestFixtures: [CompletionTestFixture] = [
  // MARK: Subcommand completions

  CompletionTestFixture(
    name: "TopLevelSubcommands",
    input: "math ",
    expected: ["add", "multiply", "stats", "help"],
    bashExpected: [
      "--help", "--version", "-h", "add", "help", "multiply", "stats",
    ]
  ),
  CompletionTestFixture(
    name: "TopLevelSubcommandPrefix",
    input: "math s",
    expected: ["stats"]
  ),
  CompletionTestFixture(
    name: "StatsSubcommands",
    input: "math stats ",
    expected: ["average", "stdev", "quantiles"],
    bashExpected: [
      "--help", "--version", "-h", "average", "quantiles", "stdev",
    ]
  ),
  CompletionTestFixture(
    name: "StatsSubcommandPrefix",
    input: "math stats a",
    expected: ["average"]
  ),

  // MARK: Flag/option completions

  CompletionTestFixture(
    name: "TopLevelFlags",
    input: "math -",
    expected: ["--version", "-h", "--help"],
    useContainsCheck: [.fish]
  ),
  CompletionTestFixture(
    name: "AddFlags",
    input: "math add -",
    expected: ["--hex-output", "-x", "--version", "-h", "--help"],
    useContainsCheck: [.fish]
  ),
  CompletionTestFixture(
    name: "AddFlagPrefix",
    input: "math add --h",
    expected: ["--hex-output", "--help"]
  ),
  CompletionTestFixture(
    name: "NonRepeatingFlagConsumed",
    input: "math add --hex-output -",
    expected: ["--version", "-h", "--help"],
    xfail: [.bash, .fish]
  ),

  // MARK: Option value completions

  CompletionTestFixture(
    name: "AverageKindValues",
    input: "math stats average --kind ",
    expected: ["mean", "median", "mode"]
  ),
  CompletionTestFixture(
    name: "AverageKindValuePrefix",
    input: "math stats average --kind m",
    expected: ["mean", "median", "mode"],
  ),
  CompletionTestFixture(
    name: "AverageKindValuePrefix2",
    input: "math stats average --kind me",
    expected: ["mean", "median"],
  ),

  // MARK: Positional list completions

  CompletionTestFixture(
    name: "QuantilesFirstPositional",
    input: "math stats quantiles ",
    expected: ["alphabet", "alligator", "branch", "braggart"]
  ),
  CompletionTestFixture(
    name: "QuantilesFirstPositionalPrefix",
    input: "math stats quantiles a",
    expected: ["alphabet", "alligator"]
  ),

  // MARK: Custom completions (calls back into binary)

  CompletionTestFixture(
    name: "QuantilesCustomOption",
    input: "math stats quantiles --custom ",
    expected: ["hello", "helicopter", "heliotrope"],
    xfail: [.fish]
  ),
  CompletionTestFixture(
    name: "QuantilesCustomPositional",
    input: "math stats quantiles foo ",
    expected: ["alabaster", "breakfast", "crunch", "crash"],
    xfail: [.fish]
  ),

  // MARK: Flags after subcommand navigation

  CompletionTestFixture(
    name: "QuantilesFlags",
    input: "math stats quantiles -",
    expected: [
      "--version", "-h", "--help",
      "--file", "--directory", "--shell", "--custom", "--custom-deprecated",
    ],
    useContainsCheck: [.fish]
  ),
]

final class ShellCompletionIntegrationTests: XCTestCase {
  private func requireShell(_ shell: CompletionTestFixture.Shell) throws
    -> String
  {
    guard isShellAvailable(shell.rawValue) else {
      throw XCTSkip("\(shell.rawValue) is not available")
    }
    let script = try AssertExecuteCommand(
      command: "math --generate-completion-script \(shell.rawValue)")
    XCTAssertFalse(
      script.isEmpty, "Failed to generate \(shell.rawValue) completion script")
    return script
  }

  private func completions(
    for shell: CompletionTestFixture.Shell,
    commandLine: String,
    script: String
  ) throws -> [String] {
    switch shell {
    case .bash:
      try bashCompletions(
        commandLine: commandLine,
        completionScript: script,
        binaryDir: debugURL.path)
    case .fish:
      try fishCompletions(
        commandLine: commandLine,
        completionScript: script,
        binaryDir: debugURL.path)
    case .zsh:
      try zshCompletions(
        commandLine: commandLine,
        completionScript: script,
        binaryDir: debugURL.path)
    }
  }

  private func runFixture(
    _ fixture: CompletionTestFixture,
    shell: CompletionTestFixture.Shell,
    script: String
  ) throws {
    let results = try completions(
      for: shell, commandLine: fixture.input, script: script)
    let expected = fixture.expected(for: shell)

    if fixture.xfail.contains(shell) {
      XCTExpectFailure(
        "[\(fixture.name)] \(shell.rawValue): Expected failure, none found")
    }
    if fixture.useContainsCheck.contains(shell) {
      let missing =
        expected
        .filter { !results.contains($0) }
        .map { "'\($0)'" }
        .joined(separator: ", ")
      if !missing.isEmpty {
        XCTFail(
          """
          [\(fixture.name)] \(shell.rawValue):\
          Expected \(missing) in completions for '\(fixture.input)', got \(results)
          """)
      }
      if results.sorted() == expected.sorted() {
        XCTFail(
          "[\(fixture.name)] \(shell.rawValue): Unnecessary contains check setting"
        )
      }

    } else {
      XCTAssertEqual(
        results.sorted(), expected.sorted(),
        "[\(fixture.name)] \(shell.rawValue) completions for '\(fixture.input)'"
      )
    }
  }

  private func runAllFixtures(shell: CompletionTestFixture.Shell) throws {
    let script = try requireShell(shell)
    for fixture in completionTestFixtures {
      try runFixture(fixture, shell: shell, script: script)
    }
  }
}

// MARK: Test runners

extension ShellCompletionIntegrationTests {
  func testBashCompletions() throws {
    try runAllFixtures(shell: .bash)
  }

  func testFishCompletions() throws {
    try runAllFixtures(shell: .fish)
  }

  func testZshCompletions() throws {
    try runAllFixtures(shell: .zsh)
  }
}

// MARK: Fixture type

struct CompletionTestFixture {
  /// The name of the test case.
  var name: String

  /// The starting point for command-line completions.
  var input: String

  /// The expected completions for each shell.
  var expected: [String]

  /// The expected completions for Bash, if different.
  var bashExpected: [String]?
  /// The expected completions for Fish, if different.
  var fishExpected: [String]?
  /// The expected completions for Zsh, if different.
  var zshExpected: [String]?

  /// The set of shells for which verifying results should use a contains check
  /// instead of requiring an exact match.
  var useContainsCheck: Set<Shell> = []

  /// The set of shells for which this test case should be excluded.
  var xfail: Set<Shell> = []

  enum Shell: String, CaseIterable {
    case bash, fish, zsh
  }

  func expected(for shell: Shell) -> [String] {
    switch shell {
    case .bash: return bashExpected ?? expected
    case .fish: return fishExpected ?? expected
    case .zsh: return zshExpected ?? expected
    }
  }
}

#endif
