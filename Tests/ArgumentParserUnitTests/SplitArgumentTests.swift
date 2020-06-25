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
@testable import ArgumentParser
import ArgumentParserTestHelpers

extension SplitArguments.InputIndex: ExpressibleByIntegerLiteral {
  public init(integerLiteral value: Int) {
    self.init(rawValue: value)
  }
}

private func AssertIndexEqual(_ sut: SplitArguments, at index: Int, inputIndex: Int, subIndex: SplitArguments.SubIndex, file: StaticString = #file, line: UInt = #line) {
  guard index < sut.elements.count else {
    XCTFail("Element index \(index) is out of range. sur only has \(sut.elements.count) elements.", file: (file), line: line)
    return
  }
  let splitIndex = sut.elements[index].0
  let expected = SplitArguments.Index(inputIndex: SplitArguments.InputIndex(rawValue: inputIndex), subIndex: subIndex)
  if splitIndex.inputIndex != expected.inputIndex {
    XCTFail("inputIndex does not match: \(splitIndex.inputIndex.rawValue) != \(expected.inputIndex.rawValue)", file: (file), line: line)
  }
  if splitIndex.subIndex != expected.subIndex {
    XCTFail("inputIndex does not match: \(splitIndex.subIndex) != \(expected.subIndex)", file: (file), line: line)
  }
}

private func AssertElementEqual(_ sut: SplitArguments, at index: Int, _ element: SplitArguments.Element, file: StaticString = #file, line: UInt = #line) {
  guard index < sut.elements.count else {
    XCTFail("Element index \(index) is out of range. sur only has \(sut.elements.count) elements.", file: (file), line: line)
    return
  }
  XCTAssertEqual(sut.elements[index].1, element, file: (file), line: line)
}

final class SplitArgumentTests: XCTestCase {
  func testEmpty() throws {
    let sut = try SplitArguments(arguments: [])
    XCTAssertEqual(sut.elements.count, 0)
    XCTAssertEqual(sut.originalInput.count, 0)
  }
  
  func testSingleValue() throws {
    let sut = try SplitArguments(arguments: ["abc"])
    
    XCTAssertEqual(sut.elements.count, 1)
    AssertIndexEqual(sut, at: 0, inputIndex: 0, subIndex: .complete)
    AssertElementEqual(sut, at: 0, .value("abc"))
    
    XCTAssertEqual(sut.originalInput.count, 1)
    XCTAssertEqual(sut.originalInput, ["abc"])
  }
  
  func testSingleLongOption() throws {
    let sut = try SplitArguments(arguments: ["--abc"])
    
    XCTAssertEqual(sut.elements.count, 1)
    AssertIndexEqual(sut, at: 0, inputIndex: 0, subIndex: .complete)
    AssertElementEqual(sut, at: 0, .option(.name(.long("abc"))))
    
    XCTAssertEqual(sut.originalInput.count, 1)
    XCTAssertEqual(sut.originalInput, ["--abc"])
  }
  
  func testSingleShortOption() throws {
    let sut = try SplitArguments(arguments: ["-a"])
    
    XCTAssertEqual(sut.elements.count, 1)
    AssertIndexEqual(sut, at: 0, inputIndex: 0, subIndex: .complete)
    AssertElementEqual(sut, at: 0, .option(.name(.short("a"))))
    
    XCTAssertEqual(sut.originalInput.count, 1)
    XCTAssertEqual(sut.originalInput, ["-a"])
  }
  
  func testSingleLongOptionWithValue() throws {
    let sut = try SplitArguments(arguments: ["--abc=def"])
    
    XCTAssertEqual(sut.elements.count, 1)
    AssertIndexEqual(sut, at: 0, inputIndex: 0, subIndex: .complete)
    AssertElementEqual(sut, at: 0, .option(.nameWithValue(.long("abc"), "def")))
    
    XCTAssertEqual(sut.originalInput.count, 1)
    XCTAssertEqual(sut.originalInput, ["--abc=def"])
  }
  
  func testMultipleShortOptionsCombined() throws {
    let sut = try SplitArguments(arguments: ["-abc"])
    
    XCTAssertEqual(sut.elements.count, 4)
    
    AssertIndexEqual(sut, at: 0, inputIndex: 0, subIndex: .complete)
    AssertElementEqual(sut, at: 0, .option(.name(.longWithSingleDash("abc"))))
    
    AssertIndexEqual(sut, at: 1, inputIndex: 0, subIndex: .sub(0))
    AssertElementEqual(sut, at: 1, .option(.name(.short("a"))))
    
    AssertIndexEqual(sut, at: 2, inputIndex: 0, subIndex: .sub(1))
    AssertElementEqual(sut, at: 2, .option(.name(.short("b"))))
    
    AssertIndexEqual(sut, at: 3, inputIndex: 0, subIndex: .sub(2))
    AssertElementEqual(sut, at: 3, .option(.name(.short("c"))))
    
    XCTAssertEqual(sut.originalInput.count, 1)
    XCTAssertEqual(sut.originalInput, ["-abc"])
  }
  
