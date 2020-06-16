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


fileprivate func exclaim(_ input: String) throws -> String {
  return input + "!"
}

fileprivate struct OptionPropertyInitArguments_Default: ParsableArguments {
  @Option
  var data: String = "test"

  @Option(transform: exclaim)
  var transformedData: String = "test"
}

fileprivate struct OptionPropertyInitArguments_NoDefault_NoTransform: ParsableArguments {
  @Option()
  var data: String
}

fileprivate struct OptionPropertyInitArguments_NoDefault_Transform: ParsableArguments {
  @Option(transform: exclaim)
  var transformedData: String
}

extension DefaultsEndToEndTests {
  /// Tests that using default property initialization syntax parses the default value for the argument when nothing is provided from the command-line.
  func testParsing_OptionPropertyInit_Default_NoTransform_UseDefault() throws {
    AssertParse(OptionPropertyInitArguments_Default.self, []) { arguments in
      XCTAssertEqual(arguments.data, "test")
    }
  }

  /// Tests that using default property initialization syntax parses the command-line-provided value for the argument when provided.
  func testParsing_OptionPropertyInit_Default_NoTransform_OverrideDefault() throws {
    AssertParse(OptionPropertyInitArguments_Default.self, ["--data", "test2"]) { arguments in
      XCTAssertEqual(arguments.data, "test2")
    }
  }

  /// Tests that *not* providing a default value still parses the argument correctly from the command-line.
  /// This test is almost certainly duplicated by others in the repository, but allows for quick use of test filtering during development on the initialization functionality.
  func testParsing_OptionPropertyInit_NoDefault_NoTransform() throws {
    AssertParse(OptionPropertyInitArguments_NoDefault_NoTransform.self, ["--data", "test"]) { arguments in
      XCTAssertEqual(arguments.data, "test")
    }
  }

  /// Tests that using default property initialization syntax on a property with a `transform` function provided parses the default value for the argument when nothing is provided from the command-line.
  func testParsing_OptionPropertyInit_Default_Transform_UseDefault() throws {
    AssertParse(OptionPropertyInitArguments_Default.self, []) { arguments in
      XCTAssertEqual(arguments.transformedData, "test")
    }
  }

  /// Tests that using default property initialization syntax on a property with a `transform` function provided parses and transforms the command-line-provided value for the argument when provided.
  func testParsing_OptionPropertyInit_Default_Transform_OverrideDefault() throws {
    AssertParse(OptionPropertyInitArguments_Default.self, ["--transformed-data", "test2"]) { arguments in
      XCTAssertEqual(arguments.transformedData, "test2!")
    }
  }

  /// Tests that *not* providing a default value for a property with a `transform` function still parses the argument correctly from the command-line.
  /// This test is almost certainly duplicated by others in the repository, but allows for quick use of test filtering during development on the initialization functionality.
  func testParsing_OptionPropertyInit_NoDefault_Transform() throws {
    AssertParse(OptionPropertyInitArguments_NoDefault_Transform.self, ["--transformed-data", "test"]) { arguments in
      XCTAssertEqual(arguments.transformedData, "test!")
    }
  }
}


fileprivate struct ArgumentPropertyInitArguments_Default_NoTransform: ParsableArguments {
  @Argument
  var data: String = "test"
}

fileprivate struct ArgumentPropertyInitArguments_NoDefault_NoTransform: ParsableArguments {
  @Argument()
  var data: String
}

fileprivate struct ArgumentPropertyInitArguments_Default_Transform: ParsableArguments {
  @Argument(transform: exclaim)
    var transformedData: String = "test"
}

fileprivate struct ArgumentPropertyInitArguments_NoDefault_Transform: ParsableArguments {
  @Argument(transform: exclaim)
  var transformedData: String
}

extension DefaultsEndToEndTests {
  /// Tests that using default property initialization syntax parses the default value for the argument when nothing is provided from the command-line.
  func testParsing_ArgumentPropertyInit_Default_NoTransform_UseDefault() throws {
    AssertParse(ArgumentPropertyInitArguments_Default_NoTransform.self, []) { arguments in
      XCTAssertEqual(arguments.data, "test")
    }
  }

  /// Tests that using default property initialization syntax parses the command-line-provided value for the argument when provided.
  func testParsing_ArgumentPropertyInit_Default_NoTransform_OverrideDefault() throws {
    AssertParse(ArgumentPropertyInitArguments_Default_NoTransform.self, ["test2"]) { arguments in
      XCTAssertEqual(arguments.data, "test2")
    }
  }

