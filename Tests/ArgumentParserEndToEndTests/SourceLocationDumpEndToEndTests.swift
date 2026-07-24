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

import ArgumentParserTestHelpers
import Foundation
import Testing

@testable import ArgumentParser

// Behavior tests of `--experimental-dump-arguments-source-location`.
//
// These tests drive a sample command with the new option and assert on the
// emitted dump output (text + JSON).
//
// They are expected to FAIL today: the option does not exist yet, so today
// `T.parse([...])` throws an `Unknown option` error instead of producing
// the dump.  Once Phase C of the plan lands, parsing the option throws a
// `dumpArgumentsSourceLocationRequested(format:)` parser error which the
// framework converts to a clean-exit help message containing the dump.
//
// Message-extraction helpers live in
// `SourceLocationEndToEndTestSupport.swift`.

@Suite struct SourceLocationDumpEndToEndTests {

  /// Decode the dump output into the typed production model.
  ///
  /// Returns `nil` if the input isn't valid JSON for the schema.
  fileprivate func decodeDump(
    _ raw: String
  ) -> SourceLocationDumpGenerator.CommandNode? {
    guard let data = raw.data(using: .utf8) else { return nil }
    return try? JSONDecoder().decode(
      SourceLocationDumpGenerator.CommandNode.self, from: data)
  }
}

// MARK: - Typed accessors for the dump wire format
//
// The generator's `CommandNode`/`ArgumentEntry`/`ValueEntry` types double
// as the JSON schema. `@testable import ArgumentParser` gives us access
// to them; these extensions add test-only convenience accessors.

extension SourceLocationDumpGenerator.CommandNode {
  /// First argument entry whose display name contains any of `candidates`.
  ///
  /// Preserves the existing lookup-by-substring semantics.
  fileprivate func firstArgument(
    matching candidates: [String]
  ) -> SourceLocationDumpGenerator.ArgumentEntry? {
    arguments.first { arg in
      candidates.contains { arg.name.contains($0) }
    }
  }
}

extension SourceLocationDumpGenerator.ArgumentEntry {
  /// Convenience for scalar arguments — the single value entry.
  fileprivate var firstValue: SourceLocationDumpGenerator.ValueEntry? {
    values.first
  }
}

extension SourceLocationDumpGenerator.ValueEntry {
  /// The argv index this value's source resolves to, or `nil` if the
  /// source isn't an argv origin (i.e., it's `.defaultValue` or
  /// `.responseFile(_,_)`).
  fileprivate var argvIndex: Int? {
    if case .argumentIndex(let idx) = source {
      return idx.inputIndex.rawValue
    }
    return nil
  }

  /// The flattened chain of response-file steps for a response-file
  /// origin, or `nil` if the source isn't `.responseFile(_,_)`.
  fileprivate var responseFileChain: [InputOrigin.ResponseFileStep]? {
    if case .responseFile = source { return source.chainAsSteps() }
    return nil
  }
}

// MARK: - Test Commands

private struct DumpRoot: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "tool",
    subcommands: [DumpDeploy.self]
  )

  @Flag(name: .long) var globalFlag = false
}

private struct DumpDeploy: ParsableCommand {
  static let configuration = CommandConfiguration(commandName: "deploy")

  @Option var env: String
  @Option var count: Int = 1
  @Argument var target: String
}

private struct DumpSimple: ParsableCommand {
  static let responseFilePrefix: Character? = "@"
  static let configuration = CommandConfiguration(commandName: "simple")

  @Option var name: String
  @Option var count: Int = 1
}

private struct DumpArrayCommand: ParsableCommand {
  static let configuration = CommandConfiguration(commandName: "array")

  /// Repeatable named option — each value pair `--tag X` contributes one
  /// element, and each element should carry the argv index of its own
  /// value (not the option name, and not the aggregate origin of the
  /// whole array).
  @Option(name: .customLong("tag")) var tags: [String] = []

  /// Positional array — each value has its own argv index.
  @Argument var files: [String] = []
}

/// Kitchen-sink command exercising the full matrix of argument shapes.
private struct DumpKitchenSink: ParsableCommand {
  static let responseFilePrefix: Character? = "@"
  static let configuration = CommandConfiguration(commandName: "kitchen")

