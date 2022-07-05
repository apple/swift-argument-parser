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

final class InteractiveTests: XCTestCase {}

private struct Repeat: ParsableCommand {
  @Option var count: Int

  @Flag var includeCounter = false

  @Argument var phrase: String
}

extension InteractiveTests {
  func testParsing_Repeat() throws {
    AssertParseCommand(Repeat.self, Repeat.self, ["a"], lines: ["2"]) { rep in
      XCTAssertEqual(rep.count, 2)
      XCTAssertEqual(rep.phrase, "a")
    }
    AssertParseCommand(Repeat.self, Repeat.self, ["--count", "3"], lines: ["b"]) { rep in
      XCTAssertEqual(rep.count, 3)
      XCTAssertEqual(rep.phrase, "b")
    }
    AssertParseCommand(Repeat.self, Repeat.self, [], lines: ["4", "c"]) { rep in
      XCTAssertEqual(rep.count, 4)
      XCTAssertEqual(rep.phrase, "c")
    }
    AssertParseCommand(Repeat.self, Repeat.self, ["d", "--count"], lines: ["5"]) { rep in
      XCTAssertEqual(rep.count, 5)
      XCTAssertEqual(rep.phrase, "d")
    }
    AssertParseCommand(Repeat.self, Repeat.self, ["--include-counter"], lines: ["6", "e"]) { rep in
      XCTAssertEqual(rep.count, 6)
      XCTAssertEqual(rep.phrase, "e")
      XCTAssertEqual(rep.includeCounter, true)
    }
    AssertParseCommand(Repeat.self, Repeat.self, ["f", "--count", "--include-counter"], lines: ["7"]) { rep in
      XCTAssertEqual(rep.count, 7)
      XCTAssertEqual(rep.phrase, "f")
      XCTAssertEqual(rep.includeCounter, true)
    }
    AssertParseCommand(Repeat.self, Repeat.self, ["--count", "--include-counter", "g"], lines: ["8"]) { rep in
      XCTAssertEqual(rep.count, 8)
      XCTAssertEqual(rep.phrase, "g")
      XCTAssertEqual(rep.includeCounter, true)
    }
    AssertParseCommand(Repeat.self, Repeat.self, ["--count", "9", "--include-counter", "h"]) { rep in
      XCTAssertEqual(rep.count, 9)
      XCTAssertEqual(rep.phrase, "h")
      XCTAssertEqual(rep.includeCounter, true)
    }
  }
}