  func testSingleLongOptionWithValueAndSingleDash() throws {
    let sut = try SplitArguments(arguments: ["-abc=def"])
    
    XCTAssertEqual(sut.elements.count, 1)
    
    AssertIndexEqual(sut, at: 0, inputIndex: 0, subIndex: .complete)
    AssertElementEqual(sut, at: 0, .option(.nameWithValue(.longWithSingleDash("abc"), "def")))
    
    XCTAssertEqual(sut.originalInput.count, 1)
    XCTAssertEqual(sut.originalInput, ["-abc=def"])
  }
  
  func testNegativeOrSingleOption() throws {
    let sut = try SplitArguments(arguments: ["-1"])
    
    XCTAssertEqual(sut.elements.count, 1)
    
    AssertIndexEqual(sut, at: 0, inputIndex: 0, subIndex: .complete)
    AssertElementEqual(sut, at: 0, .possibleNegative(value: "-1", option: .name(.short("1"))))
    
    XCTAssertEqual(sut.originalInput.count, 1)
    XCTAssertEqual(sut.originalInput, ["-1"])
  }
  
  func testNegativeOrMultipleOptions() throws {
    let sut = try SplitArguments(arguments: ["-12"])
    
    XCTAssertEqual(sut.elements.count, 3)
    
    AssertIndexEqual(sut, at: 0, inputIndex: 0, subIndex: .complete)
    AssertElementEqual(sut, at: 0, .possibleNegative(value: "-12", option: .name(.longWithSingleDash("12"))))
    
    AssertIndexEqual(sut, at: 1, inputIndex: 0, subIndex: .sub(0))
    AssertElementEqual(sut, at: 1, .option(.name(.short("1"))))
    
    AssertIndexEqual(sut, at: 2, inputIndex: 0, subIndex: .sub(1))
    AssertElementEqual(sut, at: 2, .option(.name(.short("2"))))
    
    XCTAssertEqual(sut.originalInput.count, 1)
    XCTAssertEqual(sut.originalInput, ["-12"])
  }
  
  func testNegativeOrShortOptionWithValue() throws {
    let sut = try SplitArguments(arguments: ["-1=-23"])
    
    XCTAssertEqual(sut.elements.count, 1)
    
    AssertIndexEqual(sut, at: 0, inputIndex: 0, subIndex: .complete)
    AssertElementEqual(sut, at: 0, .option(.nameWithValue(.short("1"), "-23")))
    
    XCTAssertEqual(sut.originalInput.count, 1)
    XCTAssertEqual(sut.originalInput, ["-1=-23"])
  }
  
  func testNegativeOrLongOptionWithValueAndSingleDash() throws {
    let sut = try SplitArguments(arguments: ["-12=-34"])
    
    XCTAssertEqual(sut.elements.count, 1)
    
    AssertIndexEqual(sut, at: 0, inputIndex: 0, subIndex: .complete)
    AssertElementEqual(sut, at: 0, .option(.nameWithValue(.longWithSingleDash("12"), "-34")))
    
    XCTAssertEqual(sut.originalInput.count, 1)
    XCTAssertEqual(sut.originalInput, ["-12=-34"])
  }
}

extension SplitArgumentTests {
  func testMultipleValues() throws {
    let sut = try SplitArguments(arguments: ["abc", "x", "1234"])
    
    XCTAssertEqual(sut.elements.count, 3)
    
    AssertIndexEqual(sut, at: 0, inputIndex: 0, subIndex: .complete)
    AssertElementEqual(sut, at: 0, .value("abc"))
    
    AssertIndexEqual(sut, at: 1, inputIndex: 1, subIndex: .complete)
    AssertElementEqual(sut, at: 1, .value("x"))
    
    AssertIndexEqual(sut, at: 2, inputIndex: 2, subIndex: .complete)
    AssertElementEqual(sut, at: 2, .value("1234"))
    
    XCTAssertEqual(sut.originalInput.count, 3)
    XCTAssertEqual(sut.originalInput, ["abc", "x", "1234"])
  }
  
  func testMultipleLongOptions() throws {
    let sut = try SplitArguments(arguments: ["--d", "--1", "--abc-def"])
    
    XCTAssertEqual(sut.elements.count, 3)
    
    AssertIndexEqual(sut, at: 0, inputIndex: 0, subIndex: .complete)
    AssertElementEqual(sut, at: 0, .option(.name(.long("d"))))
    
    AssertIndexEqual(sut, at: 1, inputIndex: 1, subIndex: .complete)
    AssertElementEqual(sut, at: 1, .option(.name(.long("1"))))
    
    AssertIndexEqual(sut, at: 2, inputIndex: 2, subIndex: .complete)
    AssertElementEqual(sut, at: 2, .option(.name(.long("abc-def"))))
    
    XCTAssertEqual(sut.originalInput.count, 3)
    XCTAssertEqual(sut.originalInput, ["--d", "--1", "--abc-def"])
  }
  