  // Scalar option with both short and long names.
  @Option(name: [.short, .long]) var name: String

  // Typed scalar option.
  @Option var count: Int = 0

  // Boolean flag with both a short and long name — can be packed with
  // another short flag.
  @Flag(name: [.short, .long]) var verbose = false

  // Boolean flag with a short name — for testing packed short options.
  @Flag(name: [.short, .long]) var force = false

  // Repeatable named option.
  @Option(name: .customLong("tag")) var tags: [String] = []

  // `defaultAsFlag` option — three invocation shapes:
  //   • omitted                    → property is nil (no origin)
  //   • `--log-level` (bare)       → property = "info" (the flag default)
  //   • `--log-level=<value>`      → property = <value>
  //
  // Using `.next` (rather than the `defaultAsFlag` default of
  // `.scanningForValue`) so that a bare `--log-level` does NOT read
  // ahead past subsequent option tokens looking for a value.
  @Option(
    name: .customLong("log-level"),
    defaultAsFlag: "info",
    parsing: .next
  ) var logLevel: String? = nil

  // Positional (single required).
  @Argument var target: String

  // Positional array (captures the rest).
  @Argument var extras: [String] = []
}

// MARK: - Text format (default via `defaultAsFlag`)

extension SourceLocationDumpEndToEndTests {

  @Test func textTopLevelCommandArgvOnlyRendersCommandHeader() async throws {
    let out = try fullMessage(
      for: DumpSimple.self,
      arguments: [
        "--name", "alpha", "--experimental-dump-arguments-source-location",
      ])

    #expect(
      out.contains("simple"),
      "Text dump should begin with the command name: got \(out)")
    #expect(
      out.contains("--name"),
      "Text dump should list the --name option: got \(out)")
    #expect(
      out.contains("alpha"),
      "Text dump should include the value `alpha`: got \(out)")
    #expect(
      out.contains("argv["),
      "Text dump should reference an argv index for argv-origin args: \(out)")
  }

  @Test func textArgvOnlyMarksDefaultValuedProperty() async throws {
    // `count` defaults to 1 and is not on the command line, so the dump
    // should mark it as `(default)`.
    let out = try fullMessage(
      for: DumpSimple.self,
      arguments: [
        "--name", "alpha", "--experimental-dump-arguments-source-location",
      ])

    #expect(
      out.contains("--count"),
      "Default-valued options should still appear in the dump: \(out)")
    #expect(
      out.contains("(default)"),
      "Default-valued options should be tagged `(default)`: \(out)")
  }

  @Test func textSubcommandRendersAsNestedNode() async throws {
    let out = try fullMessage(
      for: DumpRoot.self,
      arguments: [
        "--global-flag",
        "deploy",
        "--env", "prod",
        "target1",
        "--experimental-dump-arguments-source-location",
      ])

    #expect(
      out.contains("tool"),
      "Root command name should appear at the top: \(out)")
    #expect(
      out.contains("deploy"),
      "Subcommand should appear nested under the root: \(out)")
    #expect(
      out.contains("--global-flag"),
      "Root-level flag should be listed under the root: \(out)")
    #expect(
      out.contains("--env"),
      "Subcommand option should be listed under the subcommand: \(out)")
    #expect(
      out.contains("target1"),
      "Positional should appear with its value: \(out)")

    // Structural check: --global-flag should appear before `deploy`, which
    // should appear before --env (root → subcommand → its args).
    let globalIdx = try #require(
      out.range(of: "--global-flag"),
      "Anchor is missing in output: \(out)"
    )
    let deployIdx = try #require(
      out.range(of: "deploy"),
      "Anchor is missing in output: \(out)"
    )
    let envIdx = try #require(
      out.range(of: "--env"),
      "Anchor is missing in output: \(out)"
    )

    #expect(
      globalIdx.lowerBound < deployIdx.lowerBound,
      "Root-level args should appear before subcommand block: \(out)")
    #expect(
      deployIdx.lowerBound < envIdx.lowerBound,
      "Subcommand header should appear before its args: \(out)")
  }

  @Test func textResponseFileArgLeafShowsAtAndIncludedFrom() async throws {
    try await withTemporaryFile(
      "rfdump.txt",
      content: """
        --name
        beta
        """
    ) { responseFile in
      let out = try fullMessage(
        for: DumpSimple.self,
        arguments: [
          "@\(responseFile)",
          "--experimental-dump-arguments-source-location",
        ])

      #expect(
        out.contains("--name"),
        "Dump must list --name: \(out)")
      #expect(
        out.contains("beta"),
        "Dump must include the value beta: \(out)")
      #expect(
        out.contains("at \(responseFile):2"),
        "Leaf must show `at <file>:<line>` for response-file origin: \(out)")
      #expect(
        out.contains("included from argv[0]"),
        "Leaf must show `included from argv[N]` for the @file entry: \(out)")
    }
  }
}

