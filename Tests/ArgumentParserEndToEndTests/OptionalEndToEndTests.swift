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

@Suite struct OptionalEndToEndTests {}

// MARK: -

private struct Foo: ParsableArguments {
  struct Name: RawRepresentable, ExpressibleByArgument {
    var rawValue: String
  }
  @Option() var name: Name?
  @Option() var max: Int?
}

// swift-format-ignore: AlwaysUseLowerCamelCase
extension OptionalEndToEndTests {
  @Test func parsing_Optional() throws {
    expectParse(Foo.self, []) { foo in
      #expect(foo.name == nil)
      #expect(foo.max == nil)
    }

    expectParse(Foo.self, ["--name", "A"]) { foo in
      let name = try #require(foo.name)
      #expect(name.rawValue == "A")
      #expect(foo.max == nil)
    }

    expectParse(Foo.self, ["--max", "3"]) { foo in
      #expect(foo.name == nil)
      #expect(foo.max == 3)
    }

    expectParse(Foo.self, ["--max", "3", "--name", "A"]) { foo in
      let name = try #require(foo.name)
      #expect(name.rawValue == "A")
      #expect(foo.max == 3)
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
  @Option() var name: String? = nil
  @Option() var format: Format? = nil
  @Option() var foo: String
  @Argument() var bar: String? = nil
}

// swift-format-ignore: AlwaysUseLowerCamelCase
extension OptionalEndToEndTests {
  @Test func parsing_Optional_WithAllValues_1() {
    expectParse(Bar.self, ["--name", "A", "--format", "B", "--foo", "C", "D"]) {
      bar in
      #expect(bar.name == "A")
      #expect(bar.format == .B)
      #expect(bar.foo == "C")
      #expect(bar.bar == "D")
    }
  }

  @Test func parsing_Optional_WithAllValues_2() {
    expectParse(Bar.self, ["D", "--format", "B", "--foo", "C", "--name", "A"]) {
      bar in
      #expect(bar.name == "A")
      #expect(bar.format == .B)
      #expect(bar.foo == "C")
      #expect(bar.bar == "D")
    }
  }

  @Test func parsing_Optional_WithAllValues_3() {
    expectParse(Bar.self, ["--format", "B", "--foo", "C", "D", "--name", "A"]) {
      bar in
      #expect(bar.name == "A")
      #expect(bar.format == .B)
      #expect(bar.foo == "C")
      #expect(bar.bar == "D")
    }
  }

  @Test func parsing_Optional_WithMissingValues_1() {
    expectParse(Bar.self, ["--format", "B", "--foo", "C", "D"]) { bar in
      #expect(bar.name == nil)
      #expect(bar.format == .B)
      #expect(bar.foo == "C")
      #expect(bar.bar == "D")
    }
  }

  @Test func parsing_Optional_WithMissingValues_2() {
    expectParse(Bar.self, ["D", "--format", "B", "--foo", "C"]) { bar in
      #expect(bar.name == nil)
      #expect(bar.format == .B)
      #expect(bar.foo == "C")
      #expect(bar.bar == "D")
    }
  }

  @Test func parsing_Optional_WithMissingValues_3() {
    expectParse(Bar.self, ["--format", "B", "--foo", "C", "D"]) { bar in
      #expect(bar.name == nil)
      #expect(bar.format == .B)
      #expect(bar.foo == "C")
      #expect(bar.bar == "D")
    }
  }

  @Test func parsing_Optional_WithMissingValues_4() {
    expectParse(Bar.self, ["--name", "A", "--format", "B", "--foo", "C"]) {
      bar in
      #expect(bar.name == "A")
      #expect(bar.format == .B)
      #expect(bar.foo == "C")
      #expect(bar.bar == nil)
    }
  }

  @Test func parsing_Optional_WithMissingValues_5() {
    expectParse(Bar.self, ["--format", "B", "--foo", "C", "--name", "A"]) {
      bar in
      #expect(bar.name == "A")
      #expect(bar.format == .B)
      #expect(bar.foo == "C")
      #expect(bar.bar == nil)
    }
  }

  @Test func parsing_Optional_WithMissingValues_6() {
    expectParse(Bar.self, ["--format", "B", "--foo", "C", "--name", "A"]) {
      bar in
      #expect(bar.name == "A")
      #expect(bar.format == .B)
      #expect(bar.foo == "C")
      #expect(bar.bar == nil)
    }
  }

  @Test func parsing_Optional_WithMissingValues_7() {
    expectParse(Bar.self, ["--foo", "C"]) { bar in
      #expect(bar.name == nil)
      #expect(bar.format == nil)
      #expect(bar.foo == "C")
      #expect(bar.bar == nil)
    }
  }

  @Test func parsing_Optional_WithMissingValues_8() {
    expectParse(Bar.self, ["--format", "B", "--foo", "C"]) { bar in
      #expect(bar.name == nil)
      #expect(bar.format == .B)
      #expect(bar.foo == "C")
      #expect(bar.bar == nil)
    }
  }

  @Test func parsing_Optional_WithMissingValues_9() {
    expectParse(Bar.self, ["--format", "B", "--foo", "C"]) { bar in
      #expect(bar.name == nil)
      #expect(bar.format == .B)
      #expect(bar.foo == "C")
      #expect(bar.bar == nil)
    }
  }

  @Test func parsing_Optional_WithMissingValues_10() {
    expectParse(Bar.self, ["--format", "B", "--foo", "C"]) { bar in
      #expect(bar.name == nil)
      #expect(bar.format == .B)
      #expect(bar.foo == "C")
      #expect(bar.bar == nil)
    }
  }

  @Test func parsing_Optional_WithMissingValues_11() {
    expectParse(Bar.self, ["--format", "B", "--foo", "C", "--name", "A"]) {
      bar in
      #expect(bar.name == "A")
      #expect(bar.format == .B)
      #expect(bar.foo == "C")
      #expect(bar.bar == nil)
    }
  }

  @Test func parsing_Optional_Fails() throws {
    #expect(throws: (any Error).self) { try Bar.parse([]) }
    #expect(throws: (any Error).self) {
      try Bar.parse(["--format", "ZZ", "--foo", "C"])
    }
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
  }
}

// swift-format-ignore: AlwaysUseLowerCamelCase
extension OptionalEndToEndTests {
  // Compilation test: https://github.com/apple/swift-argument-parser/issues/618
  private struct Command: ParsableCommand {
    struct MyError: Error {}
    struct Foo {
      init?(string: String) { return nil }
    }

    @Option(transform: {
      guard let foo = Foo(string: $0) else {
        throw MyError()
      }
      return foo
    })
    var testOption: Foo?

    @Argument(transform: {
      guard let foo = Foo(string: $0) else {
        throw MyError()
      }
      return foo
    })
    var testArgument: Foo?
  }
}
