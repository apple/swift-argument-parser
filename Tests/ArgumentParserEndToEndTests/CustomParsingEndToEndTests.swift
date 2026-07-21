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

@Suite struct ParsingEndToEndTests {
  @Suite struct Basics {}
  @Suite struct Defaults {}
  @Suite struct Arrays {}
}

struct Name {
  var rawValue: String

  init(rawValue: String) throws {
    if rawValue == "bad" {
      throw ValidationError("Bad input for name")
    }
    self.rawValue = rawValue
  }
}

extension Array where Element == Name {
  var rawValues: [String] {
    map { $0.rawValue }
  }
}

// MARK: -

private struct Foo: ParsableCommand {
  enum Subgroup: Equatable, Sendable {
    case first(Int)
    case second(Int)

    @Sendable
    static func makeFirst(_ str: String) throws -> Subgroup {
      guard let value = Int(str) else {
        throw ValidationError("Not a valid integer for 'first'")
      }
      return .first(value)
    }

    @Sendable
    static func makeSecond(_ str: String) throws -> Subgroup {
      guard let value = Int(str) else {
        throw ValidationError("Not a valid integer for 'second'")
      }
      return .second(value)
    }
  }

  @Option(transform: Subgroup.makeFirst)
  var first: Subgroup

  @Argument(transform: Subgroup.makeSecond)
  var second: Subgroup
}

extension ParsingEndToEndTests.Basics {
  @Test func parsing() throws {
    expectParse(Foo.self, ["--first", "1", "2"]) { foo in
      #expect(foo.first == .first(1))
      #expect(foo.second == .second(2))
    }
  }

  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_Fails() throws {
    // Failure inside custom parser
    #expect(throws: (any Error).self) {
      try Foo.parse(["--first", "1", "bad"])
    }
    #expect(throws: (any Error).self) {
      try Foo.parse(["--first", "bad", "2"])
    }
    #expect(throws: (any Error).self) {
      try Foo.parse(["--first", "bad", "bad"])
    }

    // Missing argument failures
    #expect(throws: (any Error).self) { try Foo.parse(["--first", "1"]) }
    #expect(throws: (any Error).self) { try Foo.parse(["5"]) }
    #expect(throws: (any Error).self) { try Foo.parse([]) }
  }
}

// MARK: -

private struct Bar: ParsableCommand {
  @Option(transform: { try Name(rawValue: $0) })
  // swift-format-ignore: NeverUseForceTry
  var firstName: Name = try! Name(rawValue: "none")

  @Argument(transform: { try Name(rawValue: $0) })
  var lastName: Name?
}

extension ParsingEndToEndTests.Defaults {
  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_Defaults() throws {
    expectParse(Bar.self, ["--first-name", "A", "B"]) { bar in
      #expect(bar.firstName.rawValue == "A")
      let barLastName = try #require(bar.lastName)
      #expect(barLastName.rawValue == "B")
    }

    expectParse(Bar.self, ["B"]) { bar in
      #expect(bar.firstName.rawValue == "none")
      let barLastName = try #require(bar.lastName)
      #expect(barLastName.rawValue == "B")
    }

    expectParse(Bar.self, ["--first-name", "A"]) { bar in
      #expect(bar.firstName.rawValue == "A")
      #expect(bar.lastName == nil)
    }

    expectParse(Bar.self, []) { bar in
      #expect(bar.firstName.rawValue == "none")
      #expect(bar.lastName == nil)
    }
  }

  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_Defaults_Fails() throws {
    #expect(throws: (any Error).self) {
      try Bar.parse(["--first-name", "bad"])
    }
    #expect(throws: (any Error).self) {
      try Bar.parse(["bad"])
    }
  }
}

// MARK: -

private struct Qux: ParsableCommand {
  @Option(transform: { try Name(rawValue: $0) })
  var firstName: [Name] = []

  @Argument(transform: { try Name(rawValue: $0) })
  var lastName: [Name] = []
}

// https://github.com/apple/swift-argument-parser/issues/710
extension ParsingEndToEndTests.Arrays {
  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_Array() throws {
    expectParse(Qux.self, ["--first-name", "A", "B"]) { qux in
      #expect(qux.firstName.rawValues == ["A"])
      #expect(qux.lastName.rawValues == ["B"])
    }

    expectParse(Qux.self, ["--first-name", "A", "--first-name", "B", "C", "D"])
    { qux in
      #expect(qux.firstName.rawValues == ["A", "B"])
      #expect(qux.lastName.rawValues == ["C", "D"])
    }

    expectParse(Qux.self, ["--first-name", "A", "--first-name", "B"]) { qux in
      #expect(qux.firstName.rawValues == ["A", "B"])
      #expect(qux.lastName.rawValues == [])
    }

    expectParse(Qux.self, ["C", "D"]) { qux in
      #expect(qux.firstName.rawValues == [])
      #expect(qux.lastName.rawValues == ["C", "D"])
    }

    expectParse(Qux.self, []) { qux in
      #expect(qux.firstName.rawValues == [])
      #expect(qux.lastName.rawValues == [])
    }
  }

  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func parsing_Array_Fails() {
    #expect(throws: (any Error).self) {
      try Qux.parse(["--first-name", "A", "--first-name", "B", "C", "D", "bad"])
    }
    #expect(throws: (any Error).self) {
      try Qux.parse([
        "--first-name", "A", "--first-name", "B", "--first-name", "bad", "C",
        "D",
      ])
    }
  }
}
