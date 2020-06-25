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

final class NegativeNumbersEndToEndTests: XCTestCase {
}

// MARK: - Int Values

fileprivate struct Foo: ParsableArguments {
  @Option() var single: Int
  @Option(parsing: .upToNextOption) var multiple: [Int] = []
}

extension NegativeNumbersEndToEndTests {
  func testParsing_NegativeInt_Options() throws {
    AssertParse(Foo.self, ["--single", "-1", "--multiple", "-2", "-3"]) { options in
      XCTAssertEqual(options.single, -1)
      XCTAssertEqual(options.multiple, [-2, -3])
    }
  }
}

fileprivate struct Bar: ParsableArguments {
  @Argument() var single: Int
  @Argument() var multiple: [Int] = []
}

extension NegativeNumbersEndToEndTests {
  func testParsing_NegativeInt_Arguments() throws {
    AssertParse(Bar.self, ["-1", "-2", "-3"]) { options in
      XCTAssertEqual(options.single, -1)
      XCTAssertEqual(options.multiple, [-2, -3])
    }
  }
}

// MARK: - Double Values

fileprivate struct Baz: ParsableArguments {
  @Option() var single: Double
  @Option(parsing: .upToNextOption) var multiple: [Double] = []
}

extension NegativeNumbersEndToEndTests {
  func testParsing_NegativeDouble_Options() throws {
    AssertParse(Baz.self, ["--single", "-1.1", "--multiple", "-2.1", "-3.1"]) { options in
      XCTAssertEqual(options.single, -1.1)
      XCTAssertEqual(options.multiple, [-2.1, -3.1])
    }
  }
}

fileprivate struct Qux: ParsableArguments {
  @Argument() var single: Double
  @Argument() var multiple: [Double] = []
}

extension NegativeNumbersEndToEndTests {
  func testParsing_NegativeDouble_Arguments() throws {
    AssertParse(Qux.self, ["-1.1", "-2.1", "-3.1"]) { options in
      XCTAssertEqual(options.single, -1.1)
      XCTAssertEqual(options.multiple, [-2.1, -3.1])
    }
  }
}

// MARK: - Flags

fileprivate struct IntFlags: ParsableArguments {
  @Flag(name: [.customShort("4")])
  var flag4: Bool = false
  
  @Flag(name: [.customShort("6")])
  var flag6: Bool = false
  
  @Flag(name: [.customLong("12", withSingleDash: true)])
  var flag12: Bool = false
  
  @Argument()
  var extraNumbers: [Int] = []
}

fileprivate struct DoubleFlags: ParsableArguments {
  @Flag(name: [.customShort("4")])
  var flag4: Bool = false
  
  @Flag(name: [.customShort("6")])
  var flag6: Bool = false
  
  @Flag(name: [.customLong("12", withSingleDash: true)])
  var flag12: Bool = false
  
  @Argument()
  var extraNumbers: [Double] = []
}

extension NegativeNumbersEndToEndTests {
  func testParsing_NumericFlagName_NoMatchingOptions() throws {
    AssertParse(IntFlags.self, ["-35", "-1"]) { parsed in
      XCTAssertEqual(parsed.flag4, false)
      XCTAssertEqual(parsed.flag6, false)
      XCTAssertEqual(parsed.flag12, false)
      XCTAssertEqual(parsed.extraNumbers, [-35, -1])
    }
    AssertParse(DoubleFlags.self, ["-3.5", "-1.1"]) { parsed in
      XCTAssertEqual(parsed.flag4, false)
      XCTAssertEqual(parsed.flag6, false)
      XCTAssertEqual(parsed.flag12, false)
      XCTAssertEqual(parsed.extraNumbers, [-3.5, -1.1])
    }
  }
  
  func testParsing_NumericFlagName_SomeMatchingOptions() throws {
    AssertParse(IntFlags.self, ["-45", "-1"]) { parsed in
      XCTAssertEqual(parsed.flag4, false)
      XCTAssertEqual(parsed.flag6, false)
      XCTAssertEqual(parsed.flag12, false)
      XCTAssertEqual(parsed.extraNumbers, [-45, -1])
    }
    AssertParse(DoubleFlags.self, ["-4.5", "-1.1"]) { parsed in
      XCTAssertEqual(parsed.flag4, false)
      XCTAssertEqual(parsed.flag6, false)
      XCTAssertEqual(parsed.flag12, false)
      XCTAssertEqual(parsed.extraNumbers, [-4.5, -1.1])
    }
  }
  
