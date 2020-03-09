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

final class FlagsEndToEndTests: XCTestCase {
}

// MARK: -

fileprivate struct Bar: ParsableArguments {
  @Flag()
  var verbose: Bool
  
  @Flag(inversion: .prefixedNo)
  var extattr: Bool

  @Flag(inversion: .prefixedNo, exclusivity: .exclusive)
  var extattr2: Bool?

  @Flag(inversion: .prefixedEnableDisable, exclusivity: .chooseFirst)
  var logging: Bool

  @Flag(inversion: .prefixedEnableDisable, exclusivity: .chooseLast)
  var download: Bool
}

extension FlagsEndToEndTests {
  func testParsing_defaultValue() throws {
    AssertParse(Bar.self, []) { options in
      XCTAssertEqual(options.verbose, false)
      XCTAssertEqual(options.extattr, false)
      XCTAssertEqual(options.extattr2, nil)
    }
  }
  
  func testParsing_settingValue() throws {
    AssertParse(Bar.self, ["--verbose"]) { options in
      XCTAssertEqual(options.verbose, true)
      XCTAssertEqual(options.extattr, false)
      XCTAssertEqual(options.extattr2, nil)
    }
    
    AssertParse(Bar.self, ["--extattr"]) { options in
      XCTAssertEqual(options.verbose, false)
      XCTAssertEqual(options.extattr, true)
      XCTAssertEqual(options.extattr2, nil)
    }

    AssertParse(Bar.self, ["--extattr2"]) { options in
      XCTAssertEqual(options.verbose, false)
      XCTAssertEqual(options.extattr, false)
      XCTAssertEqual(options.extattr2, .some(true))
    }
  }
  
  func testParsing_invert_1() throws {
    AssertParse(Bar.self, ["--no-extattr"]) { options in
      XCTAssertEqual(options.extattr, false)
    }
  }

  func testParsing_invert_2() throws {
    AssertParse(Bar.self, ["--extattr", "--no-extattr"]) { options in
      XCTAssertEqual(options.extattr, false)
    }
  }

  func testParsing_invert_3() throws {
    AssertParse(Bar.self, ["--extattr", "--no-extattr", "--no-extattr"]) { options in
      XCTAssertEqual(options.extattr, false)
    }
  }

  func testParsing_invert_4() throws {
    AssertParse(Bar.self, ["--no-extattr", "--no-extattr", "--extattr"]) { options in
      XCTAssertEqual(options.extattr, true)
    }
  }

  func testParsing_invert_5() throws {
    AssertParse(Bar.self, ["--extattr", "--no-extattr", "--extattr"]) { options in
      XCTAssertEqual(options.extattr, true)
    }
  }

  func testParsing_invert_6() throws {
    AssertParse(Bar.self, ["--enable-logging"]) { options in
      XCTAssertEqual(options.logging, true)
    }
  }

  func testParsing_invert_7() throws {
    AssertParse(Bar.self, ["--disable-logging"]) { options in
      XCTAssertEqual(options.logging, false)
    }
  }

  func testParsing_invert_8() throws {
    AssertParse(Bar.self, ["--disable-logging", "--enable-logging"]) { options in
      XCTAssertEqual(options.logging, false)
    }
  }

  func testParsing_invert_9() throws {
    AssertParse(Bar.self, ["--enable-logging", "--disable-logging"]) { options in
      XCTAssertEqual(options.logging, true)
    }
  }

  func testParsing_invert_10() throws {
    AssertParse(Bar.self, ["--enable-download"]) { options in
      XCTAssertEqual(options.download, true)
    }
  }

  func testParsing_invert_11() throws {
    AssertParse(Bar.self, ["--disable-download", "--enable-download"]) { options in
      XCTAssertEqual(options.download, true)
    }
  }

  func testParsing_invert_12() throws {
    AssertParse(Bar.self, ["--enable-download", "--disable-download"]) { options in
      XCTAssertEqual(options.download, false)
    }
  }

  func testParsing_invert_13() throws {
    AssertParse(Bar.self, ["--no-extattr2", "--no-extattr2"]) { options in
      XCTAssertEqual(options.extattr2, false)
    }
  }
}

