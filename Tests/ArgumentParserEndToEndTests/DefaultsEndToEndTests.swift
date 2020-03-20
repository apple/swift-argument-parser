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

import XCTest
import ArgumentParserTestHelpers
import ArgumentParser

final class DefaultsEndToEndTests: XCTestCase {
}

// MARK: -

fileprivate struct Foo: ParsableArguments {
  struct Name: RawRepresentable, ExpressibleByArgument {
    var rawValue: String
  }
  @Option(default: Name(rawValue: "A"))
  var name: Name
  @Option(default: 3)
  var max: Int
}

extension DefaultsEndToEndTests {
  func testParsing_Defaults() throws {
    AssertParse(Foo.self, []) { foo in
      XCTAssertEqual(foo.name.rawValue, "A")
      XCTAssertEqual(foo.max, 3)
    }
    
    AssertParse(Foo.self, ["--name", "B"]) { foo in
      XCTAssertEqual(foo.name.rawValue, "B")
      XCTAssertEqual(foo.max, 3)
    }
    
    AssertParse(Foo.self, ["--max", "5"]) { foo in
      XCTAssertEqual(foo.name.rawValue, "A")
      XCTAssertEqual(foo.max, 5)
    }
    
    AssertParse(Foo.self, ["--max", "5", "--name", "B"]) { foo in
      XCTAssertEqual(foo.name.rawValue, "B")
      XCTAssertEqual(foo.max, 5)
    }
  }
}

// MARK: -

fileprivate struct Bar: ParsableArguments {
  enum Format: String, ExpressibleByArgument {
    case A
    case B
    case C
  }
  @Option(default: "N")
  var name: String
  @Option(default: .A)
  var format: Format
  @Option()
  var foo: String
  @Argument()
  var bar: String?
}

extension DefaultsEndToEndTests {
  func testParsing_Optional_WithAllValues_1() {
    AssertParse(Bar.self, ["--name", "A", "--format", "B", "--foo", "C", "D"]) { bar in
      XCTAssertEqual(bar.name, "A")
      XCTAssertEqual(bar.format, .B)
      XCTAssertEqual(bar.foo, "C")
      XCTAssertEqual(bar.bar, "D")
    }
  }
  
  func testParsing_Optional_WithAllValues_2() {
    AssertParse(Bar.self, ["D", "--format", "B", "--foo", "C", "--name", "A"]) { bar in
      XCTAssertEqual(bar.name, "A")
      XCTAssertEqual(bar.format, .B)
      XCTAssertEqual(bar.foo, "C")
      XCTAssertEqual(bar.bar, "D")
    }
  }
  
  func testParsing_Optional_WithAllValues_3() {
    AssertParse(Bar.self, ["--format", "B", "--foo", "C", "D", "--name", "A"]) { bar in
      XCTAssertEqual(bar.name, "A")
      XCTAssertEqual(bar.format, .B)
      XCTAssertEqual(bar.foo, "C")
      XCTAssertEqual(bar.bar, "D")
    }
  }
  
  func testParsing_Optional_WithMissingValues_1() {
    AssertParse(Bar.self, ["--format", "B", "--foo", "C", "D"]) { bar in
      XCTAssertEqual(bar.name, "N")
      XCTAssertEqual(bar.format, .B)
      XCTAssertEqual(bar.foo, "C")
      XCTAssertEqual(bar.bar, "D")
    }
  }
  
  func testParsing_Optional_WithMissingValues_2() {
    AssertParse(Bar.self, ["D", "--format", "B", "--foo", "C"]) { bar in
      XCTAssertEqual(bar.name, "N")
      XCTAssertEqual(bar.format, .B)
      XCTAssertEqual(bar.foo, "C")
      XCTAssertEqual(bar.bar, "D")
    }
  }
  
