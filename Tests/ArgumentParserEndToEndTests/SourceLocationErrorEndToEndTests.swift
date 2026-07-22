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
import Foundation
import Testing

// Behavior tests - CLI Failure Source Location, response-file-gated.
//
// These tests verify that:
//   * When the input contains NO @file reference, error messages are
//     byte-for-byte identical to the legacy behavior (no location block).
//   * When the input contains AT LEAST ONE @file reference, error messages
//     include a multi-line `at … included from …` location block per the
//     plan in `plans/source-location-tracking-architecture.md`.
//
// The "gate inactive" tests act as a regression guard — they should pass
// today and continue to pass after the feature lands. The "gate active"
// tests are expected to FAIL until the feature is implemented.
//
// Shared message-extraction helpers live in
// `SourceLocationEndToEndTestSupport.swift`.

@Suite struct SourceLocationErrorEndToEndTests {}

// MARK: - Test Commands

private struct ErrorCommand: ParsableCommand {
  static var responseFilePrefix: Character? { "@" }
  @Option var name: String
  @Option var count: Int = 1
  @Flag var verbose = false
}

// MARK: - Gate Inactive (regression guard)
//
// These tests assert that argv-only invocations produce the same error
// messages as today. They should pass both before and after the feature
// lands. If any of these tests fails after the feature ships, the gate
// has leaked.

extension SourceLocationErrorEndToEndTests {

  @Test func gateInactiveUnknownOptionMessageUnchanged() async throws {
    expectErrorMessage(
      ErrorCommand.self,
      ["--name", "a", "--bogus"],
      "Unknown option '--bogus'"
    )
  }

  @Test func gateInactiveMissingValueForOptionMessageUnchanged() async throws {
    expectErrorMessage(
      ErrorCommand.self,
      ["--name", "a", "--count"],
      "Missing value for '--count <count>'")
  }

  @Test func gateInactiveUnableToParseValueMessageUnchanged() async throws {
    expectErrorMessage(
      ErrorCommand.self,
      ["--name", "a", "--count", "not-a-number"],
      "The value 'not-a-number' is invalid for '--count <count>'")
  }

  @Test func gateInactiveUnexpectedExtraValuesMessageUnchanged() async throws {
    expectErrorMessage(
      ErrorCommand.self,
      ["--name", "a", "extra"],
      "Unexpected argument 'extra'")
  }

  @Test func gateInactiveNoLocationBlockSubstrings() async throws {
    // Defensive: the rendered string must never contain the new location
    // markers when the gate is inactive.
    let m = try errorMessage(
      for: ErrorCommand.self, arguments: ["--name", "a", "--bogus"])
    #expect(
      !m.contains("at argv["),
      "argv-only invocation should not emit `at argv[N]`: got \(m)")
    #expect(
      !m.contains("included from"),
      "argv-only invocation should not emit `included from`: got \(m)")
  }
}

// MARK: - Gate Active — single response file
//
// These tests are expected to FAIL today. They will pass once the
// `at <file>:<line>` location block is appended to gated error messages.

extension SourceLocationErrorEndToEndTests {

  @Test func gateActiveSingleFileUnknownOptionIncludesFileLine() async throws {
    try await withTemporaryFile(
      "unknown-opt.txt",
      content: """
        --name
        a
        --bogus
        """
    ) { responseFile in
      let m = try errorMessage(
        for: ErrorCommand.self, arguments: ["@\(responseFile)"])

      #expect(
        m.contains("Unknown option '--bogus'"),
        "Should still include the original error text: got \(m)")
      #expect(
        m.contains("at \(responseFile):3"),
        "Should include `at <file>:<line>` for the offending arg: got \(m)")
    }
  }

  @Test func gateActiveSingleFileMissingValueIncludesFileLine() async throws {
    try await withTemporaryFile(
      "missing-value.txt",
      content: """
        --name
        a
        --count
        """
    ) { responseFile in
      let m = try errorMessage(
        for: ErrorCommand.self, arguments: ["@\(responseFile)"])

      #expect(
        m.contains("Missing value for '--count <count>'"),
        "Should still include the original error text: got \(m)")
      #expect(
        m.contains("at \(responseFile):3"),
        "Should pinpoint the offending `--count` to line 3: got \(m)")
    }
  }

  @Test func gateActiveSingleFileUnableToParseValueIncludesFileLine()
    async throws
  {
    try await withTemporaryFile(
      "bad-value.txt",
      content: """
        --name
        a
        --count
        not-a-number
        """
    ) { responseFile in
      let m = try errorMessage(
        for: ErrorCommand.self, arguments: ["@\(responseFile)"])

      #expect(
        m.contains("not-a-number"),
        "Should still include the offending value: got \(m)")
      #expect(
        m.contains("at \(responseFile):4"),
        "Should pinpoint the bad value to line 4: got \(m)")
    }
  }

  @Test func gateActiveSingleFileUnexpectedExtraValueIncludesFileLine()
    async throws
  {
    try await withTemporaryFile(
      "extra.txt",
      content: """
        --name
        a
        extra
        """
    ) { responseFile in
      let m = try errorMessage(
        for: ErrorCommand.self, arguments: ["@\(responseFile)"])

      #expect(
        m.contains("Unexpected argument 'extra'"),
        "Should still include the original error text: got \(m)")
      #expect(
        m.contains("at \(responseFile):3"),
        "Should pinpoint the extra value to line 3: got \(m)")
    }
  }
}

