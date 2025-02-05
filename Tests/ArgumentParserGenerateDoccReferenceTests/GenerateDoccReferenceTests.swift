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

final class GenerateDoccReferenceTests: XCTestCase {
  let snapshotsDirectory = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .appendingPathComponent("Snapshots")

  func url(_ test: StaticString = #function) -> URL {
    return self.snapshotsDirectory.appendingPathComponent("\(test).md")
  }

#if os(macOS)
  func testCountLinesDoccReference() throws {
    guard #available(macOS 12, *) else { return }
    try AssertGenerateDoccReference(command: "count-lines", expected: self.url())
  }
#endif

  func testColorDoccReference() throws {
    try AssertGenerateDoccReference(command: "color", expected: self.url())
  }

  func testMathDoccReference() throws {
    try AssertGenerateDoccReference(command: "math", expected: self.url())
  }

  func testRepeatDoccReference() throws {
    try AssertGenerateDoccReference(command: "repeat", expected: self.url())
  }

  func testRollDoccReference() throws {
    try AssertGenerateDoccReference(command: "roll", expected: self.url())
  }
}
