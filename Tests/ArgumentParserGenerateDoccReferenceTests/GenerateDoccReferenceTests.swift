//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import ArgumentParserTestHelpers
import XCTest

final class GenerateDoccReferenceTests: XCTestCase {
  #if os(macOS)
  func testCountLinesDoccReference() throws {
    guard #available(macOS 12, *) else { return }
    try assertGenerateDoccReference(command: "count-lines")
  }
  #endif

  func testColorDoccReference() throws {
    try assertGenerateDoccReference(command: "color")
  }

  func testMathDoccReference() throws {
    try assertGenerateDoccReference(command: "math")
  }

  func testRepeatDoccReference() throws {
    try assertGenerateDoccReference(command: "repeat")
  }

  func testRollDoccReference() throws {
    try assertGenerateDoccReference(command: "roll")
  }
}