  func testMultipleShortOptions() throws {
    let sut = try SplitArguments(arguments: ["-x", "-y", "-z"])
    
    XCTAssertEqual(sut.elements.count, 3)
    
    AssertIndexEqual(sut, at: 0, inputIndex: 0, subIndex: .complete)
    AssertElementEqual(sut, at: 0, .option(.name(.short("x"))))
    
    AssertIndexEqual(sut, at: 1, inputIndex: 1, subIndex: .complete)
    AssertElementEqual(sut, at: 1, .option(.name(.short("y"))))
    
    AssertIndexEqual(sut, at: 2, inputIndex: 2, subIndex: .complete)
    AssertElementEqual(sut, at: 2, .option(.name(.short("z"))))
    
    XCTAssertEqual(sut.originalInput.count, 3)
    XCTAssertEqual(sut.originalInput, ["-x", "-y", "-z"])
  }
  
  func testMultiplePossibleNegatives() throws {
    let sut = try SplitArguments(arguments: ["-1", "-2"])
    
    XCTAssertEqual(sut.elements.count, 2)
    
    AssertIndexEqual(sut, at: 0, inputIndex: 0, subIndex: .complete)
    AssertElementEqual(sut, at: 0, .possibleNegative(value: "-1", option: .name(.short("1"))))
    
    AssertIndexEqual(sut, at: 1, inputIndex: 1, subIndex: .complete)
    AssertElementEqual(sut, at: 1, .possibleNegative(value: "-2", option: .name(.short("2"))))
    
    XCTAssertEqual(sut.originalInput.count, 2)
    XCTAssertEqual(sut.originalInput, ["-1", "-2"])
  }
  
  func testMultiplePossibleNegatives_2() throws {
    let sut = try SplitArguments(arguments: ["-12", "-34"])
    
    XCTAssertEqual(sut.elements.count, 6)
    
    AssertIndexEqual(sut, at: 0, inputIndex: 0, subIndex: .complete)
    AssertElementEqual(sut, at: 0, .possibleNegative(value: "-12", option: .name(.longWithSingleDash("12"))))
    
    AssertIndexEqual(sut, at: 1, inputIndex: 0, subIndex: .sub(0))
    AssertElementEqual(sut, at: 1, .option(.name(.short("1"))))
    
    AssertIndexEqual(sut, at: 2, inputIndex: 0, subIndex: .sub(1))
    AssertElementEqual(sut, at: 2, .option(.name(.short("2"))))
    
    AssertIndexEqual(sut, at: 3, inputIndex: 1, subIndex: .complete)
    AssertElementEqual(sut, at: 3, .possibleNegative(value: "-34", option: .name(.longWithSingleDash("34"))))
    
    AssertIndexEqual(sut, at: 4, inputIndex: 1, subIndex: .sub(0))
    AssertElementEqual(sut, at: 4, .option(.name(.short("3"))))
    
    AssertIndexEqual(sut, at: 5, inputIndex: 1, subIndex: .sub(1))
    AssertElementEqual(sut, at: 5, .option(.name(.short("4"))))
    
    XCTAssertEqual(sut.originalInput.count, 2)
    XCTAssertEqual(sut.originalInput, ["-12", "-34"])
  }
  
  func testMultipleShortOptionsCombined_2() throws {
    let sut = try SplitArguments(arguments: ["-bc", "-fv", "-a"])
    
    XCTAssertEqual(sut.elements.count, 7)
    
    AssertIndexEqual(sut, at: 0, inputIndex: 0, subIndex: .complete)
    AssertElementEqual(sut, at: 0, .option(.name(.longWithSingleDash("bc"))))
    
    AssertIndexEqual(sut, at: 1, inputIndex: 0, subIndex: .sub(0))
    AssertElementEqual(sut, at: 1, .option(.name(.short("b"))))
    
    AssertIndexEqual(sut, at: 2, inputIndex: 0, subIndex: .sub(1))
    AssertElementEqual(sut, at: 2, .option(.name(.short("c"))))
    
    AssertIndexEqual(sut, at: 3, inputIndex: 1, subIndex: .complete)
    AssertElementEqual(sut, at: 3, .option(.name(.longWithSingleDash("fv"))))
    
    AssertIndexEqual(sut, at: 4, inputIndex: 1, subIndex: .sub(0))
    AssertElementEqual(sut, at: 4, .option(.name(.short("f"))))
    
    AssertIndexEqual(sut, at: 5, inputIndex: 1, subIndex: .sub(1))
    AssertElementEqual(sut, at: 5, .option(.name(.short("v"))))
    
    AssertIndexEqual(sut, at: 6, inputIndex: 2, subIndex: .complete)
    AssertElementEqual(sut, at: 6, .option(.name(.short("a"))))
    
    XCTAssertEqual(sut.originalInput.count, 3)
    XCTAssertEqual(sut.originalInput, ["-bc", "-fv", "-a"])
  }
}

