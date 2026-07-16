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

import ArgumentParser
import ArgumentParserTestHelpers
import Testing

@Suite struct DefaultsEndToEndTests {}

// MARK: -

private struct Foo: ParsableArguments {
  struct Name: RawRepresentable, ExpressibleByArgument {
    var rawValue: String
  }
  @Option
  var name: Name = Name(rawValue: "A")
  @Option
  var max: Int = 3
}

// https://github.com/apple/swift-argument-parser/issues/710
extension DefaultsEndToEndTests {
  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_Defaults() throws {
    expectParse(Foo.self, []) { foo in
      #expect(foo.name.rawValue == "A")
      #expect(foo.max == 3)
    }

    expectParse(Foo.self, ["--name", "B"]) { foo in
      #expect(foo.name.rawValue == "B")
      #expect(foo.max == 3)
    }

    expectParse(Foo.self, ["--max", "5"]) { foo in
      #expect(foo.name.rawValue == "A")
      #expect(foo.max == 5)
    }

    expectParse(Foo.self, ["--max", "5", "--name", "B"]) { foo in
      #expect(foo.name.rawValue == "B")
      #expect(foo.max == 5)
    }
  }
}

// MARK: -

private struct Bar: ParsableArguments {
  // swift-format-ignore: AlwaysUseLowerCamelCase
  enum Format: String, ExpressibleByArgument {
    case A
    case B
    case C
  }
  @Option
  var name: String = "N"
  @Option
  var format: Format = .A
  @Option()
  var foo: String
  @Argument()
  var bar: String?
}

// https://github.com/apple/swift-argument-parser/issues/710
extension DefaultsEndToEndTests {
  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_Optional_WithAllValues_1() {
    expectParse(Bar.self, ["--name", "A", "--format", "B", "--foo", "C", "D"]) {
      bar in
      #expect(bar.name == "A")
      #expect(bar.format == .B)
      #expect(bar.foo == "C")
      #expect(bar.bar == "D")
    }
  }

  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_Optional_WithAllValues_2() {
    expectParse(Bar.self, ["D", "--format", "B", "--foo", "C", "--name", "A"]) {
      bar in
      #expect(bar.name == "A")
      #expect(bar.format == .B)
      #expect(bar.foo == "C")
      #expect(bar.bar == "D")
    }
  }

  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_Optional_WithAllValues_3() {
    expectParse(Bar.self, ["--format", "B", "--foo", "C", "D", "--name", "A"]) {
      bar in
      #expect(bar.name == "A")
      #expect(bar.format == .B)
      #expect(bar.foo == "C")
      #expect(bar.bar == "D")
    }
  }

  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_Optional_WithMissingValues_1() {
    expectParse(Bar.self, ["--format", "B", "--foo", "C", "D"]) { bar in
      #expect(bar.name == "N")
      #expect(bar.format == .B)
      #expect(bar.foo == "C")
      #expect(bar.bar == "D")
    }
  }

  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_Optional_WithMissingValues_2() {
    expectParse(Bar.self, ["D", "--format", "B", "--foo", "C"]) { bar in
      #expect(bar.name == "N")
      #expect(bar.format == .B)
      #expect(bar.foo == "C")
      #expect(bar.bar == "D")
    }
  }

  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_Optional_WithMissingValues_3() {
    expectParse(Bar.self, ["--format", "B", "--foo", "C", "D"]) { bar in
      #expect(bar.name == "N")
      #expect(bar.format == .B)
      #expect(bar.foo == "C")
      #expect(bar.bar == "D")
    }
  }

  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_Optional_WithMissingValues_4() {
    expectParse(Bar.self, ["--name", "A", "--format", "B", "--foo", "C"]) {
      bar in
      #expect(bar.name == "A")
      #expect(bar.format == .B)
      #expect(bar.foo == "C")
      #expect(bar.bar == nil)
    }
  }

  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_Optional_WithMissingValues_5() {
    expectParse(Bar.self, ["--format", "B", "--foo", "C", "--name", "A"]) {
      bar in
      #expect(bar.name == "A")
      #expect(bar.format == .B)
      #expect(bar.foo == "C")
      #expect(bar.bar == nil)
    }
  }

  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_Optional_WithMissingValues_6() {
    expectParse(Bar.self, ["--format", "B", "--foo", "C", "--name", "A"]) {
      bar in
      #expect(bar.name == "A")
      #expect(bar.format == .B)
      #expect(bar.foo == "C")
      #expect(bar.bar == nil)
    }
  }

  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_Optional_WithMissingValues_7() {
    expectParse(Bar.self, ["--foo", "C"]) { bar in
      #expect(bar.name == "N")
      #expect(bar.format == .A)
      #expect(bar.foo == "C")
      #expect(bar.bar == nil)
    }
  }

  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_Optional_WithMissingValues_8() {
    expectParse(Bar.self, ["--format", "B", "--foo", "C"]) { bar in
      #expect(bar.name == "N")
      #expect(bar.format == .B)
      #expect(bar.foo == "C")
      #expect(bar.bar == nil)
    }
  }

  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_Optional_WithMissingValues_9() {
    expectParse(Bar.self, ["--format", "B", "--foo", "C"]) { bar in
      #expect(bar.name == "N")
      #expect(bar.format == .B)
      #expect(bar.foo == "C")
      #expect(bar.bar == nil)
    }
  }

  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_Optional_WithMissingValues_10() {
    expectParse(Bar.self, ["--format", "B", "--foo", "C"]) { bar in
      #expect(bar.name == "N")
      #expect(bar.format == .B)
      #expect(bar.foo == "C")
      #expect(bar.bar == nil)
    }
  }

  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_Optional_Fails() throws {
    #expect(throws: (any Error).self) { try Bar.parse([]) }
    #expect(throws: (any Error).self) { try Bar.parse(["--fooz", "C"]) }
    #expect(throws: (any Error).self) {
      try Bar.parse(["--nam", "A", "--foo", "C"])
    }
    #expect(throws: (any Error).self) { try Bar.parse(["--name"]) }
    #expect(throws: (any Error).self) { try Bar.parse(["A"]) }
    #expect(throws: (any Error).self) { try Bar.parse(["--name", "A", "D"]) }
    #expect(throws: (any Error).self) {
      try Bar.parse(["--name", "A", "--foo"])
    }
    #expect(throws: (any Error).self) {
      try Bar.parse(["--name", "A", "--format", "B"])
    }
    #expect(throws: (any Error).self) { try Bar.parse(["--name", "A", "-f"]) }
    #expect(throws: (any Error).self) { try Bar.parse(["D", "--name", "A"]) }
    #expect(throws: (any Error).self) { try Bar.parse(["-f", "--name", "A"]) }
    #expect(throws: (any Error).self) {
      try Bar.parse(["--foo", "--name", "A"])
    }
    #expect(throws: (any Error).self) {
      try Bar.parse(["--foo", "--name", "AA", "BB"])
    }
  }
}