// MARK: - Gate Active — nested response files
//
// Verifies the `at … included from …` chain rendering. Expected to FAIL
// until the feature lands.

extension SourceLocationErrorEndToEndTests {

  @Test func gateActiveNestedFilesIncludeChainOuterMostLast() async throws {
    try await withTemporaryDirectory { dir in
      let inner = try dir.createTestFile(
        "inner.txt",
        content: """
          --name
          a
          --bogus
          """)

      let outer = try dir.createTestFile(
        "outer.txt",
        content: """
          @\(inner)
          """)

      let m = try errorMessage(
        for: ErrorCommand.self, arguments: ["@\(outer)"])

      #expect(
        m.contains("Unknown option '--bogus'"),
        "Should still include the original error text: got \(m)")
      #expect(
        m.contains("at \(inner):3"),
        "Innermost frame should be the file the arg literally lives in: got \(m)"
      )
      #expect(
        m.contains("included from \(outer):1"),
        "Outer file should appear as an `included from` line: got \(m)")

      // The innermost frame must appear BEFORE the outer frame in the rendered
      // text — chain is rendered innermost first, outermost last.
      if let innerRange = m.range(of: "at \(inner):3"),
        let outerRange = m.range(of: "included from \(outer):1")
      {
        #expect(
          innerRange.lowerBound < outerRange.lowerBound,
          "Innermost `at` must precede `included from` lines: got \(m)")
      }
    }
  }

  @Test func gateActiveThreeLevelNestingChainHasAllFrames() async throws {
    try await withTemporaryDirectory { dir in
      let level3 = try dir.createTestFile(
        "lvl3.txt",
        content: """
          --name
          a
          --bogus
          """)
      let level2 = try dir.createTestFile(
        "lvl2.txt",
        content: """
          @\(level3)
          """)
      let level1 = try dir.createTestFile(
        "lvl1.txt",
        content: """
          @\(level2)
          """)

      let m = try errorMessage(
        for: ErrorCommand.self, arguments: ["@\(level1)"])

      #expect(m.contains("at \(level3):3"), "Missing innermost frame: \(m)")
      #expect(
        m.contains("included from \(level2):1"),
        "Missing middle frame: \(m)")
      #expect(
        m.contains("included from \(level1):1"),
        "Missing outermost file frame: \(m)")

      // The innermost frame must appear BEFORE the outer frame in the rendered
      // text — chain is rendered innermost first, outermost last.
      if let topRange = m.range(of: "at \(level3):3"),
        let midRange = m.range(of: "included from \(level2):1"),
        let outerRange = m.range(of: "included from \(level1):1")
      {
        #expect(
          topRange.lowerBound < midRange.lowerBound,
          "topRange `at` must precede middle `included from` lines: got \(m)"
        )
        #expect(
          midRange.lowerBound < outerRange.lowerBound,
          "middle `included from` must precede outer `included from` lines: got \(m)"
        )
      }
    }
  }
}

// MARK: - Gate Active — mixed argv + response file
//
// When the gate is active because there's a response file in the input,
// argv-origin errors should also be annotated (with `at argv[N]` rather
// than a file:line). Expected to FAIL until the feature lands.

extension SourceLocationErrorEndToEndTests {

  @Test func gateActiveMixedInputArgvErrorShowsArgvIndex() async throws {
    // Put a valid response file early in argv, then an argv-origin error.
    try await withTemporaryFile(
      "valid.txt",
      content: """
        --name
        a
        """
    ) { validFile in
      let m = try errorMessage(
        for: ErrorCommand.self,
        arguments: ["@\(validFile)", "--bogus"])

      #expect(
        m.contains("Unknown option '--bogus'"),
        "Should still include the original error text: got \(m)")
      // The error came from argv[1] (post the @file at argv[0]).
      #expect(
        m.contains("at argv[1]"),
        "Argv-origin error should be annotated with `at argv[N]` when the gate is active: got \(m)"
      )
    }
  }
}