  func testParsing_Optional_WithMissingValues_3() {
    AssertParse(Bar.self, ["--format", "B", "--foo", "C", "D"]) { bar in
      XCTAssertEqual(bar.name, "N")
      XCTAssertEqual(bar.format, .B)
      XCTAssertEqual(bar.foo, "C")
      XCTAssertEqual(bar.bar, "D")
    }
  }
  
  func testParsing_Optional_WithMissingValues_4() {
    AssertParse(Bar.self, ["--name", "A", "--format", "B", "--foo", "C"]) { bar in
      XCTAssertEqual(bar.name, "A")
      XCTAssertEqual(bar.format, .B)
      XCTAssertEqual(bar.foo, "C")
      XCTAssertEqual(bar.bar, nil)
    }
  }
  
  func testParsing_Optional_WithMissingValues_5() {
    AssertParse(Bar.self, ["--format", "B", "--foo", "C", "--name", "A"]) { bar in
      XCTAssertEqual(bar.name, "A")
      XCTAssertEqual(bar.format,.B)
      XCTAssertEqual(bar.foo, "C")
      XCTAssertEqual(bar.bar, nil)
    }
  }
  
  func testParsing_Optional_WithMissingValues_6() {
    AssertParse(Bar.self, ["--format", "B", "--foo", "C", "--name", "A"]) { bar in
      XCTAssertEqual(bar.name, "A")
      XCTAssertEqual(bar.format, .B)
      XCTAssertEqual(bar.foo, "C")
      XCTAssertEqual(bar.bar, nil)
    }
  }
  
  func testParsing_Optional_WithMissingValues_7() {
    AssertParse(Bar.self, ["--foo", "C"]) { bar in
      XCTAssertEqual(bar.name, "N")
      XCTAssertEqual(bar.format, .A)
      XCTAssertEqual(bar.foo, "C")
      XCTAssertEqual(bar.bar, nil)
    }
  }
  
  func testParsing_Optional_WithMissingValues_8() {
    AssertParse(Bar.self, ["--format", "B", "--foo", "C"]) { bar in
      XCTAssertEqual(bar.name, "N")
      XCTAssertEqual(bar.format, .B)
      XCTAssertEqual(bar.foo, "C")
      XCTAssertEqual(bar.bar, nil)
    }
  }
  
  func testParsing_Optional_WithMissingValues_9() {
    AssertParse(Bar.self, ["--format", "B", "--foo", "C"]) { bar in
      XCTAssertEqual(bar.name, "N")
      XCTAssertEqual(bar.format, .B)
      XCTAssertEqual(bar.foo, "C")
      XCTAssertEqual(bar.bar, nil)
    }
  }
  
  func testParsing_Optional_WithMissingValues_10() {
    AssertParse(Bar.self, ["--format", "B", "--foo", "C"]) { bar in
      XCTAssertEqual(bar.name, "N")
      XCTAssertEqual(bar.format, .B)
      XCTAssertEqual(bar.foo, "C")
      XCTAssertEqual(bar.bar, nil)
    }
  }
  
  func testParsing_Optional_Fails() throws {
    XCTAssertThrowsError(try Bar.parse([]))
    XCTAssertThrowsError(try Bar.parse(["--fooz", "C"]))
    XCTAssertThrowsError(try Bar.parse(["--nam", "A", "--foo", "C"]))
    XCTAssertThrowsError(try Bar.parse(["--name"]))
    XCTAssertThrowsError(try Bar.parse(["A"]))
    XCTAssertThrowsError(try Bar.parse(["--name", "A", "D"]))
    XCTAssertThrowsError(try Bar.parse(["--name", "A", "--foo"]))
    XCTAssertThrowsError(try Bar.parse(["--name", "A", "--format", "B"]))
    XCTAssertThrowsError(try Bar.parse(["--name", "A", "-f"]))
    XCTAssertThrowsError(try Bar.parse(["D", "--name", "A"]))
    XCTAssertThrowsError(try Bar.parse(["-f", "--name", "A"]))
    XCTAssertThrowsError(try Bar.parse(["--foo", "--name", "A"]))
    XCTAssertThrowsError(try Bar.parse(["--foo", "--name", "AA", "BB"]))
  }
}

