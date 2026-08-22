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

#if os(macOS)

import ArgumentParserTestHelpers
import Foundation
import Testing

@testable import ArgumentParser

@Suite(
  .serialized
) struct CountLinesExampleTests {
  init() {
    Platform.Environment[.columns] = nil
  }

  @Test func countLines() throws {
    guard #available(macOS 12, *) else { return }
    let testFile = try #require(
      Bundle.module.url(forResource: "CountLinesTest", withExtension: "txt"))
    try requireExecuteCommand(
      command: "count-lines \(testFile.path)", expected: "20\n")
    try requireExecuteCommand(
      command: "count-lines \(testFile.path) --prefix al", expected: "4\n")
  }

  @Test func countLinesHelp() throws {
    guard #available(macOS 12, *) else { return }
    let helpText = """
      USAGE: count-lines [<input-file>] [--prefix <prefix>] [--verbose]

      ARGUMENTS:
        <input-file>            A file to count lines in. If omitted, counts the
                                lines of stdin.

      OPTIONS:
        --prefix <prefix>       Only count lines with this prefix.
        --verbose               Include extra information in the output.
        -h, --help              Show help information.


      """
    try requireExecuteCommand(command: "count-lines -h", expected: helpText)
  }
}

#endif