// MARK: - JSON format (via `=json`)

extension SourceLocationDumpEndToEndTests {

  @Test func jsonTopLevelCommandArgvOnlyValidJSONAndCommandKey() async throws {
    let out = try fullMessage(
      for: DumpSimple.self,
      arguments: [
        "--name", "alpha",
        "--experimental-dump-arguments-source-location=json",
      ])

    let dump = try #require(
      decodeDump(out), "Output is not valid JSON: \(out)")
    #expect(
      dump.command == "simple",
      "JSON should have command='simple': \(dump)")
    #expect(
      !dump.arguments.isEmpty,
      "JSON should have an `arguments` array: \(dump)")
  }

  @Test func jsonResponseFileArgChainOrderedInnermostFirst() async throws {
    try await withTemporaryDirectory { dir in
      let inner = try dir.createTestFile(
        "inner-json.txt",
        content: """
          --name
          gamma
          """)
      let outer = try dir.createTestFile(
        "outer-json.txt",
        content: """
          @\(inner)
          """)

      let out = try fullMessage(
        for: DumpSimple.self,
        arguments: [
          "@\(outer)",
          "--experimental-dump-arguments-source-location=json",
        ])

      let dump = try #require(
        decodeDump(out), "Output is not valid JSON: \(out)")

      // Find the entry for --name and inspect its chain.
      let nameArg = try #require(
        dump.arguments.first(where: { $0.name == "--name" }),
        "Missing --name in dump: \(dump.arguments)")
      #expect(
        nameArg.values.count == 1,
        "Expected exactly one value for --name")

      let value = try #require(
        nameArg.firstValue, "no value for --name in \(nameArg)")
      guard case .responseFile = value.source else {
        Issue.record("Source kind should be `.responseFile`: \(value.source)")
        return
      }
      let chain = try #require(
        value.responseFileChain, "no response-file chain: \(value.source)")
      #expect(
        chain.count == 3,
        "Chain must have 3 steps: inner file, outer file, argv. Got: \(chain)")

      #expect(
        chain[0] == .file(path: inner, line: 2),
        "Innermost (index 0) must be inner file at line 2: \(chain)")

      #expect(
        chain[1] == .file(path: outer, line: 1),
        "Second (index 1) must be outer file at line 1: \(chain)")

      #expect(
        chain[2] == .argv(index: 0),
        "Outermost (last) must be the argv sentinel at argv[0]: \(chain)")
    }
  }

  @Test func jsonSubcommandNestedUnderSubcommandKey() async throws {
    let out = try fullMessage(
      for: DumpRoot.self,
      arguments: [
        "--global-flag",
        "deploy",
        "--env", "prod",
        "target1",
        "--experimental-dump-arguments-source-location=json",
      ])

    let dump = try #require(
      decodeDump(out), "Output is not valid JSON: \(out)")
    #expect(dump.command == "tool")

    let sub = try #require(
      dump.subcommand?.value, "Expected a `subcommand` key: \(dump)")
    #expect(sub.command == "deploy")
  }

  @Test func jsonArgvOriginSourceRecordsCommandLineKind() async throws {
    let out = try fullMessage(
      for: DumpSimple.self,
      arguments: [
        "--name", "alpha",
        "--experimental-dump-arguments-source-location=json",
      ])

    let dump = try #require(
      decodeDump(out), "Output is not valid JSON: \(out)")
    let nameArg = try #require(
      dump.arguments.first(where: { $0.name == "--name" }),
      "Missing --name in dump: \(dump)")
    let value = try #require(
      nameArg.firstValue, "no value for --name in \(nameArg)")
    guard case .argumentIndex = value.source else {
      Issue.record(
        "Argv-origin source must be `.argumentIndex`: \(value.source)")
      return
    }
    #expect(
      value.argvIndex != nil,
      "Argv-origin source must carry an argvIndex: \(value.source)")
  }
}

