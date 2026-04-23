//===----------------------------------------------------------------------===//
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

final class TransformEndToEndTests: XCTestCase {}

private enum FooBarError: Error {
  case outOfBounds
}

private protocol Convert {
  static func convert(_ str: String) throws -> Int
}

extension Convert {
  static func convert(_ str: String) throws -> Int {
    guard let converted = Int(argument: str) else {
      throw ValidationError("Could not transform to an Int.")
    }
    guard converted < 1000 else { throw FooBarError.outOfBounds }
    return converted
  }
}

// MARK: - Options

private struct FooOption: Convert, ParsableArguments {

  static let usageString: String = """
    Usage: foo_option --string <int_str>
      See 'foo_option --help' for more information.
    """
  static let help: String =
    "Help:  --string <int_str>  Convert string to integer\n"

  @Option(
    help: ArgumentHelp("Convert string to integer", valueName: "int_str"),
    transform: { try convert($0) })
  var string: Int
}

private struct BarOption: Convert, ParsableCommand {

  static let usageString: String = """
    Usage: bar-option [--strings <int_str> ...]
      See 'bar-option --help' for more information.
    """
  static let help: String =
    "Help:  --strings <int_str>  Convert a list of strings to an array of integers\n"

  @Option(
    help: ArgumentHelp(
      "Convert a list of strings to an array of integers", valueName: "int_str"),
    transform: { try convert($0) })
  var strings: [Int] = []
}

// swift-format-ignore: AlwaysUseLowerCamelCase
// https://github.com/apple/swift-argument-parser/issues/710
extension TransformEndToEndTests {

  // MARK: Single Values

  func testSingleOptionTransform() throws {
    AssertParse(FooOption.self, ["--string", "42"]) { foo in
      XCTAssertEqual(foo.string, 42)
    }
  }

  func testSingleOptionValidation_Fail_CustomErrorMessage() throws {
    AssertFullErrorMessage(
      FooOption.self, ["--string", "Forty Two"],
      "Error: The value 'Forty Two' is invalid for '--string <int_str>': Could not transform to an Int.\n"
        + FooOption.help + FooOption.usageString)
  }

  func testSingleOptionValidation_Fail_DefaultErrorMessage() throws {
    AssertFullErrorMessage(
      FooOption.self, ["--string", "4827"],
      "Error: The value '4827' is invalid for '--string <int_str>': outOfBounds\n"
        + FooOption.help + FooOption.usageString)
  }

  // MARK: Arrays

  func testOptionArrayTransform() throws {
    AssertParse(
      BarOption.self, ["--strings", "42", "--strings", "72", "--strings", "99"]
    ) { bar in
      XCTAssertEqual(bar.strings, [42, 72, 99])
    }
  }

  func testOptionArrayValidation_Fail_CustomErrorMessage() throws {
    AssertFullErrorMessage(
      BarOption.self,
      ["--strings", "Forty Two", "--strings", "72", "--strings", "99"],
      "Error: The value 'Forty Two' is invalid for '--strings <int_str>': Could not transform to an Int.\n"
        + BarOption.help + BarOption.usageString)
  }

  func testOptionArrayValidation_Fail_DefaultErrorMessage() throws {
    AssertFullErrorMessage(
      BarOption.self,
      ["--strings", "4827", "--strings", "72", "--strings", "99"],
      "Error: The value '4827' is invalid for '--strings <int_str>': outOfBounds\n"
        + BarOption.help + BarOption.usageString)
  }
}

// MARK: - Arguments

private struct FooArgument: Convert, ParsableArguments {

  static let usageString: String = """
    Usage: foo_argument <int_str>
      See 'foo_argument --help' for more information.
    """
  static let help: String = "Help:  <int_str>  Convert string to integer\n"

  enum FooError: Error {
    case outOfBounds
  }

  @Argument(
    help: ArgumentHelp("Convert string to integer", valueName: "int_str"),
    transform: { try convert($0) })
  var string: Int
}

private struct BarArgument: Convert, ParsableCommand {

  static let usageString: String = """
    Usage: bar-argument [<int_str> ...]
      See 'bar-argument --help' for more information.
    """
  static let help: String =
    "Help:  <int_str>  Convert a list of strings to an array of integers\n"

  @Argument(
    help: ArgumentHelp(
      "Convert a list of strings to an array of integers", valueName: "int_str"),
    transform: { try convert($0) })
  var strings: [Int] = []
}

// swift-format-ignore: AlwaysUseLowerCamelCase
// https://github.com/apple/swift-argument-parser/issues/710
extension TransformEndToEndTests {

  // MARK: Single Values

  func testArgumentTransform() throws {
    AssertParse(FooArgument.self, ["42"]) { foo in
      XCTAssertEqual(foo.string, 42)
    }
  }

  func testArgumentValidation_Fail_CustomErrorMessage() throws {
    AssertFullErrorMessage(
      FooArgument.self, ["Forty Two"],
      "Error: The value 'Forty Two' is invalid for '<int_str>': Could not transform to an Int.\n"
        + FooArgument.help + FooArgument.usageString)
  }