extension SplitArgumentTests {
  func testMixed_1() throws {
    let sut = try SplitArguments(arguments: ["-x", "abc", "--foo", "1234", "-zz", "-12"])
    
    XCTAssertEqual(sut.elements.count, 10)
    
    AssertIndexEqual(sut, at: 0, inputIndex: 0, subIndex: .complete)
    AssertElementEqual(sut, at: 0, .option(.name(.short("x"))))
    
    AssertIndexEqual(sut, at: 1, inputIndex: 1, subIndex: .complete)
    AssertElementEqual(sut, at: 1, .value("abc"))
    
    AssertIndexEqual(sut, at: 2, inputIndex: 2, subIndex: .complete)
    AssertElementEqual(sut, at: 2, .option(.name(.long("foo"))))
    
    AssertIndexEqual(sut, at: 3, inputIndex: 3, subIndex: .complete)
    AssertElementEqual(sut, at: 3, .value("1234"))
    
    AssertIndexEqual(sut, at: 4, inputIndex: 4, subIndex: .complete)
    AssertElementEqual(sut, at: 4, .option(.name(.longWithSingleDash("zz"))))
    
    AssertIndexEqual(sut, at: 5, inputIndex: 4, subIndex: .sub(0))
    AssertElementEqual(sut, at: 5, .option(.name(.short("z"))))
    
    AssertIndexEqual(sut, at: 6, inputIndex: 4, subIndex: .sub(1))
    AssertElementEqual(sut, at: 6, .option(.name(.short("z"))))
    
    AssertIndexEqual(sut, at: 7, inputIndex: 5, subIndex: .complete)
    AssertElementEqual(sut, at: 7, .possibleNegative(value: "-12", option: .name(.longWithSingleDash("12"))))
    
    AssertIndexEqual(sut, at: 8, inputIndex: 5, subIndex: .sub(0))
    AssertElementEqual(sut, at: 8, .option(.name(.short("1"))))
    
    AssertIndexEqual(sut, at: 9, inputIndex: 5, subIndex: .sub(1))
    AssertElementEqual(sut, at: 9, .option(.name(.short("2"))))
    
    XCTAssertEqual(sut.originalInput.count, 6)
    XCTAssertEqual(sut.originalInput, ["-x", "abc", "--foo", "1234", "-zz", "-12"])
  }
  
  func testMixed_2() throws {
    let sut = try SplitArguments(arguments: ["1234", "-12", "-zz", "abc", "-x", "--foo"])
    
    XCTAssertEqual(sut.elements.count, 10)
    
    AssertIndexEqual(sut, at: 0, inputIndex: 0, subIndex: .complete)
    AssertElementEqual(sut, at: 0, .value("1234"))
    
    AssertIndexEqual(sut, at: 1, inputIndex: 1, subIndex: .complete)
    AssertElementEqual(sut, at: 1, .possibleNegative(value: "-12", option: .name(.longWithSingleDash("12"))))
    
    AssertIndexEqual(sut, at: 2, inputIndex: 1, subIndex: .sub(0))
    AssertElementEqual(sut, at: 2, .option(.name(.short("1"))))
    
    AssertIndexEqual(sut, at: 3, inputIndex: 1, subIndex: .sub(1))
    AssertElementEqual(sut, at: 3, .option(.name(.short("2"))))
    
    AssertIndexEqual(sut, at: 4, inputIndex: 2, subIndex: .complete)
    AssertElementEqual(sut, at: 4, .option(.name(.longWithSingleDash("zz"))))
    
    AssertIndexEqual(sut, at: 5, inputIndex: 2, subIndex: .sub(0))
    AssertElementEqual(sut, at: 5, .option(.name(.short("z"))))
    
    AssertIndexEqual(sut, at: 6, inputIndex: 2, subIndex: .sub(1))
    AssertElementEqual(sut, at: 6, .option(.name(.short("z"))))
    
    AssertIndexEqual(sut, at: 7, inputIndex: 3, subIndex: .complete)
    AssertElementEqual(sut, at: 7, .value("abc"))
    
    AssertIndexEqual(sut, at: 8, inputIndex: 4, subIndex: .complete)
    AssertElementEqual(sut, at: 8, .option(.name(.short("x"))))
    
    AssertIndexEqual(sut, at: 9, inputIndex: 5, subIndex: .complete)
    AssertElementEqual(sut, at: 9, .option(.name(.long("foo"))))
    
    XCTAssertEqual(sut.originalInput.count, 6)
    XCTAssertEqual(sut.originalInput, ["1234", "-12", "-zz", "abc", "-x", "--foo"])
  }
  
  func testTerminator_1() throws {
    let sut = try SplitArguments(arguments: ["--foo", "--", "--bar"])
    
    XCTAssertEqual(sut.elements.count, 3)
    
    AssertIndexEqual(sut, at: 0, inputIndex: 0, subIndex: .complete)
    AssertElementEqual(sut, at: 0, .option(.name(.long("foo"))))
    
    AssertIndexEqual(sut, at: 1, inputIndex: 1, subIndex: .complete)
    AssertElementEqual(sut, at: 1, .terminator)
    
    AssertIndexEqual(sut, at: 2, inputIndex: 2, subIndex: .complete)
    AssertElementEqual(sut, at: 2, .value("--bar"))
    
    XCTAssertEqual(sut.originalInput.count, 3)
    XCTAssertEqual(sut.originalInput, ["--foo", "--", "--bar"])
  }
  
