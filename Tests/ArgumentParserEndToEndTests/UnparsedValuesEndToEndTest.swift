//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2021-2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import ArgumentParser
import ArgumentParserTestHelpers
import Testing

@Suite struct UnparsedValuesEndToEndTests {}

// MARK: Two values + unparsed variable

private struct Qux: ParsableArguments {
  @Option() var name: String
  @Flag() var verbose = false
  var count = 0
}

private struct Quizzo: ParsableArguments {
  @Option() var name: String
  @Flag() var verbose = false
  let count: Int
  init() { self.count = 0 }  // silence warning about count not being decoded
}

// swift-format-ignore: AlwaysUseLowerCamelCase
extension UnparsedValuesEndToEndTests {
  @Test func parsing_TwoPlusUnparsed() throws {
    expectParse(Qux.self, ["--name", "Qux"]) { qux in
      #expect(qux.name == "Qux")
      #expect(qux.verbose == false)
      #expect(qux.count == 0)
    }
    expectParse(Qux.self, ["--name", "Qux", "--verbose"]) { qux in
      #expect(qux.name == "Qux")
      #expect(qux.verbose)
      #expect(qux.count == 0)
    }

    expectParse(Quizzo.self, ["--name", "Qux", "--verbose"]) { quizzo in
      #expect(quizzo.name == "Qux")
      #expect(quizzo.verbose)
      #expect(quizzo.count == 0)
    }
  }

  @Test func parsing_TwoPlusUnparsed_Fails() throws {
    #expect(throws: (any Error).self) { try Qux.parse([]) }
    #expect(throws: (any Error).self) { try Qux.parse(["--name"]) }
    #expect(throws: (any Error).self) {
      try Qux.parse(["--name", "Qux", "--count"])
    }
    #expect(throws: (any Error).self) {
      try Qux.parse(["--name", "Qux", "--count", "2"])
    }
  }
}

// MARK: Two value + unparsed optional variable

private struct Hogeraa: ParsableArguments {
  var fullName: String? = "Full Name"
}

private struct Hogera: ParsableArguments {
  @Option() var firstName: String
  @Flag() var hasLastName = false
  var fullName: String?
  mutating func validate() throws {
    if hasLastName { fullName = "\(firstName) LastName" }
  }
}

private struct Piyo: ParsableArguments {
  @Option() var firstName: String
  @Flag() var hasLastName = false
  var fullName: String!
  mutating func validate() throws {
    fullName = firstName + (hasLastName ? " LastName" : "")
  }
}

// swift-format-ignore: AlwaysUseLowerCamelCase
extension UnparsedValuesEndToEndTests {
  @Test func parsing_TwoPlusOptionalUnparsed() throws {
    expectParse(Hogeraa.self, []) { hogeraa in
      #expect(hogeraa.fullName == "Full Name")
    }

    expectParse(Hogera.self, ["--first-name", "Hogera"]) { hogera in
      #expect(hogera.firstName == "Hogera")
      #expect(hogera.hasLastName == false)
      #expect(hogera.fullName == nil)
    }
    expectParse(Hogera.self, ["--first-name", "Hogera", "--has-last-name"]) {
      hogera in
      #expect(hogera.firstName == "Hogera")
      #expect(hogera.hasLastName)
      #expect(hogera.fullName == "Hogera LastName")
    }

    expectParse(Piyo.self, ["--first-name", "Hogera"]) { piyo in
      #expect(piyo.firstName == "Hogera")
      #expect(piyo.hasLastName == false)
      #expect(piyo.fullName == "Hogera")
    }
    expectParse(Piyo.self, ["--first-name", "Hogera", "--has-last-name"]) {
      piyo in
      #expect(piyo.firstName == "Hogera")
      #expect(piyo.hasLastName)
      #expect(piyo.fullName == "Hogera LastName")
    }
  }

