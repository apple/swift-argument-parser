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

// MARK: - Performance

@Suite(
  .tags(
    .performance,
  ),
)
struct PerformanceTests {
  private struct RepeatedOptionCommand: ParsableCommand {
    static let configuration = CommandConfiguration(responseFilePrefix: "@")

    @Option var tag: [String] = []
  }

  private func parseDuration<Command: ParsableCommand>(
    _: Command.Type,
    arguments: [String],
  ) async throws -> Duration {
    let clock = ContinuousClock()
    let start = clock.now
    _ = try Command.parse(arguments)
    return clock.now - start
  }

  @Test() func repeatedOptionParsingScalesLinearly()
    async throws
  {
    func args(count: Int) -> [String] {
      (0..<count).map { "--tag=value\($0)" }
    }

    let small = try await parseDuration(
      RepeatedOptionCommand.self,
      arguments: args(count: 2_000),
    )
    let large = try await parseDuration(
      RepeatedOptionCommand.self,
      arguments: args(count: 20_000),
    )

    #expect(
      large < small * 30,
      """
      Parsing time scaled super-linearly with input size: \(small) for \
      2,000 repeated options vs \(large) for 20,000. A 10x increase in \
      input should cost roughly 10x the time, not ~100x, which would \
      indicate an O(n^2) hot path.
      """
    )
  }

  private struct PositionalCommand: ParsableCommand {
    static let configuration = CommandConfiguration(responseFilePrefix: "@")

    @Argument var tag: [String] = []
  }

  @Test() func positionalArgumentParsingScalesLinearly()
    async throws
  {
    func args(count: Int) -> [String] {
      (0..<count).map { "file\($0).txt" }
    }

    let small = try await parseDuration(
      PositionalCommand.self,
      arguments: args(count: 2_000),
    )
    let large = try await parseDuration(
      PositionalCommand.self,
      arguments: args(count: 20_000),
    )

    #expect(
      large < small * 30,
      """
      Parsing time scaled super-linearly with input size: \(small) for \
      2,000 positional arguments vs \(large) for 20,000. A 10x increase \
      in input should cost roughly 10x the time, not ~100x, which would \
      indicate an O(n^2) hot path.
      """
    )
  }
}
