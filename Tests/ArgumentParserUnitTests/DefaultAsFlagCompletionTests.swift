//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2025-2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import ArgumentParserTestHelpers
import Testing

@testable import ArgumentParser

@Suite struct DefaultAsFlagCompletionTests {
  @Test func defaultAsFlagCompletion_Bash() throws {
    let script = try CompletionsGenerator(
      command: DefaultAsFlagCommand.self, shell: .bash
    )
    .generateCompletionScript()
    try expectSnapshot(actual: script, extension: "bash")
  }

  @Test func defaultAsFlagCompletion_Zsh() throws {
    let script = try CompletionsGenerator(
      command: DefaultAsFlagCommand.self, shell: .zsh
    )
    .generateCompletionScript()
    try expectSnapshot(actual: script, extension: "zsh")
  }

  @Test func defaultAsFlagCompletion_Fish() throws {
    let script = try CompletionsGenerator(
      command: DefaultAsFlagCommand.self, shell: .fish
    )
    .generateCompletionScript()
    try expectSnapshot(actual: script, extension: "fish")
  }
}

extension DefaultAsFlagCompletionTests {
  struct DefaultAsFlagCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "defaultasflag-test",
      abstract:
        "A command with defaultAsFlag options for testing completion scripts."
    )

    @Option(defaultAsFlag: "/usr/bin", completion: .directory)
    var binPath: String? = nil

    @Option(defaultAsFlag: 42)
    var count: Int?

    @Option(defaultAsFlag: true)
    var verbose: Bool?

    @Option(
      defaultAsFlag: "INFO",
      completion: .list(["DEBUG", "INFO", "WARN", "ERROR"]),
      transform: { $0.uppercased() }
    )
    var logLevel: String?

    @Flag
    var help: Bool = false

    @Argument(completion: .file())
    var input: String
  }
}
