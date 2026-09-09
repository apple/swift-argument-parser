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

@Suite struct PositionalEndToEndTests {}

// MARK: Single value String

private struct Bar: ParsableArguments {
  @Argument() var name: String
}

// swift-format-ignore: AlwaysUseLowerCamelCase
extension PositionalEndToEndTests {
  @Test func parsing_SinglePositional() throws {
    expectParse(Bar.self, ["Bar"]) { bar in
      #expect(bar.name == "Bar")
    }
    expectParse(Bar.self, ["Bar-"]) { bar in
      #expect(bar.name == "Bar-")
    }
    expectParse(Bar.self, ["Bar--"]) { bar in
      #expect(bar.name == "Bar--")
    }
    expectParse(Bar.self, ["--", "-Bar"]) { bar in
      #expect(bar.name == "-Bar")
    }
    expectParse(Bar.self, ["--", "--Bar"]) { bar in
      #expect(bar.name == "--Bar")
    }
    expectParse(Bar.self, ["--", "--"]) { bar in
      #expect(bar.name == "--")
    }
  }

  @Test func parsing_SinglePositional_Fails() throws {
    #expect(throws: (any Error).self) { try Bar.parse([]) }
    #expect(throws: (any Error).self) { try Bar.parse(["--name"]) }
    #expect(throws: (any Error).self) { try Bar.parse(["Foo", "Bar"]) }
  }
}

// MARK: Two values

private struct Baz: ParsableArguments {
  @Argument() var name: String
  @Argument() var format: String
}

// swift-format-ignore: AlwaysUseLowerCamelCase
extension PositionalEndToEndTests {
  @Test func parsing_TwoPositional() throws {
    expectParse(Baz.self, ["Bar", "Foo"]) { baz in
      #expect(baz.name == "Bar")
      #expect(baz.format == "Foo")
    }
    expectParse(Baz.self, ["", "Foo"]) { baz in
      #expect(baz.name == "")
      #expect(baz.format == "Foo")
    }
    expectParse(Baz.self, ["Bar", ""]) { baz in
      #expect(baz.name == "Bar")
      #expect(baz.format == "")
    }
    expectParse(Baz.self, ["--", "--b", "--f"]) { baz in
      #expect(baz.name == "--b")
      #expect(baz.format == "--f")
    }
    expectParse(Baz.self, ["b", "--", "--f"]) { baz in
      #expect(baz.name == "b")
      #expect(baz.format == "--f")
    }
  }

  @Test func parsing_TwoPositional_Fails() throws {
    #expect(throws: (any Error).self) { try Baz.parse(["Bar", "Foo", "Baz"]) }
    #expect(throws: (any Error).self) { try Baz.parse(["Bar"]) }
    #expect(throws: (any Error).self) { try Baz.parse([]) }
    #expect(throws: (any Error).self) {
      try Baz.parse(["--name", "Bar", "Foo"])
    }
    #expect(throws: (any Error).self) {
      try Baz.parse(["Bar", "--name", "Foo"])
    }
    #expect(throws: (any Error).self) {
      try Baz.parse(["Bar", "Foo", "--name"])
    }
  }
}

// MARK: Multiple values

private struct Qux: ParsableArguments {
  @Argument() var names: [String] = []
}

// swift-format-ignore: AlwaysUseLowerCamelCase
extension PositionalEndToEndTests {
  @Test func parsing_MultiplePositional() throws {
    expectParse(Qux.self, []) { qux in
      #expect(qux.names == [])
    }
    expectParse(Qux.self, ["Bar"]) { qux in
      #expect(qux.names == ["Bar"])
    }
    expectParse(Qux.self, ["Bar", "Foo"]) { qux in
      #expect(qux.names == ["Bar", "Foo"])
    }
    expectParse(Qux.self, ["Bar", "Foo", "Baz"]) { qux in
      #expect(qux.names == ["Bar", "Foo", "Baz"])
    }

    expectParse(Qux.self, ["--", "--b", "--f"]) { qux in
      #expect(qux.names == ["--b", "--f"])
    }
    expectParse(Qux.self, ["b", "--", "--f"]) { qux in
      #expect(qux.names == ["b", "--f"])
    }
  }

  @Test func parsing_MultiplePositional_Fails() throws {
    // TODO: Allow zero-argument arrays?
    #expect(throws: (any Error).self) {
      try Qux.parse(["--name", "Bar", "Foo"])
    }
    #expect(throws: (any Error).self) {
      try Qux.parse(["Bar", "--name", "Foo"])
    }
    #expect(throws: (any Error).self) {
      try Qux.parse(["Bar", "Foo", "--name"])
    }
  }
}

// MARK: Single value plus multiple values

private struct Wobble: ParsableArguments {
  @Argument() var count: Int
  @Argument() var names: [String] = []
}

