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
@testable import ArgumentParser

final class DumpHelpGenerationTests: XCTestCase {
  let snapshotsDirectory = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .appendingPathComponent("Snapshots")

  func url(_ test: StaticString = #function) -> URL {
    return self.snapshotsDirectory.appendingPathComponent("\(test).json")
  }

  public func testADumpHelp() throws {
    try AssertDump(type: A.self, expected: self.url())
  }

  public func testBDumpHelp() throws {
    try AssertDump(type: B.self, expected: self.url())
  }

  public func testCDumpHelp() throws {
    try AssertDump(type: C.self, expected: self.url())
  }

  func testMathDumpHelp() throws {
    try AssertDump(command: "math", expected: self.url())
  }

  func testMathAddDumpHelp() throws {
    try AssertDump(command: "math add", expected: self.url())
  }

  func testMathMultiplyDumpHelp() throws {
    try AssertDump(command: "math multiply", expected: self.url())
  }

  func testMathStatsDumpHelp() throws {
    try AssertDump(command: "math stats", expected: self.url())
  }
}

extension DumpHelpGenerationTests {
  struct A: ParsableCommand {
    enum TestEnum: String, CaseIterable, ExpressibleByArgument {
      case a = "one", b = "two", c = "three"
    }

    @Option
    var enumeratedOption: TestEnum

    @Option
    var enumeratedOptionWithDefaultValue: TestEnum = .b

    @Option
    var noHelpOption: Int

    @Option(help: "int value option")
    var intOption: Int

    @Option(help: "int value option with default value")
    var intOptionWithDefaultValue: Int = 0

    @Argument
    var arg: Int

    @Argument(help: "argument with help")
    var argWithHelp: Int

    @Argument(help: "argument with default value")
    var argWithDefaultValue: Int = 1
  }

  struct Options: ParsableArguments {
    @Flag
    var verbose = false

    @Option
    var name: String
  }

  struct B: ParsableCommand {
    @OptionGroup(title: "Other")
    var options: Options
  }

  struct C: ParsableCommand {
    static let configuration = CommandConfiguration(shouldDisplay: false)

    enum Color: String, CaseIterable, ExpressibleByArgument {
      case blue
      case red
      case yellow

      var defaultValueDescription: String {
        switch self {
        case .blue:
          return "A blue color, like the sky!"
        case .red:
          return "A red color, like a rose!"
        case .yellow:
          return "A yellow color, like the sun!"
        }
      }
    }

    @Option(help: "A color to select.")
    var color: Color

    @Option(help: "Another color to select!")
    var defaultColor: Color = .red

    @Option(help: "An optional color.")
    var opt: Color?

    @Option(help: .init(discussion: "A preamble for the list of values in the discussion section."))
    var extra: Color

    @Option(help: .init(discussion: "A discussion."))
    var discussion: String
  }
}
