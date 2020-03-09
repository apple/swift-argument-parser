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

final class EnumEndToEndTests: XCTestCase {
}

// MARK: -

fileprivate struct Bar: ParsableArguments {
  enum Index: String, Equatable, ExpressibleByArgument {
    case hello
    case goodbye
  }
  
  @Option()
  var index: Index
}

extension EnumEndToEndTests {
  func testParsing_SingleOption() throws {
    AssertParse(Bar.self, ["--index", "hello"]) { bar in
      XCTAssertEqual(bar.index, Bar.Index.hello)
    }
    AssertParse(Bar.self, ["--index", "goodbye"]) { bar in
      XCTAssertEqual(bar.index, Bar.Index.goodbye)
    }
  }
  
  func testParsing_SingleOptionMultipleTimes() throws {
    AssertParse(Bar.self, ["--index", "hello", "--index", "goodbye"]) { bar in
      XCTAssertEqual(bar.index, Bar.Index.goodbye)
    }
  }
  
  func testParsing_SingleOption_Fails() throws {
    XCTAssertThrowsError(try Bar.parse([]))
    XCTAssertThrowsError(try Bar.parse(["--index"]))
    XCTAssertThrowsError(try Bar.parse(["--index", "hell"]))
    XCTAssertThrowsError(try Bar.parse(["--index", "helloo"]))
  }
}