  func testParsing_NumericFlagName_AllMatchingOptions() throws {
    AssertParse(IntFlags.self, ["-46", "-1", "-4"]) { parsed in
      XCTAssertEqual(parsed.flag4, true)
      XCTAssertEqual(parsed.flag6, true)
      XCTAssertEqual(parsed.flag12, false)
      XCTAssertEqual(parsed.extraNumbers, [-1, -4])
    }
    AssertParse(DoubleFlags.self, ["-4.6", "-1.1"]) { parsed in
      XCTAssertEqual(parsed.flag4, false)
      XCTAssertEqual(parsed.flag6, false)
      XCTAssertEqual(parsed.flag12, false)
      XCTAssertEqual(parsed.extraNumbers, [-4.6, -1.1])
    }
    AssertParse(DoubleFlags.self, ["-46", "-1.1", "-4"]) { parsed in
      XCTAssertEqual(parsed.flag4, true)
      XCTAssertEqual(parsed.flag6, true)
      XCTAssertEqual(parsed.flag12, false)
      XCTAssertEqual(parsed.extraNumbers, [-1.1, -4])
    }
  }
  
  func testParsing_NumericFlagName_Ordering() throws {
    AssertParse(IntFlags.self, ["-46", "-4", "-6"]) { parsed in
      XCTAssertEqual(parsed.flag4, true)
      XCTAssertEqual(parsed.flag6, true)
      XCTAssertEqual(parsed.flag12, false)
      XCTAssertEqual(parsed.extraNumbers, [-4, -6])
    }
    AssertParse(IntFlags.self, ["-4", "-6", "-46"]) { parsed in
      XCTAssertEqual(parsed.flag4, true)
      XCTAssertEqual(parsed.flag6, true)
      XCTAssertEqual(parsed.flag12, false)
      XCTAssertEqual(parsed.extraNumbers, [-46])
    }
    AssertParse(IntFlags.self, ["-4", "-46", "-6"]) { parsed in
      XCTAssertEqual(parsed.flag4, true)
      XCTAssertEqual(parsed.flag6, true)
      XCTAssertEqual(parsed.flag12, false)
      XCTAssertEqual(parsed.extraNumbers, [-46])
    }
  }
  
  func testParsing_NumericFlagName_Interspersed() throws {
    AssertParse(IntFlags.self, ["-4", "-1", "-6", "-2", "-4"]) { parsed in
      XCTAssertEqual(parsed.flag4, true)
      XCTAssertEqual(parsed.flag6, true)
      XCTAssertEqual(parsed.flag12, false)
      XCTAssertEqual(parsed.extraNumbers, [-1, -2, -4])
    }
    AssertParse(DoubleFlags.self, ["-4", "-1.1", "-6", "-2.1", "-4"]) { parsed in
      XCTAssertEqual(parsed.flag4, true)
      XCTAssertEqual(parsed.flag6, true)
      XCTAssertEqual(parsed.flag12, false)
      XCTAssertEqual(parsed.extraNumbers, [-1.1, -2.1, -4])
    }
  }
  
  func testParsing_NumericFlagName_SingleDashLongName() throws {
    AssertParse(IntFlags.self, ["-46", "-1", "-35", "-12", "-34", "-4", "-12"]) { parsed in
      XCTAssertEqual(parsed.flag4, true)
      XCTAssertEqual(parsed.flag6, true)
      XCTAssertEqual(parsed.flag12, true)
      XCTAssertEqual(parsed.extraNumbers, [-1, -35, -34, -4, -12])
    }
    AssertParse(DoubleFlags.self, ["-46", "-1", "-3.5", "-12", "-3.4", "-4", "-12"]) { parsed in
      XCTAssertEqual(parsed.flag4, true)
      XCTAssertEqual(parsed.flag6, true)
      XCTAssertEqual(parsed.flag12, true)
      XCTAssertEqual(parsed.extraNumbers, [-1, -3.5, -3.4, -4, -12])
    }
  }
}

// MARK: - Single Value Options

fileprivate struct IntOptionNext: ParsableArguments {
  @Option(name: [.customShort("1")], parsing: .next)
  var option1: Int?
  
  @Option(name: [.customLong("12", withSingleDash: true)], parsing: .next)
  var option12: Int?
  
  @Argument()
  var extraNumbers: [Int] = []
}

fileprivate struct DoubleOptionNext: ParsableArguments {
  @Option(name: [.customShort("1")], parsing: .next)
  var option1: Double?
  
  @Option(name: [.customLong("12", withSingleDash: true)], parsing: .next)
  var option12: Double?
  
  @Argument()
  var extraNumbers: [Double] = []
}

