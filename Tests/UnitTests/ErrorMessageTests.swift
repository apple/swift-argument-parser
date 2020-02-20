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
import TestHelpers
@testable import ArgumentParser

final class ErrorMessageTests: XCTestCase {}

// MARK: -

fileprivate struct Bar: ParsableArguments {
  @Option() var name: String
  @Option(name: [.short, .long]) var format: String
}

extension ErrorMessageTests {
  func testMissing_1() {
    AssertErrorMessage(Bar.self, [], "Missing expected argument '--name <name>'")
  }
  
  func testMissing_2() {
    AssertErrorMessage(Bar.self, ["--name", "a"], "Missing expected argument '--format <format>'")
  }
  
  func testUnknownOption_1() {
    AssertErrorMessage(Bar.self, ["--name", "a", "--format", "b", "--verbose"], "Unexpected argument '--verbose'")
  }
  
  func testUnknownOption_2() {
    AssertErrorMessage(Bar.self, ["--name", "a", "--format", "b", "-q"], "Unexpected argument '-q'")
  }
  
  func testUnknownOption_3() {
    AssertErrorMessage(Bar.self, ["--name", "a", "--format", "b", "-bar"], "Unexpected argument '-bar'")
  }
  
  func testUnknownOption_4() {
    AssertErrorMessage(Bar.self, ["--name", "a", "-foz", "b"], "2 unexpected arguments: '-o', '-z'")
  }
  
  func testMissingValue_1() {
    AssertErrorMessage(Bar.self, ["--name", "a", "--format"], "Missing value for '--format <format>'")
  }
  
  func testMissingValue_2() {
    AssertErrorMessage(Bar.self, ["--name", "a", "-f"], "Missing value for '-f <format>'")
  }
  
  func testUnusedValue_1() {
    AssertErrorMessage(Bar.self, ["--name", "a", "--format", "f", "b"], "Unexpected argument 'b'")
  }
  
  func testUnusedValue_2() {
    AssertErrorMessage(Bar.self, ["--name", "a", "--format", "f", "b", "baz"], "2 unexpected arguments: 'b', 'baz'")
  }
}

fileprivate struct Foo: ParsableArguments {
  enum Format: String, Equatable, Decodable, ExpressibleByArgument {
    case text
    case json
  }
  @Option(name: [.short, .long])
  var format: Format
}

extension ErrorMessageTests {
  func testWrongEnumValue() {
    AssertErrorMessage(Foo.self, ["--format", "png"], "The value 'png' is invalid for '--format <format>'")
    AssertErrorMessage(Foo.self, ["-f", "png"], "The value 'png' is invalid for '-f <format>'")
  }
}

fileprivate struct Baz: ParsableArguments {
  @Flag()
  var verbose: Bool
}

extension ErrorMessageTests {
  func testUnexpectedValue() {
    AssertErrorMessage(Baz.self, ["--verbose=foo"], "The option '--verbose' does not take any value, but 'foo' was specified.")
  }
}

fileprivate struct Qux: ParsableArguments {
  @Argument()
  var firstNumber: Int
  
  @Option(name: .customLong("number-two"))
  var secondNumber: Int
}

extension ErrorMessageTests {
  func testMissingArgument() {
    AssertErrorMessage(Qux.self, ["--number-two", "2"], "Missing expected argument '<first-number>'")
  }
  
  func testInvalidNumber() {
    AssertErrorMessage(Qux.self, ["--number-two", "2", "a"], "The value 'a' is invalid for '<first-number>'")
    AssertErrorMessage(Qux.self, ["--number-two", "a", "1"], "The value 'a' is invalid for '--number-two <number-two>'")
  }
}