  func testTerminator_2() throws {
    let sut = try SplitArguments(arguments: ["--foo", "--", "bar"])
    
    XCTAssertEqual(sut.elements.count, 3)
    
    AssertIndexEqual(sut, at: 0, inputIndex: 0, subIndex: .complete)
    AssertElementEqual(sut, at: 0, .option(.name(.long("foo"))))
    
    AssertIndexEqual(sut, at: 1, inputIndex: 1, subIndex: .complete)
    AssertElementEqual(sut, at: 1, .terminator)
    
    AssertIndexEqual(sut, at: 2, inputIndex: 2, subIndex: .complete)
    AssertElementEqual(sut, at: 2, .value("bar"))
    
    XCTAssertEqual(sut.originalInput.count, 3)
    XCTAssertEqual(sut.originalInput, ["--foo", "--", "bar"])
  }
  
  func testTerminator_3() throws {
    let sut = try SplitArguments(arguments: ["--foo", "--", "--bar=baz"])
    
    XCTAssertEqual(sut.elements.count, 3)
    
    AssertIndexEqual(sut, at: 0, inputIndex: 0, subIndex: .complete)
    AssertElementEqual(sut, at: 0, .option(.name(.long("foo"))))
    
    AssertIndexEqual(sut, at: 1, inputIndex: 1, subIndex: .complete)
    AssertElementEqual(sut, at: 1, .terminator)
    
    AssertIndexEqual(sut, at: 2, inputIndex: 2, subIndex: .complete)
    AssertElementEqual(sut, at: 2, .value("--bar=baz"))
    
    XCTAssertEqual(sut.originalInput.count, 3)
    XCTAssertEqual(sut.originalInput, ["--foo", "--", "--bar=baz"])
  }
  
  func testTerminatorAtTheEnd() throws {
    let sut = try SplitArguments(arguments: ["--foo", "--"])
    
    XCTAssertEqual(sut.elements.count, 2)
    
    AssertIndexEqual(sut, at: 0, inputIndex: 0, subIndex: .complete)
    AssertElementEqual(sut, at: 0, .option(.name(.long("foo"))))
    
    AssertIndexEqual(sut, at: 1, inputIndex: 1, subIndex: .complete)
    AssertElementEqual(sut, at: 1, .terminator)
    
    XCTAssertEqual(sut.originalInput.count, 2)
    XCTAssertEqual(sut.originalInput, ["--foo", "--"])
  }
  
  func testTerminatorAtTheBeginning() throws {
    let sut = try SplitArguments(arguments: ["--", "--foo"])
    
    XCTAssertEqual(sut.elements.count, 2)
    
    AssertIndexEqual(sut, at: 0, inputIndex: 0, subIndex: .complete)
    AssertElementEqual(sut, at: 0, .terminator)
    
    AssertIndexEqual(sut, at: 1, inputIndex: 1, subIndex: .complete)
    AssertElementEqual(sut, at: 1, .value("--foo"))
    
    XCTAssertEqual(sut.originalInput.count, 2)
    XCTAssertEqual(sut.originalInput, ["--", "--foo"])
  }
}

// MARK: - Removing Entries

extension SplitArgumentTests {
  func testRemovingValuesForLongNames() throws {
    var sut = try SplitArguments(arguments: ["--foo", "--bar"])
    XCTAssertEqual(sut.elements.count, 2)
    sut.remove(at: SplitArguments.Index(inputIndex: 0, subIndex: .complete))
    XCTAssertEqual(sut.elements.count, 1)
    sut.remove(at: SplitArguments.Index(inputIndex: 1, subIndex: .complete))
    XCTAssertEqual(sut.elements.count, 0)
  }
  
  func testRemovingValuesForLongNamesWithValue() throws {
    var sut = try SplitArguments(arguments: ["--foo=A", "--bar=B"])
    XCTAssertEqual(sut.elements.count, 2)
    sut.remove(at: SplitArguments.Index(inputIndex: 0, subIndex: .complete))
    XCTAssertEqual(sut.elements.count, 1)
    sut.remove(at: SplitArguments.Index(inputIndex: 1, subIndex: .complete))
    XCTAssertEqual(sut.elements.count, 0)
  }
  
  func testRemovingValuesForShortNames() throws {
    var sut = try SplitArguments(arguments: ["-f", "-b"])
    XCTAssertEqual(sut.elements.count, 2)
    sut.remove(at: SplitArguments.Index(inputIndex: 0, subIndex: .complete))
    XCTAssertEqual(sut.elements.count, 1)
    sut.remove(at: SplitArguments.Index(inputIndex: 1, subIndex: .complete))
    XCTAssertEqual(sut.elements.count, 0)
  }
  