fileprivate struct Foo: ParsableArguments {
  @Flag(default: false, inversion: .prefixedEnableDisable)
  var index: Bool
  @Flag(default: true, inversion: .prefixedEnableDisable)
  var sandbox: Bool
  @Flag(default: nil, inversion: .prefixedEnableDisable)
  var requiredElement: Bool
}

extension FlagsEndToEndTests {
  func testParsingEnableDisable_defaultValue() throws {
    AssertParse(Foo.self, ["--enable-required-element"]) { options in
      XCTAssertEqual(options.index, false)
      XCTAssertEqual(options.sandbox, true)
      XCTAssertEqual(options.requiredElement, true)
    }
  }
  
  func testParsingEnableDisable_disableAll() throws {
    AssertParse(Foo.self, ["--disable-index", "--disable-sandbox", "--disable-required-element"]) { options in
      XCTAssertEqual(options.index, false)
      XCTAssertEqual(options.sandbox, false)
      XCTAssertEqual(options.requiredElement, false)
    }
  }
  
  func testParsingEnableDisable_enableAll() throws {
    AssertParse(Foo.self, ["--enable-index", "--enable-sandbox", "--enable-required-element"]) { options in
      XCTAssertEqual(options.index, true)
      XCTAssertEqual(options.sandbox, true)
      XCTAssertEqual(options.requiredElement, true)
    }
  }
  
  func testParsingEnableDisable_Fails() throws {
    XCTAssertThrowsError(try Foo.parse([]))
    XCTAssertThrowsError(try Foo.parse(["--disable-index"]))
    XCTAssertThrowsError(try Foo.parse(["--disable-sandbox"]))
  }
}

enum Color: String, CaseIterable {
  case pink
  case purple
  case silver
}

enum Size: String, CaseIterable {
  case small
  case medium
  case large
  case extraLarge
  case humongous = "huge"
}

enum Shape: String, CaseIterable {
  case round
  case square
  case oblong
}

fileprivate struct Baz: ParsableArguments {
  @Flag()
  var color: Color
  
  @Flag(default: .small)
  var size: Size
  
  @Flag()
  var shape: Shape?
}

extension FlagsEndToEndTests {
  func testParsingCaseIterable_defaultValues() throws {
    AssertParse(Baz.self, ["--pink"]) { options in
      XCTAssertEqual(options.color, .pink)
      XCTAssertEqual(options.size, .small)
      XCTAssertEqual(options.shape, nil)
    }
    
    AssertParse(Baz.self, ["--pink", "--medium"]) { options in
      XCTAssertEqual(options.color, .pink)
      XCTAssertEqual(options.size, .medium)
      XCTAssertEqual(options.shape, nil)
    }
    
    AssertParse(Baz.self, ["--pink", "--round"]) { options in
      XCTAssertEqual(options.color, .pink)
      XCTAssertEqual(options.size, .small)
      XCTAssertEqual(options.shape, .round)
    }
  }
  
  func testParsingCaseIterable_AllValues() throws {
    AssertParse(Baz.self, ["--pink", "--small", "--round"]) { options in
      XCTAssertEqual(options.color, .pink)
      XCTAssertEqual(options.size, .small)
      XCTAssertEqual(options.shape, .round)
    }
    
    AssertParse(Baz.self, ["--purple", "--medium", "--square"]) { options in
      XCTAssertEqual(options.color, .purple)
      XCTAssertEqual(options.size, .medium)
      XCTAssertEqual(options.shape, .square)
    }
    
    AssertParse(Baz.self, ["--silver", "--large", "--oblong"]) { options in
      XCTAssertEqual(options.color, .silver)
      XCTAssertEqual(options.size, .large)
      XCTAssertEqual(options.shape, .oblong)
    }
  }
  
  func testParsingCaseIterable_CustomName() throws {
    AssertParse(Baz.self, ["--pink", "--extra-large"]) { options in
      XCTAssertEqual(options.color, .pink)
      XCTAssertEqual(options.size, .extraLarge)
      XCTAssertEqual(options.shape, nil)
    }
    
    AssertParse(Baz.self, ["--pink", "--huge"]) { options in
      XCTAssertEqual(options.color, .pink)
      XCTAssertEqual(options.size, .humongous)
      XCTAssertEqual(options.shape, nil)
    }
  }
  