// swift-format-ignore: AlwaysUseLowerCamelCase
// https://github.com/apple/swift-argument-parser/issues/710
private struct Bar_NextInput: ParsableArguments {
  enum Format: String, ExpressibleByArgument {
    case A
    case B
    case C
    case D = "-d"
  }
  @Option(parsing: .unconditional)
  var name: String = "N"
  @Option(parsing: .unconditional)
  var format: Format = .A
  @Option(parsing: .unconditional)
  var foo: String
  @Argument()
  var bar: String?
}

// https://github.com/apple/swift-argument-parser/issues/710
extension DefaultsEndToEndTests {
  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_Optional_WithOverlappingValues_1() {
    expectParse(
      Bar_NextInput.self,
      ["--format", "B", "--name", "--foo", "--foo", "--name"]
    ) { bar in
      #expect(bar.name == "--foo")
      #expect(bar.format == .B)
      #expect(bar.foo == "--name")
      #expect(bar.bar == nil)
    }
  }

  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_Optional_WithOverlappingValues_2() {
    expectParse(
      Bar_NextInput.self,
      ["--format", "-d", "--foo", "--name", "--name", "--foo"]
    ) { bar in
      #expect(bar.name == "--foo")
      #expect(bar.format == .D)
      #expect(bar.foo == "--name")
      #expect(bar.bar == nil)
    }
  }

  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_Optional_WithOverlappingValues_3() {
    expectParse(
      Bar_NextInput.self,
      ["--format", "-d", "--name", "--foo", "--foo", "--name", "bar"]
    ) { bar in
      #expect(bar.name == "--foo")
      #expect(bar.format == .D)
      #expect(bar.foo == "--name")
      #expect(bar.bar == "bar")
    }
  }
}

