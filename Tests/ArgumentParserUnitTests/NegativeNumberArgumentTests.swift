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

import XCTest
import ArgumentParser

final class NegativeNumberArgumentTests: XCTestCase {
  struct Absolute: ParsableCommand {
    @Argument var number: Int
  }

  func testParsesNegativeIntegerAsArgument() throws {
    let cmd = try Absolute.parse(["-5"]) // should be treated as value, not option
    XCTAssertEqual(cmd.number, -5)
  }

  struct FloatArg: ParsableCommand {
    @Argument var value: Double
  }

  func testParsesNegativeDoubleAsArgument() throws {
    let cmd = try FloatArg.parse(["-3.14"]) // negative decimal
    XCTAssertEqual(cmd.value, -3.14, accuracy: 1e-9)
  }
}