  func testParsingCaseIterable_Fails() throws {
    // Missing color
    XCTAssertThrowsError(try Baz.parse([]))
    XCTAssertThrowsError(try Baz.parse(["--large", "--square"]))
    // Repeating flags
    XCTAssertThrowsError(try Baz.parse(["--pink", "--purple"]))
    XCTAssertThrowsError(try Baz.parse(["--pink", "--small", "--large"]))
    XCTAssertThrowsError(try Baz.parse(["--pink", "--round", "--square"]))
    // Case name instead of raw value
    XCTAssertThrowsError(try Baz.parse(["--pink", "--extraLarge"]))
  }
}

fileprivate struct Qux: ParsableArguments {
  @Flag()
  var color: [Color]
  
  @Flag()
  var size: [Size]
}

extension FlagsEndToEndTests {
  func testParsingCaseIterableArray_Values() throws {
    AssertParse(Qux.self, []) { options in
      XCTAssertEqual(options.color, [])
      XCTAssertEqual(options.size, [])
    }
    AssertParse(Qux.self, ["--pink"]) { options in
      XCTAssertEqual(options.color, [.pink])
      XCTAssertEqual(options.size, [])
    }
    AssertParse(Qux.self, ["--pink", "--purple", "--small"]) { options in
      XCTAssertEqual(options.color, [.pink, .purple])
      XCTAssertEqual(options.size, [.small])
    }
    AssertParse(Qux.self, ["--pink", "--small", "--purple", "--medium"]) { options in
      XCTAssertEqual(options.color, [.pink, .purple])
      XCTAssertEqual(options.size, [.small, .medium])
    }
    AssertParse(Qux.self, ["--pink", "--pink", "--purple", "--pink"]) { options in
      XCTAssertEqual(options.color, [.pink, .pink, .purple, .pink])
      XCTAssertEqual(options.size, [])
    }
  }
  
  func testParsingCaseIterableArray_Fails() throws {
    XCTAssertThrowsError(try Qux.parse(["--pink", "--small", "--bloop"]))
  }
}

fileprivate struct RepeatOK: ParsableArguments {
  @Flag(exclusivity: .chooseFirst)
  var color: Color

  @Flag(exclusivity: .chooseLast)
  var shape: Shape

  @Flag(name: .shortAndLong, default: .small, exclusivity: .exclusive)
  var size: Size
}

extension FlagsEndToEndTests {
  func testParsingCaseIterable_RepeatableFlags() throws {
    AssertParse(RepeatOK.self, ["--pink", "--purple", "--square"]) { options in
      XCTAssertEqual(options.color, .pink)
      XCTAssertEqual(options.shape, .square)
    }

    AssertParse(RepeatOK.self, ["--round", "--oblong", "--silver"]) { options in
      XCTAssertEqual(options.color, .silver)
      XCTAssertEqual(options.shape, .oblong)
    }

    AssertParse(RepeatOK.self, ["--large", "--pink", "--round", "-l"]) { options in
      XCTAssertEqual(options.size, .large)
    }
  }
}

// MARK: Environment


fileprivate struct Baz2: ParsableArguments {
  @Flag(name: [.environment, .long])
  var shape: Shape?
}

extension FlagsEndToEndTests {
  func testParsingFromEnvironmentAndArguments_single_default() {
    AssertParse(Baz2.self, [], environment: [:]) { options in
      XCTAssertNil(options.shape)
    }
  }

  func testParsingFromEnvironmentAndArguments_single_1() {
    AssertParse(Baz2.self, ["--round"], environment: [:]) { options in
      XCTAssertEqual(options.shape, .round)
    }
  }

  func testParsingFromEnvironmentAndArguments_single_2() {
    AssertParse(Baz2.self, ["--square"], environment: [:]) { options in
      XCTAssertEqual(options.shape, .square)
    }
  }

  func testParsingFromEnvironmentAndArguments_single_3() {
    AssertParse(Baz2.self, [], environment: ["ROUND": ""]) { options in
      XCTAssertEqual(options.shape, .round)
    }
  }

  func testParsingFromEnvironmentAndArguments_single_4() {
    AssertParse(Baz2.self, [], environment: ["SQUARE": ""]) { options in
      XCTAssertEqual(options.shape, .square)
    }
  }

