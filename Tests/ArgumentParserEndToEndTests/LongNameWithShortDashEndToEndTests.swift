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

import XCTest
import ArgumentParserTestHelpers
import ArgumentParser

final class LongNameWithSingleDashEndToEndTests: XCTestCase {
}

// MARK: -

fileprivate struct Bar: ParsableArguments {
  @Flag(name: .customLong("file", withSingleDash: true))
  var file: Bool = false

  @Flag(name: .short)
  var force: Bool = false

  @Flag(name: .short)
  var input: Bool = false
}

extension LongNameWithSingleDashEndToEndTests {
  func testParsing_empty() throws {
    AssertParse(Bar.self, []) { options in
      XCTAssertEqual(options.file, false)
      XCTAssertEqual(options.force, false)
      XCTAssertEqual(options.input, false)
    }
  }

  func testParsing_singleOption_1() {
    AssertParse(Bar.self, ["-file"]) { options in
      XCTAssertEqual(options.file, true)
      XCTAssertEqual(options.force, false)
      XCTAssertEqual(options.input, false)
    }
  }

  func testParsing_singleOption_2() {
    AssertParse(Bar.self, ["-f"]) { options in
      XCTAssertEqual(options.file, false)
      XCTAssertEqual(options.force, true)
      XCTAssertEqual(options.input, false)
    }
  }

  func testParsing_singleOption_3() {
    AssertParse(Bar.self, ["-i"]) { options in
      XCTAssertEqual(options.file, false)
      XCTAssertEqual(options.force, false)
      XCTAssertEqual(options.input, true)
    }
  }

  func testParsing_combined_1() {
    AssertParse(Bar.self, ["-f", "-i"]) { options in
      XCTAssertEqual(options.file, false)
      XCTAssertEqual(options.force, true)
      XCTAssertEqual(options.input, true)
    }
  }

  func testParsing_combined_2() {
    AssertParse(Bar.self, ["-fi"]) { options in
      XCTAssertEqual(options.file, false)
      XCTAssertEqual(options.force, true)
      XCTAssertEqual(options.input, true)
    }
  }

  func testParsing_combined_3() {
    AssertParse(Bar.self, ["-file", "-f"]) { options in
      XCTAssertEqual(options.file, true)
      XCTAssertEqual(options.force, true)
      XCTAssertEqual(options.input, false)
    }
  }

  func testParsing_combined_4() {
    AssertParse(Bar.self, ["-file", "-i"]) { options in
      XCTAssertEqual(options.file, true)
      XCTAssertEqual(options.force, false)
      XCTAssertEqual(options.input, true)
    }
  }

  func testParsing_combined_5() {
    AssertParse(Bar.self, ["-file", "-fi"]) { options in
      XCTAssertEqual(options.file, true)
      XCTAssertEqual(options.force, true)
      XCTAssertEqual(options.input, true)
    }
  }

  func testParsing_invalid() throws {
    //XCTAssertThrowsError(try Bar.parse(["-fil"]))
    XCTAssertThrowsError(try Bar.parse(["--file"]))
  }
}

fileprivate struct Foo: ParsableArguments {
  @Option(name: [.short])
  var optionOne: [Int] = []
  
  @Option(name: [
    .customShort("t"),
    .customLong("ot", withSingleDash: true),
    .customLong("TWO", withSingleDash: true),
  ], parsing: .upToNextOption)
  var optionTwo: [Int] = []
  
  @Argument()
  var extras: [Int] = []
}

extension LongNameWithSingleDashEndToEndTests {
  func testParsing_ArrayUpToNextOption() {
    AssertParse(Foo.self, ["-o", "1", "3", "-t", "2", "4"]) { foo in
      XCTAssertEqual(foo.optionOne, [1])
      XCTAssertEqual(foo.optionTwo, [2, 4])
      XCTAssertEqual(foo.extras, [3])
    }
    AssertParse(Foo.self, ["-o", "1", "3", "-ot", "2", "4"]) { foo in
      XCTAssertEqual(foo.optionOne, [1])
      XCTAssertEqual(foo.optionTwo, [2, 4])
      XCTAssertEqual(foo.extras, [3])
    }
    AssertParse(Foo.self, ["-o", "1", "3", "-TWO", "2", "4"]) { foo in
      XCTAssertEqual(foo.optionOne, [1])
      XCTAssertEqual(foo.optionTwo, [2, 4])
      XCTAssertEqual(foo.extras, [3])
    }
  }
}