// MARK: -

private struct Baz: ParsableArguments {
  @Option(parsing: .unconditional) var int: Int = 0
  @Option(parsing: .unconditional) var int8: Int8 = 0
  @Option(parsing: .unconditional) var int16: Int16 = 0
  @Option(parsing: .unconditional) var int32: Int32 = 0
  @Option(parsing: .unconditional) var int64: Int64 = 0
  @Option var uint: UInt = 0
  @Option var uint8: UInt8 = 0
  @Option var uint16: UInt16 = 0
  @Option var uint32: UInt32 = 0
  @Option var uint64: UInt64 = 0

  @Option(parsing: .unconditional) var float: Float = 0
  @Option(parsing: .unconditional) var double: Double = 0

  @Option var bool: Bool = false
}

// https://github.com/apple/swift-argument-parser/issues/710
extension DefaultsEndToEndTests {
  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_AllTypes_1() {
    expectParse(Baz.self, []) { baz in
      #expect(baz.int == 0)
      #expect(baz.int8 == 0)
      #expect(baz.int16 == 0)
      #expect(baz.int32 == 0)
      #expect(baz.int64 == 0)
      #expect(baz.uint == 0)
      #expect(baz.uint8 == 0)
      #expect(baz.uint16 == 0)
      #expect(baz.uint32 == 0)
      #expect(baz.uint64 == 0)
      #expect(baz.float == 0)
      #expect(baz.double == 0)
      #expect(!baz.bool)
    }
  }

  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_AllTypes_2() {
    expectParse(
      Baz.self,
      [
        "--int", "-1", "--int8", "-2", "--int16", "-3", "--int32", "-4",
        "--int64", "-5",
        "--uint", "1", "--uint8", "2", "--uint16", "3", "--uint32", "4",
        "--uint64", "5",
        "--float", "1.25", "--double", "2.5", "--bool", "true",
      ]
    ) { baz in
      #expect(baz.int == -1)
      #expect(baz.int8 == -2)
      #expect(baz.int16 == -3)
      #expect(baz.int32 == -4)
      #expect(baz.int64 == -5)
      #expect(baz.uint == 1)
      #expect(baz.uint8 == 2)
      #expect(baz.uint16 == 3)
      #expect(baz.uint32 == 4)
      #expect(baz.uint64 == 5)
      #expect(baz.float == 1.25)
      #expect(baz.double == 2.5)
      #expect(baz.bool)
    }
  }

  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_AllTypes_Fails() throws {
    #expect(throws: (any Error).self) { try Baz.parse(["--int8", "256"]) }
    #expect(throws: (any Error).self) { try Baz.parse(["--int16", "32768"]) }
    #expect(throws: (any Error).self) {
      try Baz.parse(["--int32", "2147483648"])
    }
    #expect(throws: (any Error).self) {
      try Baz.parse(["--int64", "9223372036854775808"])
    }
    #expect(throws: (any Error).self) {
      try Baz.parse(["--int", "9223372036854775808"])
    }

    #expect(throws: (any Error).self) { try Baz.parse(["--uint8", "512"]) }
    #expect(throws: (any Error).self) { try Baz.parse(["--uint16", "65536"]) }
    #expect(throws: (any Error).self) {
      try Baz.parse(["--uint32", "4294967296"])
    }
    #expect(throws: (any Error).self) {
      try Baz.parse(["--uint64", "18446744073709551616"])
    }
    #expect(throws: (any Error).self) {
      try Baz.parse(["--uint", "18446744073709551616"])
    }

    #expect(throws: (any Error).self) { try Baz.parse(["--uint8", "-1"]) }
    #expect(throws: (any Error).self) { try Baz.parse(["--uint16", "-1"]) }
    #expect(throws: (any Error).self) { try Baz.parse(["--uint32", "-1"]) }
    #expect(throws: (any Error).self) { try Baz.parse(["--uint64", "-1"]) }
    #expect(throws: (any Error).self) { try Baz.parse(["--uint", "-1"]) }

    #expect(throws: (any Error).self) { try Baz.parse(["--float", "zzz"]) }
    #expect(throws: (any Error).self) { try Baz.parse(["--double", "zzz"]) }
    #expect(throws: (any Error).self) { try Baz.parse(["--bool", "truthy"]) }
  }
}