  func testRemovingValuesForCombinedShortNames() throws {
    let sut = try SplitArguments(arguments: ["-fb"])
    
    XCTAssertEqual(sut.elements.count, 3)
    AssertIndexEqual(sut, at: 0, inputIndex: 0, subIndex: .complete)
    AssertElementEqual(sut, at: 0, .option(.name(.longWithSingleDash("fb"))))
    AssertIndexEqual(sut, at: 1, inputIndex: 0, subIndex: .sub(0))
    AssertElementEqual(sut, at: 1, .option(.name(.short("f"))))
    AssertIndexEqual(sut, at: 2, inputIndex: 0, subIndex: .sub(1))
    AssertElementEqual(sut, at: 2, .option(.name(.short("b"))))
    
    do {
      var sutB = sut
      sutB.remove(at: SplitArguments.Index(inputIndex: 0, subIndex: .complete))
      
      XCTAssertEqual(sutB.elements.count, 0)
    }
    do {
      var sutB = sut
      sutB.remove(at: SplitArguments.Index(inputIndex: 0, subIndex: .sub(0)))
      
      XCTAssertEqual(sutB.elements.count, 1)
      AssertIndexEqual(sutB, at: 0, inputIndex: 0, subIndex: .sub(1))
      AssertElementEqual(sutB, at: 0, .option(.name(.short("b"))))
    }
    do {
      var sutB = sut
      sutB.remove(at: SplitArguments.Index(inputIndex: 0, subIndex: .sub(1)))
      
      XCTAssertEqual(sutB.elements.count, 1)
      AssertIndexEqual(sutB, at: 0, inputIndex: 0, subIndex: .sub(0))
      AssertElementEqual(sutB, at: 0, .option(.name(.short("f"))))
    }
  }
  
  func testRemovingValuesForPossibleNegative() throws {
    let sut = try SplitArguments(arguments: ["-12"])
    
    XCTAssertEqual(sut.elements.count, 3)
    AssertIndexEqual(sut, at: 0, inputIndex: 0, subIndex: .complete)
    AssertElementEqual(sut, at: 0, .possibleNegative(value: "-12", option: .name(.longWithSingleDash("12"))))
    AssertIndexEqual(sut, at: 1, inputIndex: 0, subIndex: .sub(0))
    AssertElementEqual(sut, at: 1, .option(.name(.short("1"))))
    AssertIndexEqual(sut, at: 2, inputIndex: 0, subIndex: .sub(1))
    AssertElementEqual(sut, at: 2, .option(.name(.short("2"))))
    
    do {
      var sutB = sut
      sutB.remove(at: SplitArguments.Index(inputIndex: 0, subIndex: .complete))
      
      XCTAssertEqual(sutB.elements.count, 0)
    }
    do {
      var sutB = sut
      sutB.remove(at: SplitArguments.Index(inputIndex: 0, subIndex: .sub(0)))
      
      XCTAssertEqual(sutB.elements.count, 1)
      AssertIndexEqual(sutB, at: 0, inputIndex: 0, subIndex: .sub(1))
      AssertElementEqual(sutB, at: 0, .option(.name(.short("2"))))
    }
    do {
      var sutB = sut
      sutB.remove(at: SplitArguments.Index(inputIndex: 0, subIndex: .sub(1)))
      
      XCTAssertEqual(sutB.elements.count, 1)
      AssertIndexEqual(sutB, at: 0, inputIndex: 0, subIndex: .sub(0))
      AssertElementEqual(sutB, at: 0, .option(.name(.short("1"))))
    }
  }
}

// MARK: - Pop & Peek

extension SplitArgumentTests {
  func testPopNext() throws {
    var sut = try SplitArguments(arguments: ["--foo", "bar", "-12"])
    
    let a = try XCTUnwrap(sut.popNext())
    XCTAssertEqual(a.0, .argumentIndex(SplitArguments.Index(inputIndex: 0, subIndex: .complete)))
    XCTAssertEqual(a.1, .option(.name(.long("foo"))))
    
    let b = try XCTUnwrap(sut.popNext())
    XCTAssertEqual(b.0, .argumentIndex(SplitArguments.Index(inputIndex: 1, subIndex: .complete)))
    XCTAssertEqual(b.1, .value("bar"))
    
    let c = try XCTUnwrap(sut.popNext())
    XCTAssertEqual(c.0, .argumentIndex(SplitArguments.Index(inputIndex: 2, subIndex: .complete)))
    XCTAssertEqual(c.1, .possibleNegative(value: "-12", option: .name(.longWithSingleDash("12"))))
    
    let d = try XCTUnwrap(sut.popNext())
    XCTAssertEqual(d.0, .argumentIndex(SplitArguments.Index(inputIndex: 2, subIndex: .sub(0))))
    XCTAssertEqual(d.1, .option(.name(.short("1"))))
    
    let e = try XCTUnwrap(sut.popNext())
    XCTAssertEqual(e.0, .argumentIndex(SplitArguments.Index(inputIndex: 2, subIndex: .sub(1))))
    XCTAssertEqual(e.1, .option(.name(.short("2"))))
    
    XCTAssertNil(sut.popNext())
  }
  
  func testPeekNext() throws {
    let sut = try SplitArguments(arguments: ["--foo", "bar", "-12"])
    
    let a = try XCTUnwrap(sut.peekNext())
    XCTAssertEqual(a.0, .argumentIndex(SplitArguments.Index(inputIndex: 0, subIndex: .complete)))
    XCTAssertEqual(a.1, .option(.name(.long("foo"))))
    
    let b = try XCTUnwrap(sut.peekNext())
    XCTAssertEqual(b.0, .argumentIndex(SplitArguments.Index(inputIndex: 0, subIndex: .complete)))
    XCTAssertEqual(b.1, .option(.name(.long("foo"))))
  }
  
  func testPeekNextWhenEmpty() throws {
    let sut = try SplitArguments(arguments: [])
    XCTAssertNil(sut.peekNext())
  }
  
