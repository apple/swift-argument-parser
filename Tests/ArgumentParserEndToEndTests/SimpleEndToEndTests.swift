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

@Suite struct SimpleEndToEndTests {}

// MARK: Single value String

private struct Bar: ParsableArguments {
  @Option() var name: String
}

// swift-format-ignore: AlwaysUseLowerCamelCase
// https://github.com/apple/swift-argument-parser/issues/710
extension SimpleEndToEndTests {
  @Test func parsing_SingleOption() throws {
    expectParse(Bar.self, ["--name", "Bar"]) { bar in
      #expect(bar.name == "Bar")
    }
    expectParse(Bar.self, ["--name", " foo "]) { bar in
      #expect(bar.name == " foo ")
    }
  }

  @Test func parsing_SingleOption_Fails() throws {
    #expect(throws: (any Error).self) { try Bar.parse([]) }
    #expect(throws: (any Error).self) { try Bar.parse(["--name"]) }
    #expect(throws: (any Error).self) { try Bar.parse(["--name", "--foo"]) }
    #expect(throws: (any Error).self) { try Bar.parse(["Bar"]) }
    #expect(throws: (any Error).self) {
      try Bar.parse(["--name", "Bar", "Baz"])
    }
    #expect(throws: (any Error).self) {
      try Bar.parse(["--name", "Bar", "--foo"])
    }
    #expect(throws: (any Error).self) {
      try Bar.parse(["--name", "Bar", "--foo", "Foo"])
    }
    #expect(throws: (any Error).self) {
      try Bar.parse(["--name", "Bar", "-f"])
    }
    #expect(throws: (any Error).self) {
      try Bar.parse(["--foo", "--name", "Bar"])
    }
    #expect(throws: (any Error).self) {
      try Bar.parse(["--foo", "Foo", "--name", "Bar"])
    }
    #expect(throws: (any Error).self) {
      try Bar.parse(["-f", "--name", "Bar"])
    }
  }
}

// MARK: Single value Int

private struct Foo: ParsableArguments {
  @Option() var count: Int
}

// swift-format-ignore: AlwaysUseLowerCamelCase
// https://github.com/apple/swift-argument-parser/issues/710
extension SimpleEndToEndTests {
  @Test func parsing_SingleOption_Int() throws {
    expectParse(Foo.self, ["--count", "42"]) { foo in
      #expect(foo.count == 42)
    }
  }

  @Test func parsing_SingleOption_Int_Fails() throws {
    #expect(throws: (any Error).self) { try Foo.parse([]) }
    #expect(throws: (any Error).self) { try Foo.parse(["--count"]) }
    #expect(throws: (any Error).self) { try Foo.parse(["--count", "a"]) }
    #expect(throws: (any Error).self) { try Foo.parse(["Bar"]) }
    #expect(throws: (any Error).self) {
      try Foo.parse(["--count", "42", "Baz"])
    }
    #expect(throws: (any Error).self) {
      try Foo.parse(["--count", "42", "--foo"])
    }
    #expect(throws: (any Error).self) {
      try Foo.parse(["--count", "42", "--foo", "Foo"])
    }
    #expect(throws: (any Error).self) {
      try Foo.parse(["--count", "42", "-f"])
    }
    #expect(throws: (any Error).self) {
      try Foo.parse(["--foo", "--count", "42"])
    }
    #expect(throws: (any Error).self) {
      try Foo.parse(["--foo", "Foo", "--count", "42"])
    }
    #expect(throws: (any Error).self) {
      try Foo.parse(["-f", "--count", "42"])
    }
  }
}

// MARK: Two values

private struct Baz: ParsableArguments {
  @Option() var name: String
  @Option() var format: String
}

// swift-format-ignore: AlwaysUseLowerCamelCase
// https://github.com/apple/swift-argument-parser/issues/710
extension SimpleEndToEndTests {
  @Test func parsing_TwoOptions_1() throws {
    expectParse(Baz.self, ["--name", "Bar", "--format", "Foo"]) { baz in
      #expect(baz.name == "Bar")
      #expect(baz.format == "Foo")
    }
  }

  @Test func parsing_TwoOptions_2() throws {
    expectParse(Baz.self, ["--format", "Foo", "--name", "Bar"]) { baz in
      #expect(baz.name == "Bar")
      #expect(baz.format == "Foo")
    }
  }

  @Test func parsing_TwoOptions_Fails() throws {
    #expect(throws: (any Error).self) {
      try Baz.parse(["--nam", "Bar", "--format", "Foo"])
    }
    #expect(throws: (any Error).self) {
      try Baz.parse(["--name", "Bar", "--forma", "Foo"])
    }
    #expect(throws: (any Error).self) { try Baz.parse(["--name", "Bar"]) }
    #expect(throws: (any Error).self) { try Baz.parse(["--format", "Foo"]) }

    #expect(throws: (any Error).self) {
      try Baz.parse(["--name", "--format", "Foo"])
    }
    #expect(throws: (any Error).self) {
      try Baz.parse(["--name", "Bar", "--format"])
    }
    #expect(throws: (any Error).self) {
      try Baz.parse(["--name", "Bar", "--format", "Foo", "Baz"])
    }
    #expect(throws: (any Error).self) {
      try Baz.parse(["Bar", "--name", "--format", "Foo"])
    }
    #expect(throws: (any Error).self) {
      try Baz.parse(["Bar", "--name", "Foo", "--format"])
    }
    #expect(throws: (any Error).self) {
      try Baz.parse(["Bar", "Foo", "--name", "--format"])
    }
    #expect(throws: (any Error).self) {
      try Baz.parse(["--name", "--name", "Bar", "--format", "Foo"])
    }
    #expect(throws: (any Error).self) {
      try Baz.parse(["--name", "Bar", "--format", "--format", "Foo"])
    }
    #expect(throws: (any Error).self) {
      try Baz.parse(["--format", "--name", "Bar", "Foo"])
    }
    #expect(throws: (any Error).self) {
      try Baz.parse(["--name", "--format", "Bar", "Foo"])
    }
  }
}