private struct Qux: ParsableArguments {
  @Argument
  var name: String = "quux"
}

// https://github.com/apple/swift-argument-parser/issues/710
extension DefaultsEndToEndTests {
  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_ArgumentDefaults() throws {
    expectParse(Qux.self, []) { qux in
      #expect(qux.name == "quux")
    }
    expectParse(Qux.self, ["Bar"]) { qux in
      #expect(qux.name == "Bar")
    }
    expectParse(Qux.self, ["Bar-"]) { qux in
      #expect(qux.name == "Bar-")
    }
    expectParse(Qux.self, ["Bar--"]) { qux in
      #expect(qux.name == "Bar--")
    }
    expectParse(Qux.self, ["--", "-Bar"]) { qux in
      #expect(qux.name == "-Bar")
    }
    expectParse(Qux.self, ["--", "--Bar"]) { qux in
      #expect(qux.name == "--Bar")
    }
    expectParse(Qux.self, ["--", "--"]) { qux in
      #expect(qux.name == "--")
    }
  }

  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_ArgumentDefaults_Fails() throws {
    #expect(throws: (any Error).self) { try Qux.parse(["--name"]) }
    #expect(throws: (any Error).self) { try Qux.parse(["Foo", "Bar"]) }
  }
}

private func exclaim(_ input: String) throws -> String {
  input + "!"
}

private struct OptionPropertyInitArguments_Default: ParsableArguments {
  @Option
  var data: String = "test"

  @Option(transform: exclaim)
  var transformedData: String = "test"
}

private struct OptionPropertyInitArguments_NoDefault_NoTransform:
  ParsableArguments
{
  @Option()
  var data: String
}

private struct OptionPropertyInitArguments_NoDefault_Transform:
  ParsableArguments
{
  @Option(transform: exclaim)
  var transformedData: String
}

// https://github.com/apple/swift-argument-parser/issues/710
extension DefaultsEndToEndTests {
  /// Tests that using default property initialization syntax parses the default value for the argument when nothing is provided from the command-line.
  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_OptionPropertyInit_Default_NoTransform_UseDefault() throws
  {
    expectParse(OptionPropertyInitArguments_Default.self, []) { arguments in
      #expect(arguments.data == "test")
    }
  }

  /// Tests that using default property initialization syntax parses the command-line-provided value for the argument when provided.
  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test
  func parsing_OptionPropertyInit_Default_NoTransform_OverrideDefault() throws {
    expectParse(OptionPropertyInitArguments_Default.self, ["--data", "test2"]) {
      arguments in
      #expect(arguments.data == "test2")
    }
  }

  /// Tests that *not* providing a default value still parses the argument
  /// correctly from the command-line.
  ///
  /// This test is almost certainly duplicated by others in the repository,
  /// but allows for quick use of test filtering during development on the
  /// initialization functionality.
  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_OptionPropertyInit_NoDefault_NoTransform() throws {
    expectParse(
      OptionPropertyInitArguments_NoDefault_NoTransform.self,
      ["--data", "test"]
    ) { arguments in
      #expect(arguments.data == "test")
    }
  }

  /// Tests that using default property initialization syntax on a property
  /// with a transform function provided parses the default value for the
  /// argument when nothing is provided from the command-line.
  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_OptionPropertyInit_Default_Transform_UseDefault() throws {
    expectParse(OptionPropertyInitArguments_Default.self, []) { arguments in
      #expect(arguments.transformedData == "test")
    }
  }

  /// Tests that using default property initialization syntax on a property
  /// with a transform function provided parses and transforms the
  /// command-line-provided value for the argument when provided.
  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_OptionPropertyInit_Default_Transform_OverrideDefault()
    throws
  {
    expectParse(
      OptionPropertyInitArguments_Default.self, ["--transformed-data", "test2"]
    ) { arguments in
      #expect(arguments.transformedData == "test2!")
    }
  }

  /// Tests that *not* providing a default value for a property with a
  /// transform function still parses the argument correctly from the
  /// command-line.
  ///
  /// This test is almost certainly duplicated by others in the repository,
  /// but allows for quick use of test filtering during development on the
  /// initialization functionality.
  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_OptionPropertyInit_NoDefault_Transform() throws {
    expectParse(
      OptionPropertyInitArguments_NoDefault_Transform.self,
      ["--transformed-data", "test"]
    ) { arguments in
      #expect(arguments.transformedData == "test!")
    }
  }
}