fileprivate struct Bar_NextInput: ParsableArguments {
  enum Format: String, ExpressibleByArgument {
    case A
    case B
    case C
    case D = "-d"
  }
  @Option(default: "N", parsing: .unconditional)
  var name: String
  @Option(default: .A, parsing: .unconditional)
  var format: Format
  @Option(parsing: .unconditional)
  var foo: String
  @Argument()
  var bar: String?
}

extension DefaultsEndToEndTests {
  func testParsing_Optional_WithOverlappingValues_1() {
    AssertParse(Bar_NextInput.self, ["--format", "B", "--name", "--foo", "--foo", "--name"]) { bar in
      XCTAssertEqual(bar.name, "--foo")
      XCTAssertEqual(bar.format, .B)
      XCTAssertEqual(bar.foo, "--name")
      XCTAssertEqual(bar.bar, nil)
    }
  }
  
  func testParsing_Optional_WithOverlappingValues_2() {
    AssertParse(Bar_NextInput.self, ["--format", "-d", "--foo", "--name", "--name", "--foo"]) { bar in
      XCTAssertEqual(bar.name, "--foo")
      XCTAssertEqual(bar.format, .D)
      XCTAssertEqual(bar.foo, "--name")
      XCTAssertEqual(bar.bar, nil)
    }
  }
  
  func testParsing_Optional_WithOverlappingValues_3() {
    AssertParse(Bar_NextInput.self, ["--format", "-d", "--name", "--foo", "--foo", "--name", "bar"]) { bar in
      XCTAssertEqual(bar.name, "--foo")
      XCTAssertEqual(bar.format, .D)
      XCTAssertEqual(bar.foo, "--name")
      XCTAssertEqual(bar.bar, "bar")
    }
  }
}

// MARK: -

fileprivate struct Baz: ParsableArguments {
  @Option(default: 0, parsing: .unconditional) var int: Int
  @Option(default: 0, parsing: .unconditional) var int8: Int8
  @Option(default: 0, parsing: .unconditional) var int16: Int16
  @Option(default: 0, parsing: .unconditional) var int32: Int32
  @Option(default: 0, parsing: .unconditional) var int64: Int64
  @Option(default: 0) var uint: UInt
  @Option(default: 0) var uint8: UInt8
  @Option(default: 0) var uint16: UInt16
  @Option(default: 0) var uint32: UInt32
  @Option(default: 0) var uint64: UInt64
  
  @Option(default: 0, parsing: .unconditional) var float: Float
  @Option(default: 0, parsing: .unconditional) var double: Double
  
  @Option(default: false) var bool: Bool
}

extension DefaultsEndToEndTests {
  func testParsing_AllTypes_1() {
    AssertParse(Baz.self, []) { baz in
      XCTAssertEqual(baz.int, 0)
      XCTAssertEqual(baz.int8, 0)
      XCTAssertEqual(baz.int16, 0)
      XCTAssertEqual(baz.int32, 0)
      XCTAssertEqual(baz.int64, 0)
      XCTAssertEqual(baz.uint, 0)
      XCTAssertEqual(baz.uint8, 0)
      XCTAssertEqual(baz.uint16, 0)
      XCTAssertEqual(baz.uint32, 0)
      XCTAssertEqual(baz.uint64, 0)
      XCTAssertEqual(baz.float, 0)
      XCTAssertEqual(baz.double, 0)
      XCTAssertEqual(baz.bool, false)
    }
  }
  
