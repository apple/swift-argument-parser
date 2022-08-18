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

final class OptionInteractiveTests: XCTestCase {}

private struct StringValue: ParsableCommand {
  @Option var string: String
}

extension OptionInteractiveTests {
  func testParsing_StringValue() throws {
    AssertParseCommand(StringValue.self, StringValue.self, [], lines: ["abc"]) { value in
      XCTAssertEqual(value.string, "abc")
    }

    AssertParseCommand(StringValue.self, StringValue.self, ["--string"], lines: ["abc"]) { value in
      XCTAssertEqual(value.string, "abc")
    }
  }
}

private struct OptionName: ParsableCommand {
  @Option(name: .shortAndLong) var string: String
}

extension OptionInteractiveTests {
  func testParsing_OptionName() throws {
    AssertParseCommand(OptionName.self, OptionName.self, ["--string"], lines: ["abc"]) { value in
      XCTAssertEqual(value.string, "abc")
    }

    AssertParseCommand(OptionName.self, OptionName.self, ["-s"], lines: ["abc"]) { value in
      XCTAssertEqual(value.string, "abc")
    }
  }
}

private struct Transform: ParsableCommand {
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

  @Option(transform: Format.init) var format: Format
}

extension OptionInteractiveTests {
  func testParsing_TransformableValue() throws {
    AssertParseCommand(Transform.self, Transform.self, [], lines: ["text"]) { value in
      XCTAssertEqual(value.format, .text)
    }
    AssertParseCommand(Transform.self, Transform.self, [], lines: ["keynote"]) { value in
      XCTAssertEqual(value.format, .other("keynote"))
    }
  }
}

// MARK: -

private struct Foo: ParsableCommand {
  struct Name: RawRepresentable, ExpressibleByArgument {
    var rawValue: String
  }

  @Option var name: Name
  @Option(parsing: .upToNextOption) var nums: [Int]
}

extension OptionInteractiveTests {
  func testParsing_ExpressibleValue() throws {
    AssertParseCommand(Foo.self, Foo.self, ["--name", "A"], lines: ["1 2 3"]) { value in
      XCTAssertEqual(value.name.rawValue, "A")
      XCTAssertEqual(value.nums, [1, 2, 3])
    }

    AssertParseCommand(Foo.self, Foo.self, ["--nums", "1", "2", "3"], lines: ["A"]) { value in
      XCTAssertEqual(value.name.rawValue, "A")
      XCTAssertEqual(value.nums, [1, 2, 3])
    }

    AssertParseCommand(Foo.self, Foo.self, [], lines: ["A", "1 2 3"]) { value in
      XCTAssertEqual(value.name.rawValue, "A")
      XCTAssertEqual(value.nums, [1, 2, 3])
    }
  }
}

private struct Bar: ParsableCommand {
  enum Format: String, ExpressibleByArgument {
    case A
    case B
    case C
  }

  @Option() var name: String
  @Option() var format: Format
  @Option() var foo: String
  @Argument() var bar: String
}

extension OptionInteractiveTests {
  func testParsing_Position1() {
    AssertParseCommand(Bar.self, Bar.self, ["--format", "B", "--foo", "C", "D"], lines: ["A"]) { value in
      XCTAssertEqual(value.name, "A")
      XCTAssertEqual(value.format, .B)
      XCTAssertEqual(value.foo, "C")
      XCTAssertEqual(value.bar, "D")
    }
  }

  func testParsing_Position2() {
    AssertParseCommand(Bar.self, Bar.self, ["D", "--format", "B", "--foo", "C"], lines: ["A"]) { value in
      XCTAssertEqual(value.name, "A")
      XCTAssertEqual(value.format, .B)
      XCTAssertEqual(value.foo, "C")
      XCTAssertEqual(value.bar, "D")
    }
  }

  func testParsing_Position3() {
    AssertParseCommand(Bar.self, Bar.self, ["--format", "B", "--foo", "C", "D"], lines: ["A"]) { value in
      XCTAssertEqual(value.name, "A")
      XCTAssertEqual(value.format, .B)
      XCTAssertEqual(value.foo, "C")
      XCTAssertEqual(value.bar, "D")
    }
  }

  func testParsing_Position4() {
    AssertParseCommand(Bar.self, Bar.self, ["--format", "B", "--foo", "C", "--name", "A"], lines: ["D"]) { value in
      XCTAssertEqual(value.name, "A")
      XCTAssertEqual(value.format, .B)
      XCTAssertEqual(value.foo, "C")
      XCTAssertEqual(value.bar, "D")
    }
  }

  func testParsing_Position5() {
    AssertParseCommand(Bar.self, Bar.self, ["--foo", "C"], lines: ["A", "B", "D"]) { value in
      XCTAssertEqual(value.name, "A")
      XCTAssertEqual(value.format, .B)
      XCTAssertEqual(value.foo, "C")
      XCTAssertEqual(value.bar, "D")
    }
  }

  func testParsing_Position6() {
    AssertParseCommand(Bar.self, Bar.self, ["--format", "B", "--foo", "C"], lines: ["A", "D"]) { value in
      XCTAssertEqual(value.name, "A")
      XCTAssertEqual(value.format, .B)
      XCTAssertEqual(value.foo, "C")
      XCTAssertEqual(value.bar, "D")
    }
  }
}

// MARK: -

private struct GlobalOptions: ParsableArguments {
  @Argument var values: [Int]
  @Flag var verbose: Bool = false
}

private struct Options: ParsableCommand {
  @Option var name: String
  @OptionGroup var globals: GlobalOptions
}

extension OptionInteractiveTests {
  func testParsing_OptionGroup() throws {
    AssertParseCommand(Options.self, Options.self, ["--verbose"], lines: ["kth", "1 2 3"]) { value in
      XCTAssertEqual(value.name, "kth")
      XCTAssertEqual(value.globals.verbose, true)
      XCTAssertEqual(value.globals.values, [1, 2, 3])
    }
  }
}