private struct ArgumentPropertyInitArguments_Default_NoTransform:
  ParsableArguments
{
  @Argument
  var data: String = "test"
}

private struct ArgumentPropertyInitArguments_NoDefault_NoTransform:
  ParsableArguments
{
  @Argument()
  var data: String
}

private struct ArgumentPropertyInitArguments_Default_Transform:
  ParsableArguments
{
  @Argument(transform: exclaim)
  var transformedData: String = "test"
}

private struct ArgumentPropertyInitArguments_NoDefault_Transform:
  ParsableArguments
{
  @Argument(transform: exclaim)
  var transformedData: String
}

// https://github.com/apple/swift-argument-parser/issues/710
extension DefaultsEndToEndTests {
  /// Tests that using default property initialization syntax parses the default value for the argument when nothing is provided from the command-line.
  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test
  func parsing_ArgumentPropertyInit_Default_NoTransform_UseDefault() throws {
    expectParse(ArgumentPropertyInitArguments_Default_NoTransform.self, []) {
      arguments in
      #expect(arguments.data == "test")
    }
  }

  /// Tests that using default property initialization syntax parses the command-line-provided value for the argument when provided.
  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test
  func parsing_ArgumentPropertyInit_Default_NoTransform_OverrideDefault()
    throws
  {
    expectParse(
      ArgumentPropertyInitArguments_Default_NoTransform.self, ["test2"]
    ) { arguments in
      #expect(arguments.data == "test2")
    }
  }

  /// Tests that *not* providing a default value still parses the argument
  /// correctly from the command-line.
  ///
  /// This test is almost certainly duplicated by others in the repository, but
  /// allows for quick use of test filtering during development on the
  /// initialization functionality.
  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_ArgumentPropertyInit_NoDefault_NoTransform() throws {
    expectParse(
      ArgumentPropertyInitArguments_NoDefault_NoTransform.self, ["test"]
    ) { arguments in
      #expect(arguments.data == "test")
    }
  }

  /// Tests that using default property initialization syntax on a property with a `transform` function provided parses the default value for the argument when nothing is provided from the command-line.
  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_ArgumentPropertyInit_Default_Transform_UseDefault() throws
  {
    expectParse(ArgumentPropertyInitArguments_Default_Transform.self, []) {
      arguments in
      #expect(arguments.transformedData == "test")
    }
  }

  /// Tests that using default property initialization syntax on a property with
  /// a `transform` function provided parses and transforms the
  /// command-line-provided value for the argument when provided.
  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_ArgumentPropertyInit_Default_Transform_OverrideDefault()
    throws
  {
    expectParse(ArgumentPropertyInitArguments_Default_Transform.self, ["test2"])
    { arguments in
      #expect(arguments.transformedData == "test2!")
    }
  }

  /// Tests that *not* providing a default value for a property with a
  /// transform function still parses the argument correctly from the
  /// command-line.
  ///
  /// This test is almost certainly duplicated by others in the repository,
  /// but allows for quick use of test filtering during development on the
  /// initialization functionality.
  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_ArgumentPropertyInit_NoDefault_Transform() throws {
    expectParse(
      ArgumentPropertyInitArguments_NoDefault_Transform.self, ["test"]
    ) { arguments in
      #expect(arguments.transformedData == "test!")
    }
  }
}

private struct Quux: ParsableArguments {
  @Option(parsing: .upToNextOption)
  var letters: [String] = ["A", "B"]

  @Argument()
  var numbers: [Int] = [1, 2]
}

// https://github.com/apple/swift-argument-parser/issues/710
extension DefaultsEndToEndTests {
  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_ArrayDefaults() throws {
    expectParse(Quux.self, []) { qux in
      #expect(qux.letters == ["A", "B"])
      #expect(qux.numbers == [1, 2])
    }
    expectParse(Quux.self, ["--letters", "C", "D"]) { qux in
      #expect(qux.letters == ["C", "D"])
      #expect(qux.numbers == [1, 2])
    }
    expectParse(Quux.self, ["3", "4"]) { qux in
      #expect(qux.letters == ["A", "B"])
      #expect(qux.numbers == [3, 4])
    }
    expectParse(Quux.self, ["3", "4", "--letters", "C", "D"]) { qux in
      #expect(qux.letters == ["C", "D"])
      #expect(qux.numbers == [3, 4])
    }
  }
}