  @Test func parsing_TwoPlusOptionalUnparsed_Fails() throws {
    #expect(throws: (any Error).self) { try Hogeraa.parse(["--full-name"]) }
    #expect(throws: (any Error).self) {
      try Hogeraa.parse(["--full-name", "Hogera Piyo"])
    }
    #expect(throws: (any Error).self) { try Hogera.parse([]) }
    #expect(throws: (any Error).self) { try Hogera.parse(["--first-name"]) }
    #expect(throws: (any Error).self) {
      try Hogera.parse(["--first-name", "Hogera", "--full-name"])
    }
    #expect(throws: (any Error).self) {
      try Hogera.parse(["--first-name", "Hogera", "--full-name", "Hogera Piyo"])
    }
    #expect(throws: (any Error).self) { try Piyo.parse([]) }
    #expect(throws: (any Error).self) { try Piyo.parse(["--first-name"]) }
    #expect(throws: (any Error).self) {
      try Piyo.parse(["--first-name", "Hogera", "--full-name"])
    }
    #expect(throws: (any Error).self) {
      try Piyo.parse(["--first-name", "Hogera", "--full-name", "Hogera Piyo"])
    }
  }
}

// MARK: Nested unparsed decodable type

private struct Foo: ParsableCommand {
  @Flag var foo: Bool = false
  var config: Config?
  @OptionGroup var opt: OptionalArguments
  @OptionGroup var def: DefaultedArguments
}

private struct Config: Decodable {
  var name: String
  var age: Int
}

private struct OptionalArguments: ParsableArguments {
  @Argument var title: String?
  @Option var edition: Int?
}

private struct DefaultedArguments: ParsableArguments {
  @Option var one = 1
  @Option var two = 2
}

// swift-format-ignore: AlwaysUseLowerCamelCase
extension UnparsedValuesEndToEndTests {
  @Test func unparsedNestedValues() {
    expectParse(Foo.self, []) { foo in
      #expect(foo.foo == false)
      #expect(foo.opt.title == nil)
      #expect(foo.opt.edition == nil)
      #expect(foo.def.one == 1)
      #expect(foo.def.two == 2)
    }

    expectParse(
      Foo.self,
      ["--foo", "--edition", "5", "Hello", "--one", "2", "--two", "1"]
    ) { foo in
      #expect(foo.foo)
      #expect(foo.opt.title == "Hello")
      #expect(foo.opt.edition == 5)
      #expect(foo.def.one == 2)
      #expect(foo.def.two == 1)
    }
  }

  @Test func unparsedNestedValues_Fails() {
    #expect(throws: (any Error).self) { try Foo.parse(["--edition", "aaa"]) }
    #expect(throws: (any Error).self) { try Foo.parse(["--one", "aaa"]) }
  }
}

// MARK: Nested unparsed optional decodable type

private struct Barr: ParsableCommand {
  var baz: Baz? = Baz(name: "Some Name", age: 105)
}

private struct Bar: ParsableCommand {
  @Flag var bar: Bool = false
  var baz: Baz?
  var bazz: Bazz?
  mutating func validate() throws {
    if bar {
      baz = Baz(name: "Some", age: 100)
      bazz = Bazz(name: "Other", age: 101)
    }
  }
}

private struct Baz: Decodable {
  var name: String?
  var age: Int!
}

private struct Bazz: Decodable {
  var name: String?
  var age: Int
}

// swift-format-ignore: AlwaysUseLowerCamelCase
extension UnparsedValuesEndToEndTests {
  @Test func unparsedNestedOptionalValue() {
    expectParse(Barr.self, []) { barr in
      let baz = try #require(barr.baz)

      #expect(baz.age == 105)
      #expect(baz.name == "Some Name")
    }

    expectParse(Bar.self, []) { bar in
      #expect(bar.bar == false)
      #expect(bar.baz == nil)
      #expect(bar.baz?.age == nil)
      #expect(bar.baz?.name == nil)
      #expect(bar.bazz == nil)
      #expect(bar.bazz?.age == nil)
      #expect(bar.bazz?.name == nil)
    }

    expectParse(Bar.self, ["--bar"]) { bar in
      #expect(bar.bar)
      let baz = try #require(bar.baz)
      #expect(baz.name == "Some")
      #expect(baz.age == 100)
      let bazz = try #require(bar.bazz)
      #expect(bazz.name == "Other")
      #expect(bazz.age == 101)
    }
  }