  func testArgumentValidation_Fail_DefaultErrorMessage() throws {
    AssertFullErrorMessage(
      FooArgument.self, ["4827"],
      "Error: The value '4827' is invalid for '<int_str>': outOfBounds\n"
        + FooArgument.help + FooArgument.usageString)
  }

  // MARK: Arrays

  func testArgumentArrayTransform() throws {
    AssertParse(BarArgument.self, ["42", "72", "99"]) { bar in
      XCTAssertEqual(bar.strings, [42, 72, 99])
    }
  }

  func testArgumentArrayValidation_Fail_CustomErrorMessage() throws {
    AssertFullErrorMessage(
      BarArgument.self, ["Forty Two", "72", "99"],
      "Error: The value 'Forty Two' is invalid for '<int_str>': Could not transform to an Int.\n"
        + BarArgument.help + BarArgument.usageString)
  }

  func testArgumentArrayValidation_Fail_DefaultErrorMessage() throws {
    AssertFullErrorMessage(
      BarArgument.self, ["4827", "72", "99"],
      "Error: The value '4827' is invalid for '<int_str>': outOfBounds\n"
        + BarArgument.help + BarArgument.usageString)
  }
}

// MARK: - Name-aware transform

private enum Operation: Equatable {
  case resize(String)
  case blur(String)
  case crop(String)
}

private struct NameTransformArray: ParsableArguments {
  @Option(
    name: [.customLong("resize"), .customLong("blur"), .customLong("crop")],
    transformIncludingName: { (optionName: String, value: String) -> Operation in
      switch optionName {
      case "resize": return .resize(value)
      case "blur": return .blur(value)
      case "crop": return .crop(value)
      default: fatalError()
      }
    }
  ) var operations: [Operation] = []
}

private struct NameTransformSingle: ParsableArguments {
  @Option(
    name: [.customLong("resize"), .customLong("crop")],
    transformIncludingName: { (optionName: String, value: String) -> Operation in
      switch optionName {
      case "resize": return .resize(value)
      case "crop": return .crop(value)
      default: fatalError()
      }
    }
  ) var operation: Operation
}

extension TransformEndToEndTests {
  func testNameTransformArray_Order() throws {
    AssertParse(NameTransformArray.self, ["--resize", "50%", "--blur", "3", "--crop", "100x100"]) {
      XCTAssertEqual($0.operations, [.resize("50%"), .blur("3"), .crop("100x100")])
    }
  }

  func testNameTransformArray_ReverseOrder() throws {
    AssertParse(NameTransformArray.self, ["--crop", "100x100", "--resize", "50%"]) {
      XCTAssertEqual($0.operations, [.crop("100x100"), .resize("50%")])
    }
  }

  func testNameTransformArray_Repeated() throws {
    AssertParse(NameTransformArray.self, ["--blur", "3", "--blur", "1"]) {
      XCTAssertEqual($0.operations, [.blur("3"), .blur("1")])
    }
  }

  func testNameTransformArray_Empty() throws {
    AssertParse(NameTransformArray.self, []) {
      XCTAssertEqual($0.operations, [])
    }
  }

  func testNameTransformSingle() throws {
    AssertParse(NameTransformSingle.self, ["--resize", "50%"]) {
      XCTAssertEqual($0.operation, .resize("50%"))
    }
    AssertParse(NameTransformSingle.self, ["--crop", "100x100"]) {
      XCTAssertEqual($0.operation, .crop("100x100"))
    }
  }

  func testNameTransformArray_InterleavedRepeats() throws {
    AssertParse(NameTransformArray.self, [
      "--crop", "200x200",
      "--resize", "50%",
      "--crop", "100x100",
      "--resize", "25%",
    ]) {
      XCTAssertEqual($0.operations, [
        .crop("200x200"),
        .resize("50%"),
        .crop("100x100"),
        .resize("25%"),
      ])
    }
  }

  func testNameTransformArray_SameOptionManyTimes() throws {
    AssertParse(NameTransformArray.self, [
      "--blur", "1",
      "--blur", "5",
      "--blur", "3",
      "--blur", "7",
    ]) {
      XCTAssertEqual($0.operations, [
        .blur("1"), .blur("5"), .blur("3"), .blur("7"),
      ])
    }
  }

  func testNameTransformArray_AllThreeInterleaved() throws {
    AssertParse(NameTransformArray.self, [
      "--resize", "50%",
      "--blur", "3",
      "--crop", "100x100",
      "--blur", "1",
      "--resize", "25%",
      "--crop", "50x50",
    ]) {
      XCTAssertEqual($0.operations, [
        .resize("50%"),
        .blur("3"),
        .crop("100x100"),
        .blur("1"),
        .resize("25%"),
        .crop("50x50"),
      ])
    }
  }

  func testNameTransformArray_SingleElement() throws {
    AssertParse(NameTransformArray.self, ["--crop", "80x80"]) {
      XCTAssertEqual($0.operations, [.crop("80x80")])
    }
  }
}