extension NegativeNumbersEndToEndTests {
  func testParsing_NumericOptionName_SingleNext() throws {
    // Int
    AssertParse(IntOptionNext.self, ["-1", "-12", "-1", "-3", "-12", "-1"]) { parsed in
      XCTAssertEqual(parsed.option1, -12)
      XCTAssertEqual(parsed.option12, -1)
      XCTAssertEqual(parsed.extraNumbers, [-1, -3])
    }
    AssertParse(IntOptionNext.self, ["-1=-12", "-1", "-3", "-12=-1"]) { parsed in
      XCTAssertEqual(parsed.option1, -12)
      XCTAssertEqual(parsed.option12, -1)
      XCTAssertEqual(parsed.extraNumbers, [-1, -3])
    }
    
    // Double
    AssertParse(DoubleOptionNext.self, ["-1", "-12", "-1", "-3", "-12", "-1"]) { parsed in
      XCTAssertEqual(parsed.option1, -12)
      XCTAssertEqual(parsed.option12, -1)
      XCTAssertEqual(parsed.extraNumbers, [-1, -3])
    }
    AssertParse(DoubleOptionNext.self, ["-1=-12", "-1", "-3", "-12=-1"]) { parsed in
      XCTAssertEqual(parsed.option1, -12)
      XCTAssertEqual(parsed.option12, -1)
      XCTAssertEqual(parsed.extraNumbers, [-1, -3])
    }
  }
}

fileprivate struct IntOptionUnconditional: ParsableArguments {
  @Option(name: [.customShort("1")], parsing: .unconditional)
  var option1: Int?
  
  @Option(name: [.customLong("12", withSingleDash: true)], parsing: .unconditional)
  var option12: Int?
  
  @Argument()
  var extraNumbers: [Int] = []
}

fileprivate struct DoubleOptionUnconditional: ParsableArguments {
  @Option(name: [.customShort("1")], parsing: .unconditional)
  var option1: Double?
  
  @Option(name: [.customLong("12", withSingleDash: true)], parsing: .unconditional)
  var option12: Double?
  
  @Argument()
  var extraNumbers: [Double] = []
}

extension NegativeNumbersEndToEndTests {
  func testParsing_NumericOptionName_SingleUnconditional() throws {
    // Int
    AssertParse(IntOptionUnconditional.self, ["-1", "-12", "-1", "-3", "-12", "-1"]) { parsed in
      XCTAssertEqual(parsed.option1, -12)
      XCTAssertEqual(parsed.option12, -1)
      XCTAssertEqual(parsed.extraNumbers, [-1, -3])
    }
    AssertParse(IntOptionUnconditional.self, ["-1=-12", "-1", "-3", "-12=-1"]) { parsed in
      XCTAssertEqual(parsed.option1, -12)
      XCTAssertEqual(parsed.option12, -1)
      XCTAssertEqual(parsed.extraNumbers, [-1, -3])
    }
    
    // Double
    AssertParse(DoubleOptionUnconditional.self, ["-1", "-12", "-1", "-3", "-12", "-1"]) { parsed in
      XCTAssertEqual(parsed.option1, -12)
      XCTAssertEqual(parsed.option12, -1)
      XCTAssertEqual(parsed.extraNumbers, [-1, -3])
    }
    AssertParse(DoubleOptionUnconditional.self, ["-1=-12", "-1", "-3", "-12=-1"]) { parsed in
      XCTAssertEqual(parsed.option1, -12)
      XCTAssertEqual(parsed.option12, -1)
      XCTAssertEqual(parsed.extraNumbers, [-1, -3])
    }
  }
}

fileprivate struct IntOptionScanningForValue: ParsableArguments {
  @Option(name: [.customShort("1")], parsing: .scanningForValue)
  var option1: Int?
  
  @Option(name: [.customLong("12", withSingleDash: true)], parsing: .scanningForValue )
  var option12: Int?
  
  @Argument()
  var extraNumbers: [Int] = []
}

fileprivate struct DoubleOptionScanningForValue: ParsableArguments {
  @Option(name: [.customShort("1")], parsing: .scanningForValue)
  var option1: Double?
  
  @Option(name: [.customLong("12", withSingleDash: true)], parsing: .scanningForValue )
  var option12: Double?
  
  @Argument()
  var extraNumbers: [Double] = []
}