private struct FlagPropertyInitArguments_Bool_Default: ParsableArguments {
  @Flag(inversion: .prefixedNo)
  var data: Bool = false
}

private struct FlagPropertyInitArguments_Bool_NoDefault: ParsableArguments {
  @Flag(inversion: .prefixedNo)
  var data: Bool
}

// https://github.com/apple/swift-argument-parser/issues/710
extension DefaultsEndToEndTests {
  /// Tests that using default property initialization syntax parses the default value for the argument when nothing is provided from the command-line.
  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_FlagPropertyInit_Bool_Default_UseDefault() throws {
    expectParse(FlagPropertyInitArguments_Bool_Default.self, []) { arguments in
      #expect(!arguments.data)
    }
  }

  /// Tests that using default property initialization syntax parses the command-line-provided value for the argument when provided.
  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_FlagPropertyInit_Bool_Default_OverrideDefault() throws {
    expectParse(FlagPropertyInitArguments_Bool_Default.self, ["--data"]) {
      arguments in
      #expect(arguments.data)
    }
  }

  /// Tests that *not* providing a default value still parses the argument
  /// correctly from the command-line.
  ///
  /// This test is almost certainly duplicated by others in the repository, but
  /// allows for quick use of test filtering during development on the
  /// initialization functionality.
  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_FlagPropertyInit_Bool_NoDefault() throws {
    expectParse(FlagPropertyInitArguments_Bool_NoDefault.self, ["--data"]) {
      arguments in
      #expect(arguments.data)
    }
  }
}

private enum HasData: EnumerableFlag {
  case noData
  case data
}

private struct FlagPropertyInitArguments_EnumerableFlag_Default:
  ParsableArguments
{
  @Flag
  var data: HasData = .noData
}

private struct FlagPropertyInitArguments_EnumerableFlag_NoDefault:
  ParsableArguments
{
  @Flag()
  var data: HasData
}

// https://github.com/apple/swift-argument-parser/issues/710
extension DefaultsEndToEndTests {
  /// Tests that using default property initialization syntax parses the default value for the argument when nothing is provided from the command-line.
  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test
  func parsing_FlagPropertyInit_EnumerableFlag_Default_UseDefault() throws {
    expectParse(FlagPropertyInitArguments_EnumerableFlag_Default.self, []) {
      arguments in
      #expect(arguments.data == .noData)
    }
  }

  /// Tests that using default property initialization syntax parses the command-line-provided value for the argument when provided.
  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test
  func parsing_FlagPropertyInit_EnumerableFlag_Default_OverrideDefault()
    throws
  {
    expectParse(
      FlagPropertyInitArguments_EnumerableFlag_Default.self, ["--data"]
    ) { arguments in
      #expect(arguments.data == .data)
    }
  }

  /// Tests that *not* providing a default value still parses the argument
  /// correctly from the command-line.
  ///
  /// This test is almost certainly duplicated by others in the repository, but
  /// allows for quick use of test filtering during development on the
  /// initialization functionality.
  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_FlagPropertyInit_EnumerableFlag_NoDefault() throws {
    expectParse(
      FlagPropertyInitArguments_EnumerableFlag_NoDefault.self, ["--data"]
    ) { arguments in
      #expect(arguments.data == .data)
    }
  }
}

private struct Main: ParsableCommand {
  static let configuration = CommandConfiguration(
    subcommands: [Sub.self],
    defaultSubcommand: Sub.self
  )

  struct Options: ParsableArguments {
    @Option(parsing: .upToNextOption)
    var letters: [String] = ["A", "B"]
  }

  struct Sub: ParsableCommand {
    @Argument()
    var numbers: [Int] = [1, 2]

    @OptionGroup()
    var options: Main.Options
  }
}

