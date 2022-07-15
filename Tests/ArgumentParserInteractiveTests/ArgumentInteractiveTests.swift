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

final class ArgumentInteractiveTests: XCTestCase {}

private struct StringValue: ParsableCommand {
  @Argument var string: String
}

private struct IntValue: ParsableCommand {
  @Argument var integer: Int
}

private struct DoubleValue: ParsableCommand {
  @Argument var decimal: Double
}

extension ArgumentInteractiveTests {
  func testParsing_StringValue() throws {
    AssertParseCommand(StringValue.self, StringValue.self, [], lines: ["abc"]) { value in
      XCTAssertEqual(value.string, "abc")
    }
  }

  func testParsing_IntValue() throws {
    AssertParseCommand(IntValue.self, IntValue.self, [], lines: ["\(Int.max)"]) { value in
      XCTAssertEqual(value.integer, .max)
    }
  }

  func testParsing_DoubleValue() throws {
    AssertParseCommand(DoubleValue.self, DoubleValue.self, [], lines: ["\(Double.pi)"]) { value in
      XCTAssertEqual(value.decimal, .pi)
    }
  }
}

// MARK: -

private struct StringArray: ParsableCommand {
  @Argument var values: [String]
}

private struct IntArray: ParsableCommand {
  @Argument var values: [Int]
}

private struct DoubleArray: ParsableCommand {
  @Argument var values: [Double]
}

extension ArgumentInteractiveTests {
  func testParsing_StringArray() throws {
    AssertParseCommand(StringArray.self, StringArray.self, [], lines: ["a b c"]) { value in
      XCTAssertEqual(value.values, ["a", "b", "c"])
    }
  }

  func testParsing_IntArray() throws {
    AssertParseCommand(IntArray.self, IntArray.self, [], lines: ["\(Int.min) \(0) \(Int.max)"]) { array in
      XCTAssertEqual(array.values, [.min, 0, .max])
    }
  }

  func testParsing_DoubleArray() throws {
    AssertParseCommand(DoubleArray.self, DoubleArray.self, [], lines: ["\(Double.pi) \(Double.ulpOfOne) \(Double.infinity)"]) { array in
      XCTAssertEqual(array.values, [.pi, .ulpOfOne, .infinity])
    }
  }
}