  func testPopNextElementIfValueAfter_1() throws {
    var sut = try SplitArguments(arguments: ["--bar", "bar", "-12", "--foo", "foo"])
    
    let value = try XCTUnwrap(sut.popNextElementIfValue(after: .argumentIndex(SplitArguments.Index(inputIndex: 0, subIndex: .complete))))
    XCTAssertEqual(value.0, .argumentIndex(SplitArguments.Index(inputIndex: 1, subIndex: .complete)))
    XCTAssertEqual(value.1, "bar")
  }
  
  func testPopNextElementIfValueAfter_2() throws {
    var sut = try SplitArguments(arguments: ["--bar", "bar", "-12", "--foo", "foo"])
    
    let value = try XCTUnwrap(sut.popNextElementIfValue(after: .argumentIndex(SplitArguments.Index(inputIndex: 1, subIndex: .complete))))
    XCTAssertEqual(value.0, .argumentIndex(SplitArguments.Index(inputIndex: 2, subIndex: .complete)))
    XCTAssertEqual(value.1, "-12")
  }
  
  func testPopNextElementIfValueAfter_3() throws {
    var sut = try SplitArguments(arguments: ["--bar", "bar", "-12", "--foo", "foo"])
    XCTAssertNil(sut.popNextElementIfValue(after: .argumentIndex(SplitArguments.Index(inputIndex: 2, subIndex: .complete))))
  }
  
  func testPopNextElementIfValueAfter_4() throws {
    var sut = try SplitArguments(arguments: ["--bar", "bar", "-12", "--foo", "foo"])
    
    let value = try XCTUnwrap(sut.popNextElementIfValue(after: .argumentIndex(SplitArguments.Index(inputIndex: 3, subIndex: .complete))))
    XCTAssertEqual(value.0, .argumentIndex(SplitArguments.Index(inputIndex: 4, subIndex: .complete)))
    XCTAssertEqual(value.1, "foo")
  }
  
  func testPopNextValueAfter_1() throws {
    var sut = try SplitArguments(arguments: ["--bar", "bar", "-12", "--foo", "foo"])
    
    XCTAssertEqual(sut.elements.count, 7)
    
    let valueA = try XCTUnwrap(sut.popNextValue(after: .argumentIndex(SplitArguments.Index(inputIndex: 0, subIndex: .complete))))
    XCTAssertEqual(valueA.0, .argumentIndex(SplitArguments.Index(inputIndex: 1, subIndex: .complete)))
    XCTAssertEqual(valueA.1, "bar")
    
    let valueB = try XCTUnwrap(sut.popNextValue(after: .argumentIndex(SplitArguments.Index(inputIndex: 0, subIndex: .complete))))
    XCTAssertEqual(valueB.0, .argumentIndex(SplitArguments.Index(inputIndex: 2, subIndex: .complete)))
    XCTAssertEqual(valueB.1, "-12")
    
    let valueC = try XCTUnwrap(sut.popNextValue(after: .argumentIndex(SplitArguments.Index(inputIndex: 0, subIndex: .complete))))
    XCTAssertEqual(valueC.0, .argumentIndex(SplitArguments.Index(inputIndex: 4, subIndex: .complete)))
    XCTAssertEqual(valueC.1, "foo")
    
    XCTAssertNil(sut.popNextValue(after: .argumentIndex(SplitArguments.Index(inputIndex: 0, subIndex: .complete))))
    
    XCTAssertEqual(sut.elements.count, 2)
  }
  
  func testPopNextValueAfter_2() throws {
    var sut = try SplitArguments(arguments: ["--bar", "bar", "-12", "--foo", "foo"])
    
    XCTAssertEqual(sut.elements.count, 7)
    
    let value = try XCTUnwrap(sut.popNextValue(after: .argumentIndex(SplitArguments.Index(inputIndex: 1, subIndex: .complete))))
    XCTAssertEqual(value.0, .argumentIndex(SplitArguments.Index(inputIndex: 2, subIndex: .complete)))
    XCTAssertEqual(value.1, "-12")
    
    let valueC = try XCTUnwrap(sut.popNextValue(after: .argumentIndex(SplitArguments.Index(inputIndex: 1, subIndex: .complete))))
    XCTAssertEqual(valueC.0, .argumentIndex(SplitArguments.Index(inputIndex: 4, subIndex: .complete)))
    XCTAssertEqual(valueC.1, "foo")
    
    XCTAssertNil(sut.popNextValue(after: .argumentIndex(SplitArguments.Index(inputIndex: 2, subIndex: .complete))))
    
    XCTAssertEqual(sut.elements.count, 3)
  }
  
  func testPopNextValueAfter_3() throws {
    var sut = try SplitArguments(arguments: ["--bar", "bar", "-12", "--foo", "foo"])
    
    XCTAssertNil(sut.popNextValue(after: .argumentIndex(SplitArguments.Index(inputIndex: 4, subIndex: .complete))))
  }
  