// swift-format-ignore: AlwaysUseLowerCamelCase
extension PositionalEndToEndTests {
  @Test func parsing_SingleAndMultiplePositional() throws {
    expectParse(Wobble.self, ["5"]) { wobble in
      #expect(wobble.count == 5)
      #expect(wobble.names == [])
    }
    expectParse(Wobble.self, ["5", "Bar"]) { wobble in
      #expect(wobble.count == 5)
      #expect(wobble.names == ["Bar"])
    }
    expectParse(Wobble.self, ["5", "Bar", "Foo"]) { wobble in
      #expect(wobble.count == 5)
      #expect(wobble.names == ["Bar", "Foo"])
    }
    expectParse(Wobble.self, ["5", "Bar", "Foo", "Baz"]) { wobble in
      #expect(wobble.count == 5)
      #expect(wobble.names == ["Bar", "Foo", "Baz"])
    }

    expectParse(Wobble.self, ["5", "--", "--b", "--f"]) { wobble in
      #expect(wobble.count == 5)
      #expect(wobble.names == ["--b", "--f"])
    }
    expectParse(Wobble.self, ["--", "5", "--b", "--f"]) { wobble in
      #expect(wobble.count == 5)
      #expect(wobble.names == ["--b", "--f"])
    }
    expectParse(Wobble.self, ["5", "b", "--", "--f"]) { wobble in
      #expect(wobble.count == 5)
      #expect(wobble.names == ["b", "--f"])
    }
  }

  @Test func parsing_SingleAndMultiplePositional_Fails() throws {
    #expect(throws: (any Error).self) { try Wobble.parse([]) }
    #expect(throws: (any Error).self) {
      try Wobble.parse(["--name", "Bar", "Foo"])
    }
    #expect(throws: (any Error).self) {
      try Wobble.parse(["Bar", "--name", "Foo"])
    }
    #expect(throws: (any Error).self) {
      try Wobble.parse(["Bar", "Foo", "--name"])
    }
  }
}

// MARK: Multiple parsed values

private struct Flob: ParsableArguments {
  @Argument() var counts: [Int] = []
}

// swift-format-ignore: AlwaysUseLowerCamelCase
extension PositionalEndToEndTests {
  @Test func parsing_MultipleParsedPositional() throws {
    expectParse(Flob.self, []) { flob in
      #expect(flob.counts == [])
    }
    expectParse(Flob.self, ["5"]) { flob in
      #expect(flob.counts == [5])
    }
    expectParse(Flob.self, ["5", "6"]) { flob in
      #expect(flob.counts == [5, 6])
    }

    expectParse(Flob.self, ["5", "--", "6"]) { flob in
      #expect(flob.counts == [5, 6])
    }
    expectParse(Flob.self, ["--", "5", "6"]) { flob in
      #expect(flob.counts == [5, 6])
    }
    expectParse(Flob.self, ["5", "6", "--"]) { flob in
      #expect(flob.counts == [5, 6])
    }
  }

  @Test func parsing_MultipleParsedPositional_Fails() throws {
    #expect(throws: (any Error).self) { try Flob.parse(["a"]) }
    #expect(throws: (any Error).self) { try Flob.parse(["5", "6", "a"]) }
  }
}

// MARK: Multiple parsed values

private struct BadlyFormed: ParsableArguments {
  @Argument() var numbers: [Int] = []
  @Argument() var name: String
}

// swift-format-ignore: AlwaysUseLowerCamelCase
extension PositionalEndToEndTests {
  // This test results in a fatal error when run, so it can't be enabled
  // or CI will prevent integration. Delete `disabled_` to verify the trap
  // locally.
  func disabled_parsing_BadlyFormedPositional() throws {
    expectParse(BadlyFormed.self, []) { _ in
      Issue.record("This should never execute")
    }
  }
}

// MARK: Conditional ExpressibleByArgument conformance

// Note: This retroactive conformance is a compilation test
extension Range<Int>: ArgumentParser.ExpressibleByArgument {
  public init?(argument: String) {
    guard let i = argument.firstIndex(of: ":"),
      let low = Int(String(argument[..<i])),
      let high = Int(String(argument[i...].dropFirst())),
      low <= high
    else { return nil }
    self = low..<high
  }
}

extension PositionalEndToEndTests {
  struct HasRange: ParsableArguments {
    @Argument var range: Range<Int>
  }

  @Test func parseCustomRangeConformance() throws {
    expectParse(HasRange.self, ["0:4"]) { args in
      #expect(args.range == 0..<4)
    }

    #expect(throws: (any Error).self) { try HasRange.parse([]) }
    #expect(throws: (any Error).self) { try HasRange.parse(["1"]) }
    #expect(throws: (any Error).self) { try HasRange.parse(["1:0"]) }
  }
}
