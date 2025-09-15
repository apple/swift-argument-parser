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

import ArgumentParserTestHelpers
import XCTest

@testable import ArgumentParser
@testable import ArgumentParserOpenCLI

final class OpenCLIDumpHelpGenerationTests: XCTestCase {
  public func testADumpOpenCLI() throws {
    try assertDumpOpenCLI(type: A.self)
  }

  public func testBDumpOpenCLI() throws {
    try assertDumpOpenCLI(type: B.self)
  }

  public func testCDumpOpenCLI() throws {
    try assertDumpOpenCLI(type: C.self)
  }

  func testMathDumpOpenCLI() throws {
    try assertDumpOpenCLI(command: "math")
  }

  func testMathAddDumpOpenCLI() throws {
    try assertDumpOpenCLI(command: "math add")
  }

  func testMathMultiplyDumpOpenCLI() throws {
    try assertDumpOpenCLI(command: "math multiply")
  }

  func testMathStatsDumpOpenCLI() throws {
    try assertDumpOpenCLI(command: "math stats")
  }

  func testSimpleCommandDumpOpenCLI() throws {
    try assertDumpOpenCLI(type: SimpleCommand.self)
  }

  func testNestedCommandDumpOpenCLI() throws {
    try assertDumpOpenCLI(type: ParentCommand.self)
  }

  func testCommandWithOptionsDumpOpenCLI() throws {
    try assertDumpOpenCLI(type: CommandWithOptions.self)
  }

  func testOpenCLIJSONStructure() throws {
    // Test that the JSON structure matches OpenCLI schema
    let actual: String
    do {
      _ = try SimpleCommand.parse(["--help-dump-opencli-v0.1"])
      XCTFail("Expected parsing to fail with OpenCLI dump request")
      return
    } catch {
      actual = SimpleCommand.fullMessage(for: error)
    }

    // Parse the JSON to validate structure
    let jsonData = actual.data(using: .utf8)!
    let openCLI = try JSONDecoder().decode(OpenCLI.self, from: jsonData)

    // Validate required fields
    XCTAssertEqual(openCLI.opencli, "0.1")
    XCTAssertEqual(openCLI.info.title, "simple")
    XCTAssertEqual(openCLI.info.version, "1.0.0")
    XCTAssertEqual(openCLI.info.summary, "A simple command for testing")

    // Validate options
    XCTAssertNotNil(openCLI.options)
    let options = openCLI.options!
    XCTAssertTrue(
      options.contains { $0.name == "--verbose" || $0.name == "-v" })
    XCTAssertTrue(options.contains { $0.name == "--input" || $0.name == "-i" })

    // Validate arguments
    XCTAssertNotNil(openCLI.arguments)
    let arguments = openCLI.arguments!
    XCTAssertTrue(arguments.contains { $0.name == "output" })
  }

  func testNestedCommandStructure() throws {
    // Test nested command structure
    let actual: String
    do {
      _ = try ParentCommand.parse(["--help-dump-opencli-v0.1"])
      XCTFail("Expected parsing to fail with OpenCLI dump request")
      return
    } catch {
      actual = ParentCommand.fullMessage(for: error)
    }

    let jsonData = actual.data(using: .utf8)!
    let openCLI = try JSONDecoder().decode(OpenCLI.self, from: jsonData)

    // Validate parent command
    XCTAssertEqual(openCLI.info.title, "parent")
    XCTAssertEqual(openCLI.info.summary, "A parent command with subcommands")

    // Validate subcommands exist
    XCTAssertNotNil(openCLI.commands)
    let commands = openCLI.commands!
    XCTAssertTrue(commands.contains { $0.name == "sub" })

    // Validate subcommand structure
    let subCommand = commands.first { $0.name == "sub" }!
    XCTAssertEqual(subCommand.description, "A subcommand")
    XCTAssertNotNil(subCommand.options)
  }
}

extension OpenCLIDumpHelpGenerationTests {
  struct A: ParsableCommand {
    enum TestEnum: String, CaseIterable, ExpressibleByArgument {
      case a = "one"
      case b = "two"
      case c = "three"
    }

    @ArgumentParser.Option
    var enumeratedOption: TestEnum

    @ArgumentParser.Option
    var enumeratedOptionWithDefaultValue: TestEnum = .b

    @ArgumentParser.Option
    var noHelpOption: Int

    @ArgumentParser.Option(help: "int value option")
    var intOption: Int

    @ArgumentParser.Option(help: "int value option with default value")
    var intOptionWithDefaultValue: Int = 0

    @ArgumentParser.Argument
    var arg: Int

    @ArgumentParser.Argument(help: "argument with help")
    var argWithHelp: Int

    @ArgumentParser.Argument(help: "argument with default value")
    var argWithDefaultValue: Int = 1
  }

  struct Options: ParsableArguments {
    @Flag
    var verbose = false

    @ArgumentParser.Option
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

    @ArgumentParser.Option(help: "A color to select.")
    var color: Color

    @ArgumentParser.Option(help: "Another color to select!")
    var defaultColor: Color = .red

    @ArgumentParser.Option(help: "An optional color.")
    var opt: Color?

    @ArgumentParser.Option(
      help: .init(
        discussion:
          "A preamble for the list of values in the discussion section."))
    var extra: Color

    @ArgumentParser.Option(help: .init(discussion: "A discussion."))
    var discussion: String
  }

  struct SimpleCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "simple",
      abstract: "A simple command for testing",
      version: "1.0.0"
    )

    @Flag(name: [.short, .long], help: "Show verbose output")
    var verbose: Bool = false

    @ArgumentParser.Option(name: [.short, .long], help: "Input file path")
    var input: String?

    @ArgumentParser.Argument(help: "Output file path")
    var output: String
  }

  struct SubCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "sub",
      abstract: "A subcommand"
    )

    @ArgumentParser.Option(help: "Sub option")
    var value: Int = 42
  }

  struct ParentCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "parent",
      abstract: "A parent command with subcommands",
      subcommands: [SubCommand.self]
    )

    @Flag(help: "Global flag")
    var global: Bool = false
  }

  struct CommandWithOptions: ParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "options",
      abstract: "Command with various option types"
    )

    @Flag(name: .shortAndLong, help: "Help flag")
    var help: Bool = false

    @ArgumentParser.Option(
      name: [.customShort("c"), .customLong("config")],
      help: "Configuration file")
    var configFile: String?

    @ArgumentParser.Option(parsing: .upToNextOption, help: "Repeating option")
    var items: [String] = []

    @ArgumentParser.Argument(help: "Required argument")
    var required: String

    @ArgumentParser.Argument(help: "Optional argument")
    var optional: String?
  }
}