  func testParsing_AllTypes_2() {
    AssertParse(Baz.self, [
      "--int", "-1", "--int8", "-2", "--int16", "-3", "--int32", "-4", "--int64", "-5",
      "--uint", "1", "--uint8", "2", "--uint16", "3", "--uint32", "4", "--uint64", "5",
      "--float", "1.25", "--double", "2.5", "--bool", "true"
    ]) { baz in
      XCTAssertEqual(baz.int, -1)
      XCTAssertEqual(baz.int8, -2)
      XCTAssertEqual(baz.int16, -3)
      XCTAssertEqual(baz.int32, -4)
      XCTAssertEqual(baz.int64, -5)
      XCTAssertEqual(baz.uint, 1)
      XCTAssertEqual(baz.uint8, 2)
      XCTAssertEqual(baz.uint16, 3)
      XCTAssertEqual(baz.uint32, 4)
      XCTAssertEqual(baz.uint64, 5)
      XCTAssertEqual(baz.float, 1.25)
      XCTAssertEqual(baz.double, 2.5)
      XCTAssertEqual(baz.bool, true)
    }
  }
  
  func testParsing_AllTypes_Fails() throws {
    XCTAssertThrowsError(try Baz.parse(["--int8", "256"]))
    XCTAssertThrowsError(try Baz.parse(["--int16", "32768"]))
    XCTAssertThrowsError(try Baz.parse(["--int32", "2147483648"]))
    XCTAssertThrowsError(try Baz.parse(["--int64", "9223372036854775808"]))
    XCTAssertThrowsError(try Baz.parse(["--int", "9223372036854775808"]))
    
    XCTAssertThrowsError(try Baz.parse(["--uint8", "512"]))
    XCTAssertThrowsError(try Baz.parse(["--uint16", "65536"]))
    XCTAssertThrowsError(try Baz.parse(["--uint32", "4294967296"]))
    XCTAssertThrowsError(try Baz.parse(["--uint64", "18446744073709551616"]))
    XCTAssertThrowsError(try Baz.parse(["--uint", "18446744073709551616"]))
    
    XCTAssertThrowsError(try Baz.parse(["--uint8", "-1"]))
    XCTAssertThrowsError(try Baz.parse(["--uint16", "-1"]))
    XCTAssertThrowsError(try Baz.parse(["--uint32", "-1"]))
    XCTAssertThrowsError(try Baz.parse(["--uint64", "-1"]))
    XCTAssertThrowsError(try Baz.parse(["--uint", "-1"]))
    
    XCTAssertThrowsError(try Baz.parse(["--float", "zzz"]))
    XCTAssertThrowsError(try Baz.parse(["--double", "zzz"]))
    XCTAssertThrowsError(try Baz.parse(["--bool", "truthy"]))
  }
}

fileprivate struct Qux: ParsableArguments {
  @Argument(default: "quux")
  var name: String
}

extension DefaultsEndToEndTests {
  func testParsing_ArgumentDefaults() throws {
    AssertParse(Qux.self, []) { qux in
      XCTAssertEqual(qux.name, "quux")
    }
    AssertParse(Qux.self, ["Bar"]) { qux in
      XCTAssertEqual(qux.name, "Bar")
    }
    AssertParse(Qux.self, ["Bar-"]) { qux in
      XCTAssertEqual(qux.name, "Bar-")
    }
    AssertParse(Qux.self, ["Bar--"]) { qux in
      XCTAssertEqual(qux.name, "Bar--")
    }
    AssertParse(Qux.self, ["--", "-Bar"]) { qux in
      XCTAssertEqual(qux.name, "-Bar")
    }
    AssertParse(Qux.self, ["--", "--Bar"]) { qux in
      XCTAssertEqual(qux.name, "--Bar")
    }
    AssertParse(Qux.self, ["--", "--"]) { qux in
      XCTAssertEqual(qux.name, "--")
    }
  }

  func testParsing_ArgumentDefaults_Fails() throws {
    XCTAssertThrowsError(try Qux.parse(["--name"]))
    XCTAssertThrowsError(try Qux.parse(["Foo", "Bar"]))
  }
}