// https://github.com/apple/swift-argument-parser/issues/710
extension DefaultsEndToEndTests {
  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_ArrayDefaults_Subcommands() {
    expectParseCommand(Main.self, Main.Sub.self, []) { sub in
      #expect(sub.options.letters == ["A", "B"])
      #expect(sub.numbers == [1, 2])
    }
    expectParseCommand(Main.self, Main.Sub.self, ["--letters", "C", "D"]) {
      sub in
      #expect(sub.options.letters == ["C", "D"])
      #expect(sub.numbers == [1, 2])
    }
    expectParseCommand(Main.self, Main.Sub.self, ["3", "4"]) { sub in
      #expect(sub.options.letters == ["A", "B"])
      #expect(sub.numbers == [3, 4])
    }
    expectParseCommand(
      Main.self, Main.Sub.self, ["3", "4", "--letters", "C", "D"]
    ) { sub in
      #expect(sub.options.letters == ["C", "D"])
      #expect(sub.numbers == [3, 4])
    }
  }
}

private struct RequiredArray_Option_NoTransform: ParsableArguments {
  @Option(parsing: .remaining)
  var array: [String]
}

private struct RequiredArray_Option_Transform: ParsableArguments {
  @Option(parsing: .remaining, transform: exclaim)
  var array: [String]
}

private struct RequiredArray_Argument_NoTransform: ParsableArguments {
  @Argument()
  var array: [String]
}

private struct RequiredArray_Argument_Transform: ParsableArguments {
  @Argument(transform: exclaim)
  var array: [String]
}

private struct RequiredArray_Flag: ParsableArguments {
  @Flag
  var array: [HasData]
}

// https://github.com/apple/swift-argument-parser/issues/710
extension DefaultsEndToEndTests {
  /// Tests that not providing an argument for a required array option produces an error.
  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_RequiredArray_Option_NoTransform_NoInput() {
    #expect(throws: (any Error).self) {
      try RequiredArray_Option_NoTransform.parse([])
    }
  }

  /// Tests that providing a single argument for a required array option parses that value correctly.
  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_RequiredArray_Option_NoTransform_SingleInput() {
    expectParse(RequiredArray_Option_NoTransform.self, ["--array", "1"]) {
      arguments in
      #expect(arguments.array == ["1"])
    }
  }

  /// Tests that providing multiple arguments for a required array option parses those values correctly.
  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_RequiredArray_Option_NoTransform_MultipleInput() {
    expectParse(RequiredArray_Option_NoTransform.self, ["--array", "2", "3"]) {
      arguments in
      #expect(arguments.array == ["2", "3"])
    }
  }

  /// Tests that not providing an argument for a required array option with a transform produces an error.
  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_RequiredArray_Option_Transform_NoInput() {
    #expect(throws: (any Error).self) {
      try RequiredArray_Option_Transform.parse([])
    }
  }

  /// Tests that providing a single argument for a required array option with a transform parses that value correctly.
  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_RequiredArray_Option_Transform_SingleInput() {
    expectParse(RequiredArray_Option_Transform.self, ["--array", "1"]) {
      arguments in
      #expect(arguments.array == ["1!"])
    }
  }

  /// Tests that providing multiple arguments for a required array option with a transform parses those values correctly.
  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_RequiredArray_Option_Transform_MultipleInput() {
    expectParse(RequiredArray_Option_Transform.self, ["--array", "2", "3"]) {
      arguments in
      #expect(arguments.array == ["2!", "3!"])
    }
  }

  /// Tests that not providing an argument for a required array argument produces an error.
  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_RequiredArray_Argument_NoTransform_NoInput() {
    #expect(throws: (any Error).self) {
      try RequiredArray_Argument_NoTransform.parse([])
    }
  }

  /// Tests that providing a single argument for a required array argument parses that value correctly.
  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_RequiredArray_Argument_NoTransform_SingleInput() {
    expectParse(RequiredArray_Argument_NoTransform.self, ["1"]) { arguments in
      #expect(arguments.array == ["1"])
    }
  }

  /// Tests that providing multiple arguments for a required array argument parses those values correctly.
  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_RequiredArray_Argument_NoTransform_MultipleInput() {
    expectParse(RequiredArray_Argument_NoTransform.self, ["2", "3"]) {
      arguments in
      #expect(arguments.array == ["2", "3"])
    }
  }

  /// Tests that not providing an argument for a required array argument with a transform produces an error.
  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_RequiredArray_Argument_Transform_NoInput() {
    #expect(throws: (any Error).self) {
      try RequiredArray_Argument_Transform.parse([])
    }
  }

  /// Tests that providing a single argument for a required array argument with a transform parses that value correctly.
  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_RequiredArray_Argument_Transform_SingleInput() {
    expectParse(RequiredArray_Argument_Transform.self, ["1"]) { arguments in
      #expect(arguments.array == ["1!"])
    }
  }

  /// Tests that providing multiple arguments for a required array argument with a transform parses those values correctly.
  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_RequiredArray_Argument_Transform_MultipleInput() {
    expectParse(RequiredArray_Argument_Transform.self, ["2", "3"]) {
      arguments in
      #expect(arguments.array == ["2!", "3!"])
    }
  }

  /// Tests that not providing an argument for a required array flag produces an error.
  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_RequiredArray_Flag_NoInput() {
    #expect(throws: (any Error).self) { try RequiredArray_Flag.parse([]) }
  }

  /// Tests that providing a single argument for a required array flag parses that value correctly.
  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_RequiredArray_Flag_SingleInput() {
    expectParse(RequiredArray_Flag.self, ["--data"]) { arguments in
      #expect(arguments.array == [.data])
    }
  }

  /// Tests that providing multiple arguments for a required array flag parses those values correctly.
  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_RequiredArray_Flag_MultipleInput() {
    expectParse(RequiredArray_Flag.self, ["--data", "--no-data"]) { arguments in
      #expect(arguments.array == [.data, .noData])
    }
  }
}