  func testParsingFromEnvironmentAndArguments_single_5() {
    AssertParse(Baz2.self, [], environment: ["OBLONG": ""]) { options in
      XCTAssertEqual(options.shape, .oblong)
    }
  }

  func testParsingFromEnvironmentAndArguments_single_6() {
    AssertParse(Baz2.self, ["--round"], environment: ["OBLONG": ""]) { options in
      XCTAssertEqual(options.shape, .round)
    }
  }

  func testParsingFromEnvironmentAndArguments_single_7() {
    AssertParse(Baz2.self, ["--square"], environment: ["ROUND": ""]) { options in
      XCTAssertEqual(options.shape, .square)
    }
  }
}

fileprivate struct Baz3: ParsableArguments {
  @Flag(name: [.environment, .long])
  var color: Color

  @Flag(name: [.environment, .long], default: .small)
  var size: Size

  @Flag(name: [.environment, .long])
  var shape: Shape?
}

extension FlagsEndToEndTests {
  func testParsingFromEnvironment_1() {
    AssertParse(Baz3.self, [], environment: ["PINK": "", "SMALL": "", "ROUND": ""]) { options in
      XCTAssertEqual(options.color, .pink)
      XCTAssertEqual(options.size, .small)
      XCTAssertEqual(options.shape, .round)
    }
  }

  func testParsingFromEnvironment_2() {
    AssertParse(Baz3.self, [], environment: ["PURPLE": "", "MEDIUM": "", "SQUARE": ""]) { options in
      XCTAssertEqual(options.color, .purple)
      XCTAssertEqual(options.size, .medium)
      XCTAssertEqual(options.shape, .square)
    }
  }

  func testParsingFromEnvironment_3() {
    AssertParse(Baz3.self, [], environment: ["SILVER": "", "LARGE": "", "OBLONG": ""]) { options in
      XCTAssertEqual(options.color, .silver)
      XCTAssertEqual(options.size, .large)
      XCTAssertEqual(options.shape, .oblong)
    }
  }

  func testParsingFromEnvironmentAndArguments_1() {
    AssertParse(Baz3.self, ["--round"], environment: ["PINK": "", "SMALL": ""]) { options in
      XCTAssertEqual(options.color, .pink)
      XCTAssertEqual(options.size, .small)
      XCTAssertEqual(options.shape, .round)
    }
  }

  func testParsingFromEnvironmentAndArguments_2() {
    AssertParse(Baz3.self, ["--purple", "--square"], environment: ["MEDIUM": ""]) { options in
      XCTAssertEqual(options.color, .purple)
      XCTAssertEqual(options.size, .medium)
      XCTAssertEqual(options.shape, .square)
    }
  }

  func testParsingFromEnvironmentAndArguments_3() {
    AssertParse(Baz3.self, ["--large"], environment: ["SILVER": "", "OBLONG": ""]) { options in
      XCTAssertEqual(options.color, .silver)
      XCTAssertEqual(options.size, .large)
      XCTAssertEqual(options.shape, .oblong)
    }
  }

  func testParsingFromEnvironmentAndArguments_4() {
    AssertParse(Baz3.self, ["--large"], environment: ["SILVER": "", "OBLONG": "", "MEDIUM": ""]) { options in
      XCTAssertEqual(options.color, .silver)
      XCTAssertEqual(options.size, .large)
      XCTAssertEqual(options.shape, .oblong)
    }
  }

  func testParsingFromEnvironmentAndArguments_5() {
    AssertParse(Baz3.self, ["--purple", "--square"], environment: ["SILVER": "", "MEDIUM": ""]) { options in
      XCTAssertEqual(options.color, .purple)
      XCTAssertEqual(options.size, .medium)
      XCTAssertEqual(options.shape, .square)
    }
  }

  func testParsingFromEnvironmentAndArguments_6() {
    AssertParse(Baz3.self, ["--round"], environment: ["PINK": "", "OBLONG": "", "SMALL": ""]) { options in
      XCTAssertEqual(options.color, .pink)
      XCTAssertEqual(options.size, .small)
      XCTAssertEqual(options.shape, .round)
    }
  }
}