// MARK: - Interaction with the failure path
//
// When parsing fails, the dump must NOT be produced — the source location  error
// path takes precedence. Furthermore, the presence of the dump option
// alone (no @file in input) must not activate the source location gate.

extension SourceLocationDumpEndToEndTests {

  @Test func failurePathTakesPrecedenceOverDump() async throws {
    // `--name` is required; parsing must fail and the dump must not run.
    let msg = try fullMessage(
      for: DumpSimple.self,
      arguments: ["--experimental-dump-arguments-source-location"])
    #expect(
      msg.contains("--name"),
      "Failure path should mention the missing --name: \(msg)")
    #expect(
      !msg.contains("(default)"),
      "Dump-style output must not be produced on failure: \(msg)")
  }

  @Test func failurePathDumpFlagAloneDoesNotActivateREQ1Gate() async throws {
    // The dump option is present, no `@file`.
    // Therefore the error message must NOT include the new location block.
    let msg = try rootErrorMessage(
      for: DumpSimple.self,
      arguments: [
        "--name", "a",
        "--bogus",
        "--experimental-dump-arguments-source-location",
      ])
    #expect(
      msg.contains("Unknown option '--bogus'"),
      "Should still report unknown option: \(msg)")
    #expect(
      !msg.contains("at argv["),
      "Dump option alone must not activate the source location gate: \(msg)")
    #expect(
      !msg.contains("included from"),
      "Dump option alone must not produce a chain: \(msg)")
  }
}

// MARK: - Array-valued arguments
//
// Each element of a repeated `@Option` or an `@Argument` array should
// carry the source location of its own value token, not the aggregate
// origin of the whole array.

extension SourceLocationDumpEndToEndTests {

  @Test func jsonRepeatingOptionEachValueHasDistinctArgvIndex() async throws {
    // `--tag alpha --tag beta --tag gamma` — argv:
    //   [0]=--tag, [1]=alpha, [2]=--tag, [3]=beta, [4]=--tag, [5]=gamma, [6]=--experimental-...
    let out = try fullMessage(
      for: DumpArrayCommand.self,
      arguments: [
        "--tag", "alpha",
        "--tag", "beta",
        "--tag", "gamma",
        "--experimental-dump-arguments-source-location=json",
      ])

    let dump = try #require(
      decodeDump(out), "Output is not valid JSON: \(out)")
    let tagArg = try #require(
      dump.arguments.first(where: { $0.name == "--tag" }),
      "Missing --tag entry in dump: \(dump)")

    let values = tagArg.values
    #expect(
      values.count == 3, "Should render one entry per value: \(values)")
    #expect(values[0].value == "\"alpha\"")
    #expect(values[1].value == "\"beta\"")
    #expect(values[2].value == "\"gamma\"")

    // Each value's source must point to that value's own argv index.
    let expectedArgvByValue: [(String, Int)] = [
      ("\"alpha\"", 1),
      ("\"beta\"", 3),
      ("\"gamma\"", 5),
    ]
    for (index, entry) in values.enumerated() {
      let (expectedRendered, expectedArgv) = expectedArgvByValue[index]
      #expect(
        entry.value == expectedRendered,
        "Value ordering mismatch at [\(index)]: \(values)")
      guard case .argumentIndex = entry.source else {
        Issue.record(
          "Argv-origin source must be `.argumentIndex` at [\(index)]: \(entry.source)"
        )
        continue
      }
      #expect(
        entry.argvIndex == expectedArgv,
        "Value '\(expectedRendered)' should carry argv[\(expectedArgv)]: \(values)"
      )
    }
  }

  @Test func jsonPositionalArrayEachValueHasDistinctArgvIndex() async throws {
    let out = try fullMessage(
      for: DumpArrayCommand.self,
      arguments: [
        "a.txt",
        "b.txt",
        "c.txt",
        "--experimental-dump-arguments-source-location=json",
      ])

    let dump = try #require(
      decodeDump(out), "Output is not valid JSON: \(out)")
    let filesArg = try #require(
      dump.arguments.first(where: {
        $0.name.contains("files") || $0.name == "<files>"
      }),
      "Missing positional entry in dump: \(dump)")

    let values = filesArg.values
    #expect(values.count == 3, "Should render one entry per value")
    let expectedArgvByValue: [(String, Int)] = [
      ("\"a.txt\"", 0),
      ("\"b.txt\"", 1),
      ("\"c.txt\"", 2),
    ]
    for (index, entry) in values.enumerated() {
      let (expectedRendered, expectedArgv) = expectedArgvByValue[index]
      #expect(
        entry.value == expectedRendered,
        "Positional ordering mismatch at [\(index)]: \(values)")

      guard case .argumentIndex = entry.source else {
        Issue.record(
          "Positional source must be `.argumentIndex` at [\(index)]: \(entry.source)"
        )
        continue
      }
      #expect(
        entry.argvIndex == expectedArgv,
        "Positional '\(expectedRendered)' should carry argv[\(expectedArgv)]")
    }
  }
}

