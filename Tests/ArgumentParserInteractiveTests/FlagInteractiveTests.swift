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

final class FlagInteractiveTests: XCTestCase {}

enum Color: String, EnumerableFlag {
  case pink
  case purple
  case silver
}

enum Size: String, EnumerableFlag {
  case small
  case medium
  case large
  case extraLarge
  case humongous
}

enum Shape: String, EnumerableFlag {
  case round
  case square
  case oblong
}

private struct Baz: ParsableCommand {
  @Flag var shape: Shape?

  @Flag var color: Color

  @Flag var size: Size
}

extension FlagInteractiveTests {
  func testParsing_CaseIterable() throws {
    AssertParseCommand(Baz.self, Baz.self, ["--pink"], lines: ["1"]) { options in
      XCTAssertEqual(options.shape, nil)
      XCTAssertEqual(options.color, .pink)
      XCTAssertEqual(options.size, .small)
    }

    AssertParseCommand(Baz.self, Baz.self, [], lines: ["1", "2"]) { options in
      XCTAssertEqual(options.shape, nil)
      XCTAssertEqual(options.color, .pink)
      XCTAssertEqual(options.size, .medium)
    }

    AssertParseCommand(Baz.self, Baz.self, ["--round"], lines: ["1", "1"]) { options in
      XCTAssertEqual(options.shape, .round)
      XCTAssertEqual(options.color, .pink)
      XCTAssertEqual(options.size, .small)
    }

    AssertParseCommand(Baz.self, Baz.self, ["--square"], lines: ["2", "2"]) { options in
      XCTAssertEqual(options.shape, .square)
      XCTAssertEqual(options.color, .purple)
      XCTAssertEqual(options.size, .medium)
    }

    AssertParseCommand(Baz.self, Baz.self, ["--oblong"], lines: ["3", "3"]) { options in
      XCTAssertEqual(options.shape, .oblong)
      XCTAssertEqual(options.color, .silver)
      XCTAssertEqual(options.size, .large)
    }
  }
}

private struct Qux: ParsableCommand {
  @Flag var color: [Color] = []

  @Flag var size: [Size]
}

extension FlagInteractiveTests {
  func testParsing_CaseIterableArray() throws {
    AssertParseCommand(Qux.self, Qux.self, [], lines: ["1 2"]) { options in
      XCTAssertEqual(options.color, [])
      XCTAssertEqual(options.size, [.small, .medium])
    }

    AssertParseCommand(Qux.self, Qux.self, ["--pink"], lines: ["1 2"]) { options in
      XCTAssertEqual(options.color, [.pink])
      XCTAssertEqual(options.size, [.small, .medium])
    }

    AssertParseCommand(Qux.self, Qux.self, ["--pink", "--purple"], lines: ["1"]) { options in
      XCTAssertEqual(options.color, [.pink, .purple])
      XCTAssertEqual(options.size, [.small])
    }

    AssertParseCommand(Qux.self, Qux.self, ["--pink", "--purple"], lines: ["1 2"]) { options in
      XCTAssertEqual(options.color, [.pink, .purple])
      XCTAssertEqual(options.size, [.small, .medium])
    }

    AssertParseCommand(Qux.self, Qux.self, ["--purple", "--pink"], lines: ["3 3"]) { options in
      XCTAssertEqual(options.color, [.purple, .pink])
      XCTAssertEqual(options.size, [.large, .large])
    }
  }
}

extension FlagInteractiveTests {
  func testParsing_InvalidValue() throws {
    AssertParseCommand(Baz.self, Baz.self, ["--pink"], lines: ["--small", "0", "6", "1"]) { options in
      XCTAssertEqual(options.shape, nil)
      XCTAssertEqual(options.color, .pink)
      XCTAssertEqual(options.size, .small)
    }

    AssertParseCommand(Baz.self, Baz.self, ["--pink"], lines: ["1 2"]) { options in
      XCTAssertEqual(options.shape, nil)
      XCTAssertEqual(options.color, .pink)
      XCTAssertEqual(options.size, .small)
    }

    AssertParseCommand(Baz.self, Baz.self, ["--pink"], lines: ["3 2 1"]) { options in
      XCTAssertEqual(options.shape, nil)
      XCTAssertEqual(options.color, .pink)
      XCTAssertEqual(options.size, .large)
    }

    AssertParseCommand(Qux.self, Qux.self, [], lines: ["1 0 2", "1 2"]) { options in
      XCTAssertEqual(options.color, [])
      XCTAssertEqual(options.size, [.small, .medium])
    }
  }
}
