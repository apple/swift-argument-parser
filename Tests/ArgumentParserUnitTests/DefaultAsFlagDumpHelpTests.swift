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

final class DefaultAsFlagDumpHelpTests: XCTestCase {
  func testDefaultAsFlagDumpHelp() throws {
    try assertDumpHelp(type: DefaultAsFlagCommand.self)
  }

  func testDefaultAsFlagWithTransformDumpHelp() throws {
    try assertDumpHelp(type: DefaultAsFlagWithTransformCommand.self)
  }
}

extension DefaultAsFlagDumpHelpTests {
  struct DefaultAsFlagCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
      abstract: "A command with defaultAsFlag options for testing dump help."
    )

    @Option(name: .customLong("binary-path"), defaultAsFlag: "/usr/bin")
    var binPath: String? = nil

    @Option(name: .long, defaultAsFlag: 42)
    var count: Int?

    @Option(name: .long, defaultAsFlag: true)
    var verbose: Bool?

    @Argument
    var input: String
  }

  struct DefaultAsFlagWithTransformCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
      abstract:
        "A command with defaultAsFlag options using transforms for testing dump help."
    )

    @Option(
      name: .customLong("output-dir"),
      defaultAsFlag: "/default/output",
      transform: { $0.uppercased() }
    )
    var outputDir: String? = nil

    @Option(
      name: .long,
      defaultAsFlag: "INFO",
      transform: { $0.lowercased() }
    )
    var level: String?

    @Flag
    var debug: Bool = false
  }
}