  @Test func unparsedNestedOptionalValue_Fails() {
    #expect(throws: (any Error).self) { try Bar.parse(["--baz", "xyz"]) }
    #expect(throws: (any Error).self) { try Bar.parse(["--bazz", "xyz"]) }
    #expect(throws: (any Error).self) { try Bar.parse(["--name", "None"]) }
    #expect(throws: (any Error).self) { try Bar.parse(["--age", "123"]) }
    #expect(throws: (any Error).self) {
      try Bar.parse(["--bar", "--name", "None"])
    }
    #expect(throws: (any Error).self) {
      try Bar.parse(["--bar", "--age", "123"])
    }
    #expect(throws: (any Error).self) { try Bar.parse(["--bar", "--baz"]) }
    #expect(throws: (any Error).self) {
      try Bar.parse(["--bar", "--baz", "xyz"])
    }
    #expect(throws: (any Error).self) {
      try Bar.parse(["--bar", "--baz", "--name", "None"])
    }
    #expect(throws: (any Error).self) {
      try Bar.parse(["--bar", "--baz", "xyz", "--name"])
    }
    #expect(throws: (any Error).self) {
      try Bar.parse(["--bar", "--baz", "xyz", "--name", "None"])
    }
    #expect(throws: (any Error).self) {
      try Bar.parse(["--bar", "--baz", "--age", "None"])
    }
    #expect(throws: (any Error).self) {
      try Bar.parse(["--bar", "--baz", "xyz", "--age"])
    }
    #expect(throws: (any Error).self) {
      try Bar.parse(["--bar", "--baz", "xyz", "--age", "None"])
    }
    #expect(throws: (any Error).self) { try Bar.parse(["--bar", "--bazz"]) }
    #expect(throws: (any Error).self) {
      try Bar.parse(["--bar", "--bazz", "xyz"])
    }
    #expect(throws: (any Error).self) {
      try Bar.parse(["--bar", "--bazz", "--name", "None"])
    }
    #expect(throws: (any Error).self) {
      try Bar.parse(["--bar", "--bazz", "xyz", "--name"])
    }
    #expect(throws: (any Error).self) {
      try Bar.parse(["--bar", "--bazz", "xyz", "--name", "None"])
    }
    #expect(throws: (any Error).self) {
      try Bar.parse(["--bar", "--bazz", "--age", "None"])
    }
    #expect(throws: (any Error).self) {
      try Bar.parse(["--bar", "--bazz", "xyz", "--age"])
    }
    #expect(throws: (any Error).self) {
      try Bar.parse(["--bar", "--bazz", "xyz", "--age", "None"])
    }
  }
}

// MARK: Value + unparsed dictionary

private struct Bamf: ParsableCommand {
  @Flag var bamph: Bool = false
  var bop: [String: String] = [:]
  var bopp: [String: [String]] = [:]
}

// swift-format-ignore: AlwaysUseLowerCamelCase
extension UnparsedValuesEndToEndTests {
  @Test func unparsedNestedDictionary() {
    expectParse(Bamf.self, []) { bamf in
      #expect(bamf.bamph == false)
      #expect(bamf.bop == [:])
      #expect(bamf.bopp == [:])
    }
  }
}

// MARK: Value + unparsed enum with associated values

private struct Qiqi: ParsableCommand {
  @Flag var qiqiqi: Bool = false
  var qiqii: Qiqii = .q("")
}

private enum Qiqii: Codable, Equatable {
  // Enums with associated values generate a Codable conformance
  // which calls `KeyedDecodingContainer.nestedContainer(keyedBy:)`.
  //
  // There is no known case of anything ever actually using the
  // `.nestedUnkeyedContainer()` method.
  case q(String)
  case i(Int)
}

// swift-format-ignore: AlwaysUseLowerCamelCase
extension UnparsedValuesEndToEndTests {
  @Test func unparsedEnumWithAssociatedValues() {
    expectParse(Qiqi.self, []) { qiqi in
      #expect(qiqi.qiqiqi == false)
      #expect(qiqi.qiqii == .q(""))
    }
  }
}

// MARK: Value + nested decodable inheriting class type

private struct Fry: ParsableCommand {
  @Flag var c: Bool = false
  var toksVig: Vig = .init()
}

private class Toks: Codable {
  var a = "hello"
}

private final class Vig: Toks {
  var b = "world"
}

// swift-format-ignore: AlwaysUseLowerCamelCase
extension UnparsedValuesEndToEndTests {
  @Test func unparsedNestedInheritingClassType() {
    expectParse(Fry.self, []) { fry in
      #expect(fry.c == false)
      #expect(fry.toksVig.a == "hello")
      #expect(fry.toksVig.b == "world")
    }
  }
}