// MARK: - Kitchen-sink command / invocation-syntax coverage
//
// Exercises a command that mixes scalar options, flags (long + short,
// packed shorts), a repeating named option, a required positional, and a
// positional array — invoked via the various CLI syntaxes ArgumentParser
// accepts (`--opt value`, `--opt=value`, `-n value`, packed `-vf`, mixed
// argv + response file).

extension SourceLocationDumpEndToEndTests {

  /// Extracts the decoded dump for a set of kitchen-sink arguments, or
  /// throws if the output cannot be decoded as JSON.
  fileprivate func kitchenDump(
    _ arguments: [String]
  ) throws -> SourceLocationDumpGenerator.CommandNode {
    let out = try fullMessage(
      for: DumpKitchenSink.self,
      arguments: arguments
        + ["--experimental-dump-arguments-source-location=json"])
    return try #require(decodeDump(out), "Output is not valid JSON: \(out)")
  }

  @Test func kitchenSinkAllSyntaxesRenderCommandLineOrigins() async throws {
    // Invoke with: --name space, --count=42, -v, --force, --tag one,
    // --tag=two, target-value, extra1, extra2
    // Argv:
    //   [0]=--name [1]=Alice [2]=--count=42 [3]=-v [4]=--force
    //   [5]=--tag  [6]=one   [7]=--tag=two  [8]=target-value
    //   [9]=extra1 [10]=extra2 [11]=--experimental-dump-...
    let dump = try kitchenDump([
      "--name", "Alice",
      "--count=42",
      "-v",
      "--force",
      "--tag", "one",
      "--tag=two",
      "target-value",
      "extra1", "extra2",
    ])

    // --name Alice (space-separated) → value at argv[1]
    let nameValue = try #require(
      dump.firstArgument(matching: ["name"])?.firstValue)
    guard case .argumentIndex = nameValue.source else {
      Issue.record(
        "--name source must be `.argumentIndex`:  \(String(describing: nameValue.source))"
      )
      return
    }
    #expect(nameValue.value == "\"Alice\"")
    #expect(
      nameValue.argvIndex == 1,
      "space-separated `--name Alice` value should be at argv[1]")

    // --count=42 (attached with =) → value is at argv[2] (the same token)
    let countValue = try #require(
      dump.firstArgument(matching: ["count"])?.firstValue)
    guard case .argumentIndex = countValue.source else {
      Issue.record(
        "--count source must be `.argumentIndex`: \(String(describing: countValue.source))"
      )
      return
    }
    #expect(countValue.value == "42")
    #expect(
      countValue.argvIndex == 2,
      "attached `--count=42` should record argv[2]")

    // -v (short flag) → argv[3]
    let verboseValue =
      try #require(dump.firstArgument(matching: ["verbose"])?.firstValue)
    guard case .argumentIndex = verboseValue.source else {
      Issue.record(
        "--verbose source must be `.argumentIndex`: \(String(describing: verboseValue.source))"
      )
      return
    }
    #expect(verboseValue.value == "true")
    #expect(verboseValue.argvIndex == 3, "short `-v` at argv[3]")

    // --force (long flag) → argv[4]
    let forceValue =
      try #require(dump.firstArgument(matching: ["force"])?.firstValue)
    guard case .argumentIndex = forceValue.source else {
      Issue.record(
        "--force source must be `.argumentIndex`: \(String(describing: forceValue.source))"
      )
      return
    }
    #expect(forceValue.value == "true")
    #expect(forceValue.argvIndex == 4, "long `--force` at argv[4]")

    // --tag one --tag=two → two entries, argv indices [6] and [7]
    let tagArg = try #require(dump.firstArgument(matching: ["tag"]))
    let tagValues = tagArg.values
    #expect(
      tagValues.count == 2, "tags should have 2 values: \(tagValues)")
    for (i, tv) in tagValues.enumerated() {
      guard case .argumentIndex = tv.source else {
        Issue.record(
          "tag[\(i)] source must be `.argumentIndex`: \(tv.source)")
        return
      }
    }
    let firstTag = try #require(tagValues.first)
    let lastTag = try #require(tagValues.last)
    #expect(firstTag.value == "\"one\"")
    #expect(firstTag.argvIndex == 6)
    #expect(lastTag.value == "\"two\"")
    #expect(
      lastTag.argvIndex == 7,
      "attached `--tag=two` value token is at argv[7]")

    // target-value positional → argv[8]
    let targetValue =
      try #require(dump.firstArgument(matching: ["target"])?.firstValue)
    guard case .argumentIndex = targetValue.source else {
      Issue.record(
        "target source must be `.argumentIndex`: \(String(describing: targetValue.source))"
      )
      return
    }
    #expect(targetValue.value == "\"target-value\"")
    #expect(targetValue.argvIndex == 8)

    // extras positional array → argv[9], argv[10]
    let extrasArg = try #require(dump.firstArgument(matching: ["extras"]))
    let extrasValues = extrasArg.values
    #expect(extrasValues.count == 2)
    for (i, ev) in extrasValues.enumerated() {
      guard case .argumentIndex = ev.source else {
        Issue.record(
          "extras[\(i)] source must be `.argumentIndex`: \(ev.source)")
        return
      }
    }
    let firstExtra = try #require(extrasValues.first)
    let lastExtra = try #require(extrasValues.last)
    #expect(firstExtra.argvIndex == 9)
    #expect(lastExtra.argvIndex == 10)
  }

  @Test func kitchenSinkPackedShortFlagsShareArgvIndex() async throws {
    // `-vf target` should treat `-v` and `-f` as coming from argv[0],
    // and `target` as argv[1].
    let dump = try kitchenDump([
      "-vf",
      "target",
      "--name", "Bob",
    ])

    let verbose = try #require(
      dump.firstArgument(matching: ["verbose"])?.firstValue)
    let force = try #require(
      dump.firstArgument(matching: ["force"])?.firstValue)
    guard case .argumentIndex = verbose.source else {
      Issue.record(
        "-v source must be `.argumentIndex`: \(verbose.source)")
      return
    }
    guard case .argumentIndex = force.source else {
      Issue.record(
        "-f source must be `.argumentIndex`: \(force.source)")
      return
    }
    #expect(verbose.value == "true")
    #expect(force.value == "true")
    #expect(
      verbose.argvIndex == 0,
      "packed `-v` should carry argv[0]: \(verbose)")
    #expect(
      force.argvIndex == 0,
      "packed `-f` should carry argv[0]: \(force)")

    let target = try #require(
      dump.firstArgument(matching: ["target"])?.firstValue)
    guard case .argumentIndex = target.source else {
      Issue.record(
        "target source must be `.argumentIndex`: \(target.source)")
      return
    }
    #expect(target.argvIndex == 1)
  }

  @Test func kitchenSinkShortAndLongNameFormsAgreeOnArgvIndex() async throws {
    // Using the short form of --name (`-n Charlie`) should render the
    // value at the argv index of the value token, matching the long-form
    // behavior.
    let dump = try kitchenDump([
      "-n", "Charlie",
      "the-target",
    ])

    let nameValue = try #require(
      dump.firstArgument(matching: ["name"])?.firstValue)
    guard case .argumentIndex = nameValue.source else {
      Issue.record(
        "-n source must be `.argumentIndex`: \(nameValue.source)")
      return
    }
    #expect(nameValue.value == "\"Charlie\"")
    #expect(
      nameValue.argvIndex == 1,
      "short form `-n Charlie` should still record the value's argv index")
  }

  @Test func kitchenSinkDefaultsRenderWithoutSource() async throws {
    // Only `--name` and the positional provided. `count`, `verbose`,
    // `force`, `tags`, `extras` should render as (default) / kind=default.
    let dump = try kitchenDump([
      "--name", "Dana",
      "only-target",
    ])

    // Scalars default → .defaultValue source.
    for name in ["count", "verbose", "force"] {
      let value = try #require(
        dump.firstArgument(matching: [name])?.firstValue,
        "missing entry for \(name)")
      guard case .defaultValue = value.source else {
        Issue.record(
          "\(name) should have `.defaultValue` source: \(value.source)")
        return
      }
    }

    // Array `tags` default → single default entry.
    let tagsArg = try #require(dump.firstArgument(matching: ["tag"]))
    #expect(tagsArg.values.count == 1, "empty tags renders as one entry")
    let tagValue = try #require(tagsArg.values.first)
    guard case .defaultValue = tagValue.source else {
      Issue.record(
        "tags default entry must be `.defaultValue`: \(tagValue.source)")
      return
    }

    // Array `extras` default → single default entry.
    let extrasArg = try #require(dump.firstArgument(matching: ["extras"]))
    #expect(extrasArg.values.count == 1)
    let extrasValue = try #require(extrasArg.values.first)
    guard case .defaultValue = extrasValue.source else {
      Issue.record(
        "extras default entry must be `.defaultValue`: \(extrasValue.source)")
      return
    }
  }

  @Test func kitchenSinkArgvArgAfterResponseFileShowsCorrectArgvIndex()
    async throws
  {
    // Response file supplies `--name FromFile`. Argv-only args after it
    // should get argv indices that reflect their position in the
    // pre-expansion argv (0=@file, 1=--verbose, 2=positional).
    try await withTemporaryFile(
      "kitchen.txt",
      content: """
        --name
        FromFile
        """
    ) { responseFile in
      let dump = try kitchenDump([
        "@\(responseFile)",
        "--verbose",
        "argv-target",
      ])

      // Response-file-origin `--name FromFile` — chain source, not commandLine.
      let nameValue = try #require(
        dump.firstArgument(matching: ["name"])?.firstValue)
      guard case .responseFile = nameValue.source else {
        Issue.record(
          "name-from-@file source must be `.responseFile`: \(String(describing: nameValue.source))"
        )
        return
      }
      #expect(nameValue.value == "\"FromFile\"")
      let chain = try #require(nameValue.responseFileChain)
      #expect(
        chain.first == .file(path: responseFile, line: 2),
        "chain[0] should be the response file: \(chain)")
      #expect(
        chain.last == .argv(index: 0),
        "@file itself lives at argv[0]: \(chain)")

      // Argv-origin `--verbose` at argv[1]
      let verbose = try #require(
        dump.firstArgument(matching: ["verbose"])?.firstValue)
      guard case .argumentIndex = verbose.source else {
        Issue.record(
          "--verbose source must be `.argumentIndex`: \(verbose.source)")
        return
      }
      #expect(verbose.value == "true")
      #expect(verbose.argvIndex == 1)

      // Argv-origin positional `argv-target` at argv[2]
      let target = try #require(
        dump.firstArgument(matching: ["target"])?.firstValue)
      guard case .argumentIndex = target.source else {
        Issue.record(
          "target source must be `.argumentIndex`: \(target.source)")
        return
      }
      #expect(target.value == "\"argv-target\"")
      #expect(target.argvIndex == 2)
    }
  }

  @Test func kitchenSinkMixedShorthandAndAttachedInSameInvocation() async throws
  {
    // Mix long-with-equals, short-with-space, and packed shorts.
    // Argv: [0]=--count=7 [1]=-n [2]=Eve [3]=-vf [4]=tgt [5]=e1
    //       [6]=--experimental-...
    let dump = try kitchenDump([
      "--count=7",
      "-n", "Eve",
      "-vf",
      "tgt",
      "e1",
    ])

    // Bind each value and verify each source kind via `guard case`.
    let countValue = try #require(
      dump.firstArgument(matching: ["count"])?.firstValue)
    let nameValue = try #require(
      dump.firstArgument(matching: ["name"])?.firstValue)
    let verboseValue = try #require(
      dump.firstArgument(matching: ["verbose"])?.firstValue)
    let forceValue = try #require(
      dump.firstArgument(matching: ["force"])?.firstValue)
    let targetValue = try #require(
      dump.firstArgument(matching: ["target"])?.firstValue)

    for (label, v) in [
      ("--count", countValue),
      ("--name", nameValue),
      ("--verbose", verboseValue),
      ("--force", forceValue),
      ("<target>", targetValue),
    ] {
      guard case .argumentIndex = v.source else {
        Issue.record(
          "\(label) source must be `.argumentIndex`: \(v.source)")
        return
      }
    }

    #expect(countValue.argvIndex == 0)
    #expect(
      nameValue.argvIndex == 2, "short `-n Eve` — value token at argv[2]")
    #expect(verboseValue.argvIndex == 3)
    #expect(forceValue.argvIndex == 3)
    #expect(targetValue.argvIndex == 4)
    let extras = try #require(
      dump.firstArgument(matching: ["extras"])?.values)
    let extrasFirst = try #require(extras.first)
    guard case .argumentIndex = extrasFirst.source else {
      Issue.record(
        "extras[0] source must be `.argumentIndex`: \(extrasFirst.source)")
      return
    }
    #expect(extrasFirst.argvIndex == 5)
  }

  // MARK: - defaultAsFlag coverage
  //
  // The `--log-level` option can be invoked three ways. Each has a
  // distinct expected source rendering:
  //   • omitted           → kind=default, no argv index
  //   • bare `--log-level` → the value is the flag's default ("info"),
  //     but the source is still argv (the flag token itself)
  //   • `--log-level=warn` → argv-origin, value from the same token

  @Test func kitchenSinkDefaultAsFlagOmittedRendersAsDefault() async throws {
    let dump = try kitchenDump([
      "--name", "Frank",
      "tgt",
    ])

    let logValue = try #require(
      dump.firstArgument(matching: ["log-level"])?.firstValue)
    guard case .defaultValue = logValue.source else {
      Issue.record(
        "omitted defaultAsFlag option should render as `.defaultValue`: \(String(describing: logValue.source))"
      )
      return
    }
  }

  @Test func kitchenSinkDefaultAsFlagBareInvocationSourcesToFlagToken()
    async throws
  {
    // With `.next` parsing, the bare-flag path fires when the token
    // immediately after `--log-level` starts with `--` (i.e., is
    // clearly not a value). Place another option right after it.
    // Argv: [0]=--name [1]=Frank [2]=--log-level [3]=--verbose [4]=tgt
    //       [5]=--experimental-...
    let dump = try kitchenDump([
      "--name", "Frank",
      "--log-level",
      "--verbose",
      "tgt",
    ])

    let logValue = try #require(
      dump.firstArgument(matching: ["log-level"])?.firstValue)
    guard case .argumentIndex = logValue.source else {
      Issue.record(
        "bare `--log-level` should be sourced to `.argumentIndex`, not `.defaultValue`: \(logValue.source)"
      )
      return
    }
    #expect(
      logValue.value == "\"info\"",
      "bare `--log-level` should render the flag default value: \(logValue)")
    #expect(
      logValue.argvIndex == 2,
      "bare `--log-level` should be sourced to argv[2]: \(logValue)")
  }

  @Test func kitchenSinkDefaultAsFlagAttachedValueSourcesToSameToken()
    async throws
  {
    // Argv: [0]=--name [1]=Frank [2]=--log-level=warn [3]=tgt
    let dump = try kitchenDump([
      "--name", "Frank",
      "--log-level=warn",
      "tgt",
    ])

    let logValue = try #require(
      dump.firstArgument(matching: ["log-level"])?.firstValue)
    guard case .argumentIndex = logValue.source else {
      Issue.record(
        "attached `--log-level=warn` source must be `.argumentIndex`: \(String(describing: logValue.source))"
      )
      return
    }
    #expect(logValue.value == "\"warn\"")
    #expect(
      logValue.argvIndex == 2,
      "attached `--log-level=warn` value is at argv[2]: \(logValue)")
  }
}
