//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020-2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import ArgumentParserTestHelpers
import Testing

@testable import ArgumentParser

struct ErrorCase: Sendable, CustomTestStringConvertible {
  let id: String
  let arguments: [String]
  let expected: String
  var testDescription: String { id }
}

@Suite struct ErrorMessageTests {}

// MARK: -

private struct Bar: ParsableArguments {
  @Option() var name: String
  @Option(name: [.short, .long]) var format: String
}

// https://github.com/apple/swift-argument-parser/issues/710
extension ErrorMessageTests {
  static let barCases: [ErrorCase] = [
    ErrorCase(
      id: "missing --name",
      arguments: [],
      expected: "Missing expected argument '--name <name>'"),
    ErrorCase(
      id: "missing --format",
      arguments: ["--name", "a"],
      expected: "Missing expected argument '--format <format>'"),
    ErrorCase(
      id: "unknown long option --verbose",
      arguments: ["--name", "a", "--format", "b", "--verbose"],
      expected: "Unknown option '--verbose'"),
    ErrorCase(
      id: "unknown short option -q",
      arguments: ["--name", "a", "--format", "b", "-q"],
      expected: "Unknown option '-q'"),
    ErrorCase(
      id: "unknown single-dash long option -bar",
      arguments: ["--name", "a", "--format", "b", "-bar"],
      expected: "Unknown option '-bar'"),
    ErrorCase(
      id: "unknown short in combined -foz",
      arguments: ["--name", "a", "-foz", "b"],
      expected: "Unknown option '-o'"),
    ErrorCase(
      id: "missing value for --format",
      arguments: ["--name", "a", "--format"],
      expected: "Missing value for '--format <format>'"),
    ErrorCase(
      id: "missing value for -f",
      arguments: ["--name", "a", "-f"],
      expected: "Missing value for '-f <format>'"),
    ErrorCase(
      id: "one unexpected argument",
      arguments: ["--name", "a", "--format", "f", "b"],
      expected: "Unexpected argument 'b'"),
    ErrorCase(
      id: "two unexpected arguments",
      arguments: ["--name", "a", "--format", "f", "b", "baz"],
      expected: "2 unexpected arguments: 'b', 'baz'"),
  ]

  @Test(arguments: barCases)
  func bar(_ c: ErrorCase) {
    expectErrorMessage(Bar.self, c.arguments, c.expected)
  }
}

private enum Format: String, Equatable, Decodable, ExpressibleByArgument,
  CaseIterable
{
  case text
  case json
  case csv
}

private enum Name: String, Equatable, Decodable, ExpressibleByArgument,
  CaseIterable
{
  case bruce
  case clint
  case hulk
  case natasha
  case steve
  case thor
  case tony
}

private enum Counter: Int, ExpressibleByArgument, CaseIterable {
  case one = 1
  case two, three, four
}

private struct Foo: ParsableArguments {
  @Option(name: [.short, .long])
  var format: Format
  @Option(name: [.short, .long])
  var name: Name?
}

private struct EnumWithFewCasesArrayArgument: ParsableArguments {
  @Argument
  var formats: [Format]
}

private struct EnumWithManyCasesArrayArgument: ParsableArguments {
  @Argument
  var names: [Name]
}

private struct EnumWithIntRawValue: ParsableArguments {
  @Option var counter: Counter
}

extension ErrorMessageTests {
  static let fooCases: [ErrorCase] = [
    ErrorCase(
      id: "invalid enum value for --format",
      arguments: ["--format", "png"],
      expected:
        "The value 'png' is invalid for '--format <format>'. Please provide one of 'text', 'json' or 'csv'."
    ),
    ErrorCase(
      id: "invalid enum value for -f",
      arguments: ["-f", "png"],
      expected:
        "The value 'png' is invalid for '-f <format>'. Please provide one of 'text', 'json' or 'csv'."
    ),
    ErrorCase(
      id: "invalid enum value for --name (many cases)",
      arguments: ["-f", "text", "--name", "loki"],
      expected: """
        The value 'loki' is invalid for '--name <name>'. Please provide one of the following:
          - bruce
          - clint
          - hulk
          - natasha
          - steve
          - thor
          - tony
        """),
    ErrorCase(
      id: "invalid enum value for -n (many cases)",
      arguments: ["-f", "text", "-n", "loki"],
      expected: """
        The value 'loki' is invalid for '-n <name>'. Please provide one of the following:
          - bruce
          - clint
          - hulk
          - natasha
          - steve
          - thor
          - tony
        """),
  ]