@available(*, deprecated)
private struct OptionPropertyDeprecatedInit_NoDefault: ParsableArguments {
  @Option(completion: .file(), help: "")
  var data: String = "test"
}

// https://github.com/apple/swift-argument-parser/issues/710
extension DefaultsEndToEndTests {
  /// Tests that instances created using deprecated initializer with completion and help arguments swapped are constructed and parsed correctly.
  @available(*, deprecated)
  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_OptionPropertyDeprecatedInit_NoDefault() {
    expectParse(OptionPropertyDeprecatedInit_NoDefault.self, []) { arguments in
      #expect(arguments.data == "test")
    }
  }
}

// MARK: Overload selection

extension DefaultsEndToEndTests {
  private struct AbsolutePath: ExpressibleByArgument {
    init(_ value: String) {}
    init?(argument: String) {}
  }

  private struct TwoPaths: ParsableCommand {
    @Argument(help: .init("The path"))
    var path1 = AbsolutePath("abc")

    @Argument(help: "The path")
    var path2 = AbsolutePath("abc")

    @Option(help: .init("The path"))
    var path3 = AbsolutePath("abc")

    @Option(help: "The path")
    var path4 = AbsolutePath("abc")
  }

  /// Tests that a non-optional `Value` type is inferred, regardless of how the
  /// initializer parameters are spelled.
  ///
  /// Previously, string literals and `.init` calls for the help parameter
  /// inferred different generic types.
  @Test func helpInitInferredType() throws {
    expectParse(TwoPaths.self, []) { cmd in
      #expect(type(of: cmd.path1) == AbsolutePath.self)
      #expect(type(of: cmd.path2) == AbsolutePath.self)
      #expect(type(of: cmd.path3) == AbsolutePath.self)
      #expect(type(of: cmd.path4) == AbsolutePath.self)
    }
  }
}

// https://github.com/apple/swift-argument-parser/issues/710
extension DefaultsEndToEndTests {
  private struct UnderscoredOptional: ParsableCommand {
    @Option(name: .customLong("arg"))
    var _arg: String?
  }

  private struct UnderscoredArray: ParsableCommand {
    @Option(name: .customLong("columns"), parsing: .upToNextOption)
    var _columns: [String] = []
  }

  @Test func underscoredOptional() throws {
    expectParse(UnderscoredOptional.self, []) { parsed in
      #expect(parsed._arg == nil)
    }
    expectParse(UnderscoredOptional.self, ["--arg", "foo"]) { parsed in
      #expect(parsed._arg == "foo")
    }
  }

  @Test func underscoredArray() throws {
    expectParse(UnderscoredArray.self, []) { parsed in
      #expect(parsed._columns == [])
    }
    expectParse(UnderscoredArray.self, ["--columns", "foo", "bar", "baz"]) {
      parsed in
      #expect(parsed._columns == ["foo", "bar", "baz"])
    }
  }
}