extension NegativeNumbersEndToEndTests {
  func testParsing_NumericOptionName_SingleScanning() throws {
    // Int
    AssertParse(IntOptionScanningForValue.self, ["-1", "-12", "-1", "-3", "-12", "-1"]) { parsed in
      XCTAssertEqual(parsed.option1, -12)
      XCTAssertEqual(parsed.option12, -1)
      XCTAssertEqual(parsed.extraNumbers, [-1, -3])
    }
    AssertParse(IntOptionScanningForValue.self, ["-1=-12", "-1", "-3", "-12=-1"]) { parsed in
      XCTAssertEqual(parsed.option1, -12)
      XCTAssertEqual(parsed.option12, -1)
      XCTAssertEqual(parsed.extraNumbers, [-1, -3])
    }
    
    // Double
    AssertParse(DoubleOptionScanningForValue.self, ["-1", "-12", "-1", "-3", "-12", "-1"]) { parsed in
      XCTAssertEqual(parsed.option1, -12)
      XCTAssertEqual(parsed.option12, -1)
      XCTAssertEqual(parsed.extraNumbers, [-1, -3])
    }
    AssertParse(DoubleOptionScanningForValue.self, ["-1=-12", "-1", "-3", "-12=-1"]) { parsed in
      XCTAssertEqual(parsed.option1, -12)
      XCTAssertEqual(parsed.option12, -1)
      XCTAssertEqual(parsed.extraNumbers, [-1, -3])
    }
  }
}

// MARK: - Array Options

fileprivate struct IntOptionArraySingleValue: ParsableArguments {
  @Option(name: [.customShort("1")], parsing: .singleValue)
  var option1: [Int] = []
  
  @Option(name: [.customLong("12", withSingleDash: true)], parsing: .singleValue)
  var option12: [Int] = []
  
  @Argument()
  var extraNumbers: [Int] = []
}

fileprivate struct DoubleOptionArraySingleValue: ParsableArguments {
  @Option(name: [.customShort("1")], parsing: .singleValue)
  var option1: [Double] = []
  
  @Option(name: [.customLong("12", withSingleDash: true)], parsing: .singleValue)
  var option12: [Double] = []
  
  @Argument()
  var extraNumbers: [Double] = []
}

extension NegativeNumbersEndToEndTests {
  func testParsing_NumericOptionName_ArraySingleValue() throws {
    // Int
    AssertParse(IntOptionArraySingleValue.self, ["-1", "-12", "-1", "-3", "-12", "-1"]) { parsed in
      XCTAssertEqual(parsed.option1, [-12])
      XCTAssertEqual(parsed.option12, [-1])
      XCTAssertEqual(parsed.extraNumbers, [-1, -3])
    }
    AssertParse(IntOptionArraySingleValue.self, ["-1=-12", "-1", "-3", "-12=-1"]) { parsed in
      XCTAssertEqual(parsed.option1, [-12])
      XCTAssertEqual(parsed.option12, [-1])
      XCTAssertEqual(parsed.extraNumbers, [-1, -3])
    }
    
    // Double
    AssertParse(DoubleOptionArraySingleValue.self, ["-1", "-12", "-1", "-3", "-12", "-1"]) { parsed in
      XCTAssertEqual(parsed.option1, [-12])
      XCTAssertEqual(parsed.option12, [-1])
      XCTAssertEqual(parsed.extraNumbers, [-1, -3])
    }
    AssertParse(DoubleOptionArraySingleValue.self, ["-1=-12", "-1", "-3", "-12=-1"]) { parsed in
      XCTAssertEqual(parsed.option1, [-12])
      XCTAssertEqual(parsed.option12, [-1])
      XCTAssertEqual(parsed.extraNumbers, [-1, -3])
    }
  }
}

fileprivate struct IntOptionArrayUpToNextOption: ParsableArguments {
  @Option(name: [.customShort("1")], parsing: .upToNextOption)
  var option1: [Int] = []
  
  @Option(name: [.customLong("12", withSingleDash: true)], parsing: .upToNextOption)
  var option12: [Int] = []
  
  @Flag()
  var flag: Bool = false
  
  @Argument()
  var extraNumbers: [Int] = []
}

fileprivate struct DoubleOptionArrayUpToNextOption: ParsableArguments {
  @Option(name: [.customShort("1")], parsing: .upToNextOption)
  var option1: [Double] = []
  
  @Option(name: [.customLong("12", withSingleDash: true)], parsing: .upToNextOption)
  var option12: [Double] = []
  
  @Flag()
  var flag: Bool = false
  
  @Argument()
  var extraNumbers: [Double] = []
}

