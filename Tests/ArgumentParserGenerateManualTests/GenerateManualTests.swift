//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import XCTest
import ArgumentParserTestHelpers

final class GenerateManualTests: XCTestCase {
  let snapshotsDirectory = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .appendingPathComponent("Snapshots")

  func url(_ test: StaticString = #function) -> URL {
    return self.snapshotsDirectory.appendingPathComponent("\(test).mdoc")
  }

#if os(macOS)
  func testCountLinesSinglePageManual() throws {
    guard #available(macOS 12, *) else { return }
    try AssertGenerateManual(multiPage: false, command: "count-lines", expected: self.url())
  }

  func testCountLinesMultiPageManual() throws {
    guard #available(macOS 12, *) else { return }
    try AssertGenerateManual(multiPage: true, command: "count-lines", expected: self.url())
  }
#endif

  func testColorSinglePageManual() throws {
    try AssertGenerateManual(multiPage: false, command: "color", expected: self.url())
  }

  func testColorMultiPageManual() throws {
    try AssertGenerateManual(multiPage: true, command: "color", expected: self.url())
  }

  func testMathSinglePageManual() throws {
    try AssertGenerateManual(multiPage: false, command: "math", expected: self.url())
  }

  func testMathMultiPageManual() throws {
    try AssertGenerateManual(multiPage: true, command: "math", expected: self.url())
  }

  func testRepeatSinglePageManual() throws {
    try AssertGenerateManual(multiPage: false, command: "repeat", expected: self.url())
  }

  func testRepeatMultiPageManual() throws {
    try AssertGenerateManual(multiPage: true, command: "repeat", expected: self.url())
  }

  func testRollSinglePageManual() throws {
    try AssertGenerateManual(multiPage: false, command: "roll", expected: self.url())
  }

  func testRollMultiPageManual() throws {
    try AssertGenerateManual(multiPage: true, command: "roll", expected: self.url())
  }
}
