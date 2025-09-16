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

  func testRepeatingOptionProperty() throws {
    // Test that swiftArgumentParserRepeating is set correctly for repeating options
    let actual: String
    do {
      _ = try CommandWithOptions.parse(["--help-dump-opencli-v0.1"])
      XCTFail("Expected parsing to fail with OpenCLI dump request")
      return
    } catch {
      actual = CommandWithOptions.fullMessage(for: error)
    }

    // Parse the JSON output
    let jsonData = actual.data(using: .utf8)!
    let openCLI = try JSONDecoder().decode(OpenCLIv0_1.self, from: jsonData)

    // Find the repeating option
    guard let options = openCLI.options else {
      XCTFail("Expected options to be present")
      return
    }

    // Find the items option (which uses .upToNextOption parsing)
    let itemsOption = options.first { $0.name == "--items" }
    XCTAssertNotNil(itemsOption, "Expected to find --items option")
    XCTAssertEqual(
      itemsOption?.swiftArgumentParserRepeating, true,
      "Expected items option to have swiftArgumentParserRepeating set to true")

    // Find a non-repeating option to verify it doesn't have the property set
    let configOption = options.first { $0.name == "-c" }
    XCTAssertNotNil(configOption, "Expected to find -c option")
    XCTAssertNil(
      configOption?.swiftArgumentParserRepeating,
      "Expected non-repeating option to have swiftArgumentParserRepeating as nil"
    )
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
    let openCLI = try JSONDecoder().decode(OpenCLIv0_1.self, from: jsonData)

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
    let openCLI = try JSONDecoder().decode(OpenCLIv0_1.self, from: jsonData)

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

  func testFileDirectoryCompletionProperties() throws {
    // Test that swiftArgumentParserFile and swiftArgumentParserDirectory are set correctly
    let actual: String
    do {
      _ = try CommandWithFileCompletion.parse(["--help-dump-opencli-v0.1"])
      XCTFail("Expected parsing to fail with OpenCLI dump request")
      return
    } catch {
      actual = CommandWithFileCompletion.fullMessage(for: error)
    }

    // Parse the JSON output
    let jsonData = actual.data(using: .utf8)!
    let openCLI = try JSONDecoder().decode(OpenCLIv0_1.self, from: jsonData)

    // Find the file option
    guard let options = openCLI.options else {
      XCTFail("Expected options to be present")
      return
    }

    let fileOption = options.first { $0.name == "--file" }
    XCTAssertNotNil(fileOption, "Expected to find --file option")
    XCTAssertEqual(
      fileOption?.swiftArgumentParserFile, true,
      "Expected file option to have swiftArgumentParserFile set to true")
    XCTAssertNil(
      fileOption?.swiftArgumentParserDirectory,
      "Expected file option to have swiftArgumentParserDirectory as nil")

    // Find the directory option
    let dirOption = options.first { $0.name == "--dir" }
    XCTAssertNotNil(dirOption, "Expected to find --dir option")
    XCTAssertEqual(
      dirOption?.swiftArgumentParserDirectory, true,
      "Expected directory option to have swiftArgumentParserDirectory set to true"
    )
    XCTAssertNil(
      dirOption?.swiftArgumentParserFile,
      "Expected directory option to have swiftArgumentParserFile as nil")

    // Find a regular option to verify it doesn't have completion properties set
    let regularOption = options.first { $0.name == "--regular" }
    XCTAssertNotNil(regularOption, "Expected to find --regular option")
    XCTAssertNil(
      regularOption?.swiftArgumentParserFile,
      "Expected regular option to have swiftArgumentParserFile as nil")
    XCTAssertNil(
      regularOption?.swiftArgumentParserDirectory,
      "Expected regular option to have swiftArgumentParserDirectory as nil")

    // Check arguments
    guard let arguments = openCLI.arguments else {
      XCTFail("Expected arguments to be present")
      return
    }

    let fileArg = arguments.first { $0.name == "input-file" }
    XCTAssertNotNil(fileArg, "Expected to find input-file argument")
    XCTAssertEqual(
      fileArg?.swiftArgumentParserFile, true,
      "Expected file argument to have swiftArgumentParserFile set to true")
    XCTAssertNil(
      fileArg?.swiftArgumentParserDirectory,
      "Expected file argument to have swiftArgumentParserDirectory as nil")

    let dirArg = arguments.first { $0.name == "output-dir" }
    XCTAssertNotNil(dirArg, "Expected to find output-dir argument")
    XCTAssertEqual(
      dirArg?.swiftArgumentParserDirectory, true,
      "Expected directory argument to have swiftArgumentParserDirectory set to true"
    )
    XCTAssertNil(
      dirArg?.swiftArgumentParserFile,
      "Expected directory argument to have swiftArgumentParserFile as nil")
  }
}

extension OpenCLIDumpHelpGenerationTests {
  struct A: ParsableCommand {
    enum TestEnum: String, CaseIterable, ExpressibleByArgument {
      case a = "one"
      case b = "two"
      case c = "three"
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

    @Option(
      help: .init(
        discussion:
          "A preamble for the list of values in the discussion section."))
    var extra: Color

    @Option(help: .init(discussion: "A discussion."))
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

    @Option(name: [.short, .long], help: "Input file path")
    var input: String?

    @Argument(help: "Output file path")
    var output: String
  }

  struct SubCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "sub",
      abstract: "A subcommand"
    )

    @Option(help: "Sub option")
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

    @Option(
      name: [.customShort("c"), .customLong("config")],
      help: "Configuration file")
    var configFile: String?

    @Option(parsing: .upToNextOption, help: "Repeating option")
    var items: [String] = []

    @Argument(help: "Required argument")
    var required: String

    @Argument(help: "Optional argument")
    var optional: String?
  }

  struct CommandWithFileCompletion: ParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "file-completion",
      abstract: "Command with file and directory completion"
    )

    @Option(help: "File option", completion: .file())
    var file: String?

    @Option(help: "Directory option", completion: .directory)
    var dir: String?

    @Option(help: "Regular option without completion")
    var regular: String?

    @Argument(help: "Input file", completion: .file())
    var inputFile: String

    @Argument(help: "Output directory", completion: .directory)
    var outputDir: String
  }
}