extension NegativeNumbersEndToEndTests {
  func testParsing_NumericOptionName_ArrayUpToNextOption() throws {
    // Int
    AssertParse(IntOptionArrayUpToNextOption.self, ["-1", "-12", "-1", "-3", "-12", "-1"]) { parsed in
      XCTAssertEqual(parsed.option1, [-12, -1, -3, -12, -1])
      XCTAssertEqual(parsed.option12, [])
      XCTAssertEqual(parsed.flag, false)
      XCTAssertEqual(parsed.extraNumbers, [])
    }
    AssertParse(IntOptionArrayUpToNextOption.self, ["-1", "-12", "-1", "-3", "--flag", "-12", "-1"]) { parsed in
      XCTAssertEqual(parsed.option1, [-12, -1, -3])
      XCTAssertEqual(parsed.option12, [-1])
      XCTAssertEqual(parsed.flag, true)
      XCTAssertEqual(parsed.extraNumbers, [])
    }
    AssertParse(IntOptionArrayUpToNextOption.self, ["-1=-12", "-1", "-3", "-12=-1"]) { parsed in
      XCTAssertEqual(parsed.option1, [-12, -1, -3])
      XCTAssertEqual(parsed.option12, [-1])
      XCTAssertEqual(parsed.flag, false)
      XCTAssertEqual(parsed.extraNumbers, [])
    }
    
    // Double
    AssertParse(DoubleOptionArrayUpToNextOption.self, ["-1", "-12", "-1", "-3", "-12", "-1"]) { parsed in
      XCTAssertEqual(parsed.option1, [-12, -1, -3, -12, -1])
      XCTAssertEqual(parsed.option12, [])
      XCTAssertEqual(parsed.flag, false)
      XCTAssertEqual(parsed.extraNumbers, [])
    }
    AssertParse(DoubleOptionArrayUpToNextOption.self, ["-1", "-12", "-1", "-3", "--flag", "-12", "-1"]) { parsed in
      XCTAssertEqual(parsed.option1, [-12, -1, -3])
      XCTAssertEqual(parsed.option12, [-1])
      XCTAssertEqual(parsed.flag, true)
      XCTAssertEqual(parsed.extraNumbers, [])
    }
    AssertParse(DoubleOptionArrayUpToNextOption.self, ["-1=-12", "-1", "-3", "-12=-1"]) { parsed in
      XCTAssertEqual(parsed.option1, [-12, -1, -3])
      XCTAssertEqual(parsed.option12, [-1])
      XCTAssertEqual(parsed.flag, false)
      XCTAssertEqual(parsed.extraNumbers, [])
    }
  }
}

fileprivate struct IntOptionArrayRemaining: ParsableArguments {
  @Option(name: [.customShort("1")], parsing: .remaining)
  var option1: [Int] = []
  
  @Option(name: [.customLong("12", withSingleDash: true)], parsing: .remaining)
  var option12: [Int] = []
  
  @Flag()
  var flag: Bool = false
  
  @Argument()
  var extraNumbers: [Int] = []
}

fileprivate struct DoubleOptionArrayRemaining: ParsableArguments {
  @Option(name: [.customShort("1")], parsing: .remaining)
  var option1: [Double] = []
  
  @Option(name: [.customLong("12", withSingleDash: true)], parsing: .remaining)
  var option12: [Double] = []
  
  @Flag()
  var flag: Bool = false
  
  @Argument()
  var extraNumbers: [Double] = []
}

extension NegativeNumbersEndToEndTests {
  func testParsing_NumericOptionName_ArrayRemaining() throws {
    // Int
    AssertParse(IntOptionArrayRemaining.self, ["-1", "-12", "-1", "-3", "-12", "-1"]) { parsed in
      XCTAssertEqual(parsed.option1, [-12, -1, -3, -12, -1])
      XCTAssertEqual(parsed.option12, [])
      XCTAssertEqual(parsed.flag, false)
      XCTAssertEqual(parsed.extraNumbers, [])
    }
    XCTAssertThrowsError(try IntOptionArrayRemaining.parse(["-1=-12", "-1", "-3", "-12=-1"]))
    
    // Double
    AssertParse(DoubleOptionArrayRemaining.self, ["-1", "-12", "-1", "-3", "-12", "-1"]) { parsed in
      XCTAssertEqual(parsed.option1, [-12, -1, -3, -12, -1])
      XCTAssertEqual(parsed.option12, [])
      XCTAssertEqual(parsed.flag, false)
      XCTAssertEqual(parsed.extraNumbers, [])
    }
    XCTAssertThrowsError(try DoubleOptionArrayRemaining.parse(["-1=-12", "-1", "-3", "-12=-1"]))
  }
}
