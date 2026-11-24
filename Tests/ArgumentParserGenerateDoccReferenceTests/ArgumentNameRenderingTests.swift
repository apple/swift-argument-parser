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

/// Verifies how argument names are rendered, using a fixture "tool" that
/// emits hand-written `--experimental-dump-help` JSON so every name kind can
/// be exercised.
@Suite struct ArgumentNameRenderingTests {
  #if !os(Windows)
  private struct Name {
    var kind: String
    var name: String
    var json: String { #"{"kind":"\#(kind)","name":"\#(name)"}"# }
  }

  private static func long(_ n: String) -> Name { Name(kind: "long", name: n) }
  private static func short(_ n: String) -> Name {
    Name(kind: "short", name: n)
  }
  private static func single(_ n: String) -> Name {
    Name(kind: "longWithSingleDash", name: n)
  }

  private static func argument(
    kind: String, names: [Name], preferred: Name? = nil,
    valueName: String? = nil
  ) -> String {
    let namesJSON = names.map(\.json).joined(separator: ",")
    let pref =
      (preferred ?? names.first).map { #","preferredName":\#($0.json)"# } ?? ""
    let value = valueName.map { #","valueName":"\#($0)""# } ?? ""
    return
      #"{"kind":"\#(kind)","shouldDisplay":true,"isOptional":true,"isRepeating":false,"parsingStrategy":"default","names":[\#(namesJSON)]\#(pref)\#(value)}"#
  }

  /// Writes an executable script that prints the given arguments as tool info.
  private static func withFixtureTool(
    arguments: [String],
    _ body: (String) throws -> Void
  ) throws {
    let json =
      #"{"serializationVersion":0,"command":{"commandName":"fixture","arguments":[\#(arguments.joined(separator: ","))]}}"#
    let dir = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(
      at: dir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: dir) }
    let tool = dir.appendingPathComponent("fixture")
    try "#!/bin/sh\ncat <<'EOF'\n\(json)\nEOF\n".write(
      to: tool, atomically: true, encoding: .utf8)
    try FileManager.default.setAttributes(
      [.posixPermissions: 0o755], ofItemAtPath: tool.path)
    try body(tool.path)
  }

  private static func generate(
    _ arguments: [String], docc: Bool
  ) throws -> String {
    var output = ""
    try withFixtureTool(arguments: arguments) { tool in
      output = try requireExecuteCommand(
        command: [
          "generate-docc-reference", tool, "--output-directory", "-",
          "--style", docc ? "docc" : "github",
        ])
    }
    return output
  }

  private func check(
    _ arguments: [String], usage: String, identity: String,
    sourceLocation: SourceLocation = #_sourceLocation
  ) throws {
    for docc in [false, true] {
      let output = try Self.generate(arguments, docc: docc)
      #expect(
        output.contains("```\nfixture \(usage)\n```"),
        "usage missing '\(usage)' in:\n\(output)",
        sourceLocation: sourceLocation)
      let heading = docc ? "- term **\(identity)**:" : "**\(identity):**"
      #expect(
        output.contains(heading),
        "identity missing '\(heading)' in:\n\(output)",
        sourceLocation: sourceLocation)
      #expect(!output.contains("[--]"), sourceLocation: sourceLocation)
    }
  }

  @Test func shortOnlyFlag() throws {
    try check(
      [Self.argument(kind: "flag", names: [Self.short("v")])],
      usage: "[-v]", identity: "-v")
  }

  @Test func shortOnlyOption() throws {
    try check(
      [
        Self.argument(
          kind: "option", names: [Self.short("n")], valueName: "count")
      ],
      usage: "[-n=<count>]", identity: "-n=\\<count\\>")
  }

  @Test func singleDashLongFlag() throws {
    try check(
      [Self.argument(kind: "flag", names: [Self.single("verbose")])],
      usage: "[-verbose]", identity: "-verbose")
  }

  @Test func singleDashLongOption() throws {
    try check(
      [
        Self.argument(
          kind: "option", names: [Self.single("level")], valueName: "n")
      ],
      usage: "[-level=<n>]", identity: "-level=\\<n\\>")
  }

  @Test func shortAndSingleDashUsesPreferredName() throws {
    try check(
      [
        Self.argument(
          kind: "option", names: [Self.short("l"), Self.single("level")],
          preferred: Self.single("level"), valueName: "n")
      ],
      usage: "[-level=<n>]", identity: "-level=\\<n\\>")
  }

  @Test func longNamesUnchanged() throws {
    try check(
      [
        Self.argument(
          kind: "option", names: [Self.long("count"), Self.short("c")],
          valueName: "n"),
        Self.argument(kind: "flag", names: [Self.long("verbose")]),
      ],
      usage: "[--count=<n>] [--verbose]", identity: "--count=\\<n\\>")
  }

  @Test func longAlternationUnchanged() throws {
    try check(
      [
        Self.argument(
          kind: "flag",
          names: [Self.long("verbose"), Self.short("v"), Self.long("loud")])
      ],
      usage: "[--verbose|loud]", identity: "--verbose|loud")
  }

  @Test func mixedLongAndShortOnlyFlagsTogether() throws {
    try check(
      [
        Self.argument(kind: "flag", names: [Self.long("force")]),
        Self.argument(kind: "flag", names: [Self.short("v")]),
        Self.argument(kind: "flag", names: [Self.single("x")]),
      ],
      usage: "[--force] [-v] [-x]", identity: "-v")
  }
  #endif
}