  /// Tests that *not* providing a default value still parses the argument correctly from the command-line.
  /// This test is almost certainly duplicated by others in the repository, but allows for quick use of test filtering during development on the initialization functionality.
  func testParsing_ArgumentPropertyInit_NoDefault_NoTransform() throws {
    AssertParse(ArgumentPropertyInitArguments_NoDefault_NoTransform.self, ["test"]) { arguments in
      XCTAssertEqual(arguments.data, "test")
    }
  }

  /// Tests that using default property initialization syntax on a property with a `transform` function provided parses the default value for the argument when nothing is provided from the command-line.
  func testParsing_ArgumentPropertyInit_Default_Transform_UseDefault() throws {
    AssertParse(ArgumentPropertyInitArguments_Default_Transform.self, []) { arguments in
      XCTAssertEqual(arguments.transformedData, "test")
    }
  }

  /// Tests that using default property initialization syntax on a property with a `transform` function provided parses and transforms the command-line-provided value for the argument when provided.
  func testParsing_ArgumentPropertyInit_Default_Transform_OverrideDefault() throws {
    AssertParse(ArgumentPropertyInitArguments_Default_Transform.self, ["test2"]) { arguments in
      XCTAssertEqual(arguments.transformedData, "test2!")
    }
  }

  /// Tests that *not* providing a default value for a property with a `transform` function still parses the argument correctly from the command-line.
  /// This test is almost certainly duplicated by others in the repository, but allows for quick use of test filtering during development on the initialization functionality.
  func testParsing_ArgumentPropertyInit_NoDefault_Transform() throws {
    AssertParse(ArgumentPropertyInitArguments_NoDefault_Transform.self, ["test"]) { arguments in
      XCTAssertEqual(arguments.transformedData, "test!")
    }
  }
}


fileprivate struct FlagPropertyInitArguments_Bool_Default: ParsableArguments {
  @Flag(inversion: .prefixedNo)
  var data: Bool = false
}

fileprivate struct FlagPropertyInitArguments_Bool_NoDefault: ParsableArguments {
  @Flag(inversion: .prefixedNo)
  var data: Bool
}


extension DefaultsEndToEndTests {
  /// Tests that using default property initialization syntax parses the default value for the argument when nothing is provided from the command-line.
  func testParsing_FlagPropertyInit_Bool_Default_UseDefault() throws {
    AssertParse(FlagPropertyInitArguments_Bool_Default.self, []) { arguments in
      XCTAssertEqual(arguments.data, false)
    }
  }

  /// Tests that using default property initialization syntax parses the command-line-provided value for the argument when provided.
  func testParsing_FlagPropertyInit_Bool_Default_OverrideDefault() throws {
    AssertParse(FlagPropertyInitArguments_Bool_Default.self, ["--data"]) { arguments in
      XCTAssertEqual(arguments.data, true)
    }
  }

  /// Tests that *not* providing a default value still parses the argument correctly from the command-line.
  /// This test is almost certainly duplicated by others in the repository, but allows for quick use of test filtering during development on the initialization functionality.
  func testParsing_FlagPropertyInit_Bool_NoDefault() throws {
    AssertParse(FlagPropertyInitArguments_Bool_NoDefault.self, ["--data"]) { arguments in
      XCTAssertEqual(arguments.data, true)
    }
  }
}


fileprivate enum HasData: EnumerableFlag {
  case noData
  case data
}

fileprivate struct FlagPropertyInitArguments_EnumerableFlag_Default: ParsableArguments {
  @Flag
  var data: HasData = .noData
}

fileprivate struct FlagPropertyInitArguments_EnumerableFlag_NoDefault: ParsableArguments {
  @Flag()
  var data: HasData
}


extension DefaultsEndToEndTests {
  /// Tests that using default property initialization syntax parses the default value for the argument when nothing is provided from the command-line.
  func testParsing_FlagPropertyInit_EnumerableFlag_Default_UseDefault() throws {
    AssertParse(FlagPropertyInitArguments_EnumerableFlag_Default.self, []) { arguments in
      XCTAssertEqual(arguments.data, .noData)
    }
  }

  /// Tests that using default property initialization syntax parses the command-line-provided value for the argument when provided.
  func testParsing_FlagPropertyInit_EnumerableFlag_Default_OverrideDefault() throws {
    AssertParse(FlagPropertyInitArguments_EnumerableFlag_Default.self, ["--data"]) { arguments in
      XCTAssertEqual(arguments.data, .data)
    }
  }

  /// Tests that *not* providing a default value still parses the argument correctly from the command-line.
  /// This test is almost certainly duplicated by others in the repository, but allows for quick use of test filtering during development on the initialization functionality.
  func testParsing_FlagPropertyInit_EnumerableFlag_NoDefault() throws {
    AssertParse(FlagPropertyInitArguments_EnumerableFlag_NoDefault.self, ["--data"]) { arguments in
      XCTAssertEqual(arguments.data, .data)
    }
  }
}