  @Test(arguments: fooCases)
  func foo(_ c: ErrorCase) {
    expectErrorMessage(Foo.self, c.arguments, c.expected)
  }

  @Test func enumWithFewCasesArrayArgument() {
    expectErrorMessage(
      EnumWithFewCasesArrayArgument.self, ["png"],
      "The value 'png' is invalid for '<formats>'. Please provide one of 'text', 'json' or 'csv'."
    )
  }

  @Test func enumWithManyCasesArrayArgument() {
    expectErrorMessage(
      EnumWithManyCasesArrayArgument.self, ["loki"],
      """
      The value 'loki' is invalid for '<names>'. Please provide one of the following:
        - bruce
        - clint
        - hulk
        - natasha
        - steve
        - thor
        - tony
      """)
  }

  @Test func enumWithIntRawValue() {
    expectErrorMessage(
      EnumWithIntRawValue.self, ["--counter", "one"],
      """
      The value 'one' is invalid for '--counter <counter>'. \
      Please provide one of '1', '2', '3' or '4'.
      """)
  }
}

private struct Baz: ParsableArguments {
  @Flag
  var verbose: Bool = false
}

extension ErrorMessageTests {
  @Test func unexpectedValue() {
    expectErrorMessage(
      Baz.self, ["--verbose=foo"],
      "The option '--verbose' does not take any value, but 'foo' was specified."
    )
  }
}

private struct Qux: ParsableArguments {
  @Argument()
  var firstNumber: Int

  @Option(name: .customLong("number-two"))
  var secondNumber: Int
}

extension ErrorMessageTests {
  static let quxCases: [ErrorCase] = [
    ErrorCase(
      id: "missing <first-number>",
      arguments: ["--number-two", "2"],
      expected: "Missing expected argument '<first-number>'"),
    ErrorCase(
      id: "invalid <first-number>",
      arguments: ["--number-two", "2", "a"],
      expected: "The value 'a' is invalid for '<first-number>'"),
    ErrorCase(
      id: "invalid --number-two",
      arguments: ["--number-two", "a", "1"],
      expected: "The value 'a' is invalid for '--number-two <number-two>'"),
  ]

  @Test(arguments: quxCases)
  func qux(_ c: ErrorCase) {
    expectErrorMessage(Qux.self, c.arguments, c.expected)
  }
}

private struct Qwz: ParsableArguments {
  @Option() var name: String?
  @Option(name: [.customLong("title", withSingleDash: true)]) var title: String?
}

// https://github.com/apple/swift-argument-parser/issues/710
extension ErrorMessageTests {
  static let qwzCases: [ErrorCase] = [
    ErrorCase(
      id: "--nme suggests --name",
      arguments: ["--nme"],
      expected: "Unknown option '--nme'. Did you mean '--name'?"),
    ErrorCase(
      id: "-name suggests --name",
      arguments: ["-name"],
      expected: "Unknown option '-name'. Did you mean '--name'?"),
    ErrorCase(
      id: "-ttle suggests -title",
      arguments: ["-ttle"],
      expected: "Unknown option '-ttle'. Did you mean '-title'?"),
    ErrorCase(
      id: "--title suggests -title",
      arguments: ["--title"],
      expected: "Unknown option '--title'. Did you mean '-title'?"),
    ErrorCase(
      id: "--not-similar has no suggestion",
      arguments: ["--not-similar"],
      expected: "Unknown option '--not-similar'"),
    ErrorCase(
      id: "-x has no suggestion",
      arguments: ["-x"],
      expected: "Unknown option '-x'"),
  ]

