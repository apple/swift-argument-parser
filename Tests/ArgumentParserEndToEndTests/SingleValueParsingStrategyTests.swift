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

@Suite struct SingleValueParsingStrategyTests {}

// MARK: Scanning for Value

private struct Bar: ParsableArguments {
  @Option(parsing: .scanningForValue) var name: String
  @Option(parsing: .scanningForValue) var format: String
  @Option(parsing: .scanningForValue) var input: String
}

// swift-format-ignore: AlwaysUseLowerCamelCase
extension SingleValueParsingStrategyTests {
  @Test func parsing_scanningForValue_1() throws {
    expectParse(
      Bar.self, ["--name", "Foo", "--format", "Bar", "--input", "Baz"]
    ) { bar in
      #expect(bar.name == "Foo")
      #expect(bar.format == "Bar")
      #expect(bar.input == "Baz")
    }
  }

  @Test func parsing_scanningForValue_2() throws {
    expectParse(
      Bar.self, ["--name", "--format", "Foo", "Bar", "--input", "Baz"]
    ) { bar in
      #expect(bar.name == "Foo")
      #expect(bar.format == "Bar")
      #expect(bar.input == "Baz")
    }
  }

  @Test func parsing_scanningForValue_3() throws {
    expectParse(
      Bar.self, ["--name", "--format", "--input", "Foo", "Bar", "Baz"]
    ) { bar in
      #expect(bar.name == "Foo")
      #expect(bar.format == "Bar")
      #expect(bar.input == "Baz")
    }
  }
}

// MARK: Unconditional

private struct Baz: ParsableArguments {
  @Option(parsing: .unconditional) var name: String
  @Option(parsing: .unconditional) var format: String
  @Option(parsing: .unconditional) var input: String
}

// swift-format-ignore: AlwaysUseLowerCamelCase
extension SingleValueParsingStrategyTests {
  @Test func parsing_unconditional_1() throws {
    expectParse(
      Baz.self, ["--name", "Foo", "--format", "Bar", "--input", "Baz"]
    ) { bar in
      #expect(bar.name == "Foo")
      #expect(bar.format == "Bar")
      #expect(bar.input == "Baz")
    }
  }

  @Test func parsing_unconditional_2() throws {
    expectParse(
      Baz.self,
      ["--name", "--name", "--format", "--format", "--input", "--input"]
    ) { bar in
      #expect(bar.name == "--name")
      #expect(bar.format == "--format")
      #expect(bar.input == "--input")
    }
  }

  @Test func parsing_unconditional_3() throws {
    expectParse(
      Baz.self, ["--name", "-Foo", "--format", "-Bar", "--input", "-Baz"]
    ) { bar in
      #expect(bar.name == "-Foo")
      #expect(bar.format == "-Bar")
      #expect(bar.input == "-Baz")
    }
  }
}