  func testPopNextElementAsValueAfter_1() throws {
    var sut = try SplitArguments(arguments: ["--bar", "bar", "-12", "--foo", "foo"])
    
    let valueA = try XCTUnwrap(sut.popNextElementAsValue(after: .argumentIndex(SplitArguments.Index(inputIndex: 0, subIndex: .complete))))
    XCTAssertEqual(valueA.0, .argumentIndex(SplitArguments.Index(inputIndex: 1, subIndex: .complete)))
    XCTAssertEqual(valueA.1, "bar")
    
    let valueB = try XCTUnwrap(sut.popNextElementAsValue(after: .argumentIndex(SplitArguments.Index(inputIndex: 0, subIndex: .complete))))
    XCTAssertEqual(valueB.0, .argumentIndex(SplitArguments.Index(inputIndex: 2, subIndex: .complete)))
    XCTAssertEqual(valueB.1, "-12")
    
    let valueC = try XCTUnwrap(sut.popNextElementAsValue(after: .argumentIndex(SplitArguments.Index(inputIndex: 0, subIndex: .complete))))
    XCTAssertEqual(valueC.0, .argumentIndex(SplitArguments.Index(inputIndex: 3, subIndex: .complete)))
    XCTAssertEqual(valueC.1, "--foo")
  }
  
  func testPopNextElementAsValueAfter_2() throws {
    var sut = try SplitArguments(arguments: ["--bar", "bar", "--foo", "foo"])
    
    XCTAssertNil(sut.popNextElementAsValue(after: .argumentIndex(SplitArguments.Index(inputIndex: 3, subIndex: .complete))))
  }
  
  func testPopNextElementAsValueAfter_3() throws {
    var sut = try SplitArguments(arguments: ["--bar", "-bar"])
    
    let value = try XCTUnwrap(sut.popNextElementAsValue(after: .argumentIndex(SplitArguments.Index(inputIndex: 0, subIndex: .complete))))
    XCTAssertEqual(value.0, .argumentIndex(SplitArguments.Index(inputIndex: 1, subIndex: .complete)))
    XCTAssertEqual(value.1, "-bar")
  }
  
  func testPopNextElementIfValue() throws {
    var sut = try SplitArguments(arguments: ["--bar", "bar", "-12", "--foo", "foo"])
    
    _ = try XCTUnwrap(sut.popNext())
    
    let valueA = try XCTUnwrap(sut.popNextElementIfValue())
    XCTAssertEqual(valueA.0, .argumentIndex(SplitArguments.Index(inputIndex: 1, subIndex: .complete)))
    XCTAssertEqual(valueA.1, "bar")
    
    let valueB = try XCTUnwrap(sut.popNextElementIfValue())
    XCTAssertEqual(valueB.0, .argumentIndex(SplitArguments.Index(inputIndex: 2, subIndex: .complete)))
    XCTAssertEqual(valueB.1, "-12")
    
    XCTAssertNil(sut.popNextElementIfValue())
    _ = try XCTUnwrap(sut.popNext())
    
    let valueC = try XCTUnwrap(sut.popNextElementIfValue())
    XCTAssertEqual(valueC.0, .argumentIndex(SplitArguments.Index(inputIndex: 4, subIndex: .complete)))
    XCTAssertEqual(valueC.1, "foo")
    
    XCTAssertNil(sut.popNextElementIfValue())
  }
  
  func testPopNextValue() throws {
    var sut = try SplitArguments(arguments: ["--bar", "bar", "-12", "--foo", "foo"])
    
    let valueA = try XCTUnwrap(sut.popNextValue())
    XCTAssertEqual(valueA.0, SplitArguments.Index(inputIndex: 1, subIndex: .complete))
    XCTAssertEqual(valueA.1, "bar")
    
    let valueB = try XCTUnwrap(sut.popNextValue())
    XCTAssertEqual(valueB.0, SplitArguments.Index(inputIndex: 2, subIndex: .complete))
    XCTAssertEqual(valueB.1, "-12")
    XCTAssertEqual(sut.elements.count, 3) // Ensure popping as value removes subindices
    
    let valueC = try XCTUnwrap(sut.popNextValue())
    XCTAssertEqual(valueC.0, SplitArguments.Index(inputIndex: 4, subIndex: .complete))
    XCTAssertEqual(valueC.1, "foo")
    
    XCTAssertNil(sut.popNextElementIfValue())
  }
  
  func testPeekNextValue() throws {
    let sut = try SplitArguments(arguments: ["--bar", "bar", "-12", "--foo", "foo"])
    
    let valueA = try XCTUnwrap(sut.peekNextValue())
    XCTAssertEqual(valueA.0, SplitArguments.Index(inputIndex: 1, subIndex: .complete))
    XCTAssertEqual(valueA.1, "bar")
    
    let valueB = try XCTUnwrap(sut.peekNextValue())
    XCTAssertEqual(valueB.0, SplitArguments.Index(inputIndex: 1, subIndex: .complete))
    XCTAssertEqual(valueB.1, "bar")
    
    let sut2 = try SplitArguments(arguments: ["--bar", "-12"])
    
    let value2 = try XCTUnwrap(sut2.peekNextValue())
    XCTAssertEqual(value2.0, SplitArguments.Index(inputIndex: 1, subIndex: .complete))
    XCTAssertEqual(value2.1, "-12")
  }
}
