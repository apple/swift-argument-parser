//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import XCTest
import ArgumentParserTestHelpers
import ArgumentParser

final class UnparsedValuesEndToEndTests: XCTestCase {}

// MARK: Two values + unparsed variable

fileprivate struct Qux: ParsableArguments {
  @Option() var name: String
  @Flag() var verbose = false
  var count = 0
}

fileprivate struct Quizzo: ParsableArguments {
  @Option() var name: String
  @Flag() var verbose = false
  let count = 0
}

extension UnparsedValuesEndToEndTests {
  func testParsing_TwoPlusUnparsed() throws {
    AssertParse(Qux.self, ["--name", "Qux"]) { qux in
      XCTAssertEqual(qux.name, "Qux")
      XCTAssertFalse(qux.verbose)
      XCTAssertEqual(qux.count, 0)
    }
    AssertParse(Qux.self, ["--name", "Qux", "--verbose"]) { qux in
      XCTAssertEqual(qux.name, "Qux")
      XCTAssertTrue(qux.verbose)
      XCTAssertEqual(qux.count, 0)
    }
    
    AssertParse(Quizzo.self, ["--name", "Qux", "--verbose"]) { quizzo in
      XCTAssertEqual(quizzo.name, "Qux")
      XCTAssertTrue(quizzo.verbose)
      XCTAssertEqual(quizzo.count, 0)
    }
  }
  
  func testParsing_TwoPlusUnparsed_Fails() throws {
    XCTAssertThrowsError(try Qux.parse([]))
    XCTAssertThrowsError(try Qux.parse(["--name"]))
    XCTAssertThrowsError(try Qux.parse(["--name", "Qux", "--count"]))
    XCTAssertThrowsError(try Qux.parse(["--name", "Qux", "--count", "2"]))
  }
}

// MARK: Nested unparsed decodable type


fileprivate struct Foo: ParsableCommand {
  @Flag var foo: Bool = false
  var config: Config?
  @OptionGroup var opt: OptionalArguments
  @OptionGroup var def: DefaultedArguments
}

fileprivate struct Config: Decodable {
  var name: String
  var age: Int
}

fileprivate struct OptionalArguments: ParsableArguments {
  @Argument var title: String?
  @Option var edition: Int?
}

fileprivate struct DefaultedArguments: ParsableArguments {
  @Option var one = 1
  @Option var two = 2
}

extension UnparsedValuesEndToEndTests {
  func testUnparsedNestedValues() {
    AssertParse(Foo.self, []) { foo in
      XCTAssertFalse(foo.foo)
      XCTAssertNil(foo.opt.title)
      XCTAssertNil(foo.opt.edition)
      XCTAssertEqual(1, foo.def.one)
      XCTAssertEqual(2, foo.def.two)
    }

    AssertParse(Foo.self, ["--foo", "--edition", "5", "Hello", "--one", "2", "--two", "1"]) { foo in
      XCTAssertTrue(foo.foo)
      XCTAssertEqual("Hello", foo.opt.title)
      XCTAssertEqual(5, foo.opt.edition)
      XCTAssertEqual(2, foo.def.one)
      XCTAssertEqual(1, foo.def.two)
    }
  }
  
  func testUnparsedNestedValues_Fails() {
    XCTAssertThrowsError(try Foo.parse(["--edition", "aaa"]))
    XCTAssertThrowsError(try Foo.parse(["--one", "aaa"]))
  }
}
