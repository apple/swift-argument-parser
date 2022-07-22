//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import ArgumentParser
import ArgumentParserTestHelpers
import XCTest

final class InvalidValueInteractiveTests: XCTestCase {}

private struct IntValue: ParsableCommand {
  @Argument var integer: Int
}

private struct IntArray: ParsableCommand {
  @Argument var values: [Int]
}

extension InvalidValueInteractiveTests {
  func testParsing_HandleUpdateError() throws {
    AssertParseCommand(IntValue.self, IntValue.self, [], lines: ["", "a", "0.1", "1"]) { value in
      XCTAssertEqual(value.integer, 1)
    }

    AssertParseCommand(IntArray.self, IntArray.self, [], lines: ["1 2 a", "0.1", "3"]) { value in
      XCTAssertEqual(value.values, [1, 2, 3])
    }
    
    AssertParseCommand(IntArray.self, IntArray.self, [], lines: ["a 0.1", "1", "2"]) { value in
      XCTAssertEqual(value.values, [1, 2])
    }
  }
}
