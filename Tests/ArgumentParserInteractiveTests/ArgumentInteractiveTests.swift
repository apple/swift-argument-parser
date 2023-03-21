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

private struct ExpressibleValue: ParsableCommand {
  enum Mode: String, ExpressibleByArgument {
    case foo, bar, baz
  }

  @Argument var mode: Mode
}

private struct TransformableValue: ParsableCommand {
  enum Format: Equatable {
    case text
    case other(String)

    init(_ string: String) throws {
      if string == "text" {
        self = .text
      } else {
        self = .other(string)
      }
    }
  }

  @Argument(transform: Format.init) var format: Format
}

extension ArgumentInteractiveTests {
  func testParsing_ExpressibleValue() throws {
    AssertParseCommand(ExpressibleValue.self, ExpressibleValue.self, [], lines: ["foo"]) { value in
      XCTAssertEqual(value.mode, .foo)
    }
  }

  func testParsing_TransformableValue() throws {
    AssertParseCommand(TransformableValue.self, TransformableValue.self, [], lines: ["text"]) { value in
      XCTAssertEqual(value.format, .text)
    }
    AssertParseCommand(TransformableValue.self, TransformableValue.self, [], lines: ["keynote"]) { value in
      XCTAssertEqual(value.format, .other("keynote"))
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
    AssertParseCommand(StringArray.self, StringArray.self, [], lines: ["a 'b c'"]) { value in
      XCTAssertEqual(value.values, ["a", "b c"])
    }
    AssertParseCommand(StringArray.self, StringArray.self, [], lines: ["a b 'c", "d e'"]) { value in
      XCTAssertEqual(value.values, ["a", "b", "c\nd e"])
    }
  }

  func testParsing_IntArray() throws {
    AssertParseCommand(IntArray.self, IntArray.self, [], lines: ["\(Int.min) \(0) \(Int.max)"]) { array in
      XCTAssertEqual(array.values, [.min, 0, .max])
    }
    AssertParseCommand(IntArray.self, IntArray.self, [], lines: ["10 11 1\\", "2"]) { array in
      XCTAssertEqual(array.values, [10, 11, 12])
    }
  }

  func testParsing_DoubleArray() throws {
    AssertParseCommand(DoubleArray.self, DoubleArray.self, [], lines: ["\(Double.pi) \(Double.ulpOfOne) \(Double.infinity)"]) { array in
      XCTAssertEqual(array.values, [.pi, .ulpOfOne, .infinity])
    }
  }
}

// MARK: -

private struct PositionalArray1: ParsableCommand {
  @Argument var values: [Int]
  @Option var count: Int
  @Flag var verbose = false
}

private struct PositionalArray2: ParsableCommand {
  @Option var count: Int
  @Argument var values: [Int]
  @Flag var verbose = false
}

private struct PositionalArray3: ParsableCommand {
  @Option var count: Int
  @Flag var verbose = false
  @Argument var values: [Int]
}

extension ArgumentInteractiveTests {
  func testParsing_PositionalArray() throws {
    AssertParseCommand(PositionalArray1.self, PositionalArray1.self, ["--count", "3", "--verbose"], lines: ["1 2"]) { value in
      XCTAssertEqual(value.count, 3)
      XCTAssertEqual(value.verbose, true)
      XCTAssertEqual(value.values, [1, 2])
    }

    AssertParseCommand(PositionalArray2.self, PositionalArray2.self, ["--count", "3", "--verbose"], lines: ["1 2"]) { value in
      XCTAssertEqual(value.count, 3)
      XCTAssertEqual(value.verbose, true)
      XCTAssertEqual(value.values, [1, 2])
    }

    AssertParseCommand(PositionalArray3.self, PositionalArray3.self, ["--count", "3", "--verbose"], lines: ["1 2"]) { value in
      XCTAssertEqual(value.count, 3)
      XCTAssertEqual(value.verbose, true)
      XCTAssertEqual(value.values, [1, 2])
    }
  }
}

// MARK: -

private struct CaseIterableArgument: ParsableCommand {
  enum Mode: String, CaseIterable, ExpressibleByArgument {
    case foo, bar, baz
  }

  @Argument var mode: Mode
  @Argument var modes: [Mode]
}

extension ArgumentInteractiveTests {
  func testParsing_CaseIterableArgument() throws {
    AssertParseCommand(CaseIterableArgument.self, CaseIterableArgument.self, ["foo"], lines: ["2 3"]) { value in
      XCTAssertEqual(value.mode, .foo)
      XCTAssertEqual(value.modes, [.bar, .baz])
    }

    AssertParseCommand(CaseIterableArgument.self, CaseIterableArgument.self, [], lines: ["1", "2 3"]) { value in
      XCTAssertEqual(value.mode, .foo)
      XCTAssertEqual(value.modes, [.bar, .baz])
    }

    AssertParseCommand(CaseIterableArgument.self, CaseIterableArgument.self, [], lines: ["1 2", "2 3"]) { value in
      XCTAssertEqual(value.mode, .bar)
      XCTAssertEqual(value.modes, [.bar, .baz])
    }

    AssertParseCommand(CaseIterableArgument.self, CaseIterableArgument.self, [], lines: ["foo", "0", "2 3", "1"]) { value in
      XCTAssertEqual(value.mode, .baz)
      XCTAssertEqual(value.modes, [.foo])
    }

    AssertParseCommand(CaseIterableArgument.self, CaseIterableArgument.self, [], lines: ["1", "0 1", "2 3"]) { value in
      XCTAssertEqual(value.mode, .foo)
      XCTAssertEqual(value.modes, [.bar, .baz])
    }
  }
}