  @Test(arguments: qwzCases)
  func qwz(_ c: ErrorCase) {
    expectErrorMessage(Qwz.self, c.arguments, c.expected)
  }
}

private struct Options: ParsableArguments {
  enum OutputBehaviour: String, EnumerableFlag {
    case stats, count, list

    static func name(for value: OutputBehaviour) -> NameSpecification {
      .shortAndLong
    }
  }

  @Flag(help: "Program output")
  var behaviour: OutputBehaviour = .list

  @Flag(inversion: .prefixedNo, exclusivity: .exclusive) var bool: Bool
}

private struct OptOptions: ParsableArguments {
  enum OutputBehaviour: String, EnumerableFlag {
    case stats, count, list

    static func name(for value: OutputBehaviour) -> NameSpecification {
      .short
    }
  }

  @Flag(help: "Program output")
  var behaviour: OutputBehaviour?
}

extension ErrorMessageTests {
  static let optionsCases: [ErrorCase] = [
    ErrorCase(
      id: "-s conflicts with --list",
      arguments: ["--list", "--bool", "-s"],
      expected:
        "Value to be set with flag \'-s\' had already been set with flag \'--list\'"
    ),
    ErrorCase(
      id: "combined -cbl: l conflicts with c",
      arguments: ["-cbl"],
      expected:
        "Value to be set with flag \'l\' in \'-cbl\' had already been set with flag \'c\' in \'-cbl\'"
    ),
    ErrorCase(
      id: "--stats conflicts with c in -bc",
      arguments: ["-bc", "--stats", "-l"],
      expected:
        "Value to be set with flag \'--stats\' had already been set with flag \'c\' in \'-bc\'"
    ),
    ErrorCase(
      id: "--bool conflicts with --no-bool",
      arguments: ["--no-bool", "--bool"],
      expected:
        "Value to be set with flag \'--bool\' had already been set with flag \'--no-bool\'"
    ),
  ]

  @Test(arguments: optionsCases)
  func options(_ c: ErrorCase) {
    expectErrorMessage(Options.self, c.arguments, c.expected)
  }

  @Test func optOptionsCombinedShort() {
    expectErrorMessage(
      OptOptions.self, ["-cbl"],
      "Value to be set with flag \'l\' in \'-cbl\' had already been set with flag \'c\' in \'-cbl\'"
    )
  }
}

// (see issue #434).
private struct EmptyArray: ParsableArguments {
  @Option(parsing: .upToNextOption)
  var array: [String] = []

  @Flag(name: [.short, .long])
  var verbose = false
}

extension ErrorMessageTests {
  static let emptyArrayCases: [ErrorCase] = [
    ErrorCase(
      id: "--array alone",
      arguments: ["--array"],
      expected: "Missing value for '--array <array>'"),
    ErrorCase(
      id: "--array followed by --verbose",
      arguments: ["--array", "--verbose"],
      expected: "Missing value for '--array <array>'"),
    ErrorCase(
      id: "-verbose followed by --array",
      arguments: ["-verbose", "--array"],
      expected: "Missing value for '--array <array>'"),
    ErrorCase(
      id: "--array followed by -v",
      arguments: ["--array", "-v"],
      expected: "Missing value for '--array <array>'"),
    ErrorCase(
      id: "-v followed by --array",
      arguments: ["-v", "--array"],
      expected: "Missing value for '--array <array>'"),
  ]

  @Test(arguments: emptyArrayCases)
  func emptyArray(_ c: ErrorCase) {
    expectErrorMessage(EmptyArray.self, c.arguments, c.expected)
  }
}

// MARK: -

private struct Repeat: ParsableArguments {
  @Option() var count: Int?
  @Argument() var phrase: String
}

extension ErrorMessageTests {
  @Test func badOptionBeforeArgument() {
    expectErrorMessage(
      Repeat.self,
      ["--cont", "5", "Hello"],
      "Unknown option '--cont'. Did you mean '--count'?")
  }
}
