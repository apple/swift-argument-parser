//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import ArgumentParser
import ArgumentParserTestHelpers
import Foundation
import XCTest

final class ResponseFileEndToEndTests: XCTestCase {

  override func setUp() {
    super.setUp()
    // Create test directory for response files
    try? FileManager.default.createDirectory(
      at: temporaryDirectory,
      withIntermediateDirectories: true,
      attributes: nil
    )
  }

  override func tearDown() {
    super.tearDown()
    // Clean up test files
    try? FileManager.default.removeItem(at: temporaryDirectory)
  }

  private var temporaryDirectory: URL {
    FileManager.default.temporaryDirectory
      .appendingPathComponent("ArgumentParserResponseFileTests")
  }

  private func createResponseFile(_ name: String, content: String) throws
    -> String
  {
    let fileURL = temporaryDirectory.appendingPathComponent(name)
    try content.write(to: fileURL, atomically: true, encoding: .utf8)
    return fileURL.path
  }
}

// MARK: - Test Commands

private struct SimpleCommand: ParsableCommand {
  @Option var name: String
  @Option var count: Int = 1
  @Flag var verbose = false
}

private struct MultipleArgsCommand: ParsableCommand {
  @Option var input: String
  @Option var output: String
  @Option var format: String = "json"
  @Flag var force = false
  @Flag var quiet = false
}

private struct PositionalCommand: ParsableCommand {
  @Argument var files: [String] = []
  @Option var output: String?
}

private struct SubcommandParent: ParsableCommand {
  static let configuration = CommandConfiguration(
    subcommands: [SubcommandChild.self]
  )

  @Flag var verbose: Bool = false
}

private struct SubcommandChild: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "subcommand-child")
  @Option var value: String
}

// MARK: - Basic Response File Tests

extension ResponseFileEndToEndTests {
  func testBasicResponseFile() throws {
    let responseFile = try createResponseFile(
      "args.txt",
      content: """
        --name
        TestName
        --count
        42
        --verbose
        """)

    AssertParse(SimpleCommand.self, ["@\(responseFile)"]) { command in
      XCTAssertEqual(command.name, "TestName")
      XCTAssertEqual(command.count, 42)
      XCTAssertTrue(command.verbose)
    }
  }

  func testResponseFileWithMixedArgs() throws {
    let responseFile = try createResponseFile(
      "partial.txt",
      content: """
        --name
        FromFile
        """)

    AssertParse(SimpleCommand.self, ["@\(responseFile)", "--count", "100"]) {
      command in
      XCTAssertEqual(command.name, "FromFile")
      XCTAssertEqual(command.count, 100)
      XCTAssertFalse(command.verbose)
    }
  }

  func testResponseFileWithMixedArgsLastWinsCLI() throws {
    let responseFile = try createResponseFile(
      "partial.txt",
      content: """
        --name
        FromFile
        --count
        2
        """)

    AssertParse(SimpleCommand.self, ["@\(responseFile)", "--count", "100"]) {
      command in
      XCTAssertEqual(command.name, "FromFile")
      XCTAssertEqual(command.count, 100)
      XCTAssertFalse(command.verbose)
    }
  }
  func testResponseFileWithMixedArgsLastWinsResponseFile() throws {
    let responseFile = try createResponseFile(
      "partial.txt",
      content: """
        --name
        FromFile
        --count
        2
        """)

    AssertParse(SimpleCommand.self, ["--count", "100", "@\(responseFile)"]) {
      command in
      XCTAssertEqual(command.name, "FromFile")
      XCTAssertEqual(command.count, 2)
      XCTAssertFalse(command.verbose)
    }
  }

  func testMultipleResponseFiles() throws {
    let file1 = try createResponseFile(
      "file1.txt",
      content: """
        --name
        TestName
        """)

    let file2 = try createResponseFile(
      "file2.txt",
      content: """
        --count
        50
        --verbose
        """)

    AssertParse(SimpleCommand.self, ["@\(file1)", "@\(file2)"]) { command in
      XCTAssertEqual(command.name, "TestName")
      XCTAssertEqual(command.count, 50)
      XCTAssertTrue(command.verbose)
    }
  }
}

// MARK: - Response File Formats

extension ResponseFileEndToEndTests {
  func testResponseFileOneArgPerLine() throws {
    let responseFile = try createResponseFile(
      "oneline.txt",
      content: """
        --input
        input.txt
        --output
        output.txt
        --format
        xml
        --force
        """)

    AssertParse(MultipleArgsCommand.self, ["@\(responseFile)"]) { command in
      XCTAssertEqual(command.input, "input.txt")
      XCTAssertEqual(command.output, "output.txt")
      XCTAssertEqual(command.format, "xml")
      XCTAssertTrue(command.force)
      XCTAssertFalse(command.quiet)
    }
  }

  func testResponseFileSpaceSeparated() throws {
    let responseFile = try createResponseFile(
      "spaced.txt",
      content: """
        --input input.txt --output output.txt --force
        """)

    AssertParse(MultipleArgsCommand.self, ["@\(responseFile)"]) { command in
      XCTAssertEqual(command.input, "input.txt")
      XCTAssertEqual(command.output, "output.txt")
      XCTAssertTrue(command.force)
    }
  }

  func testResponseFileWithQuotedArguments() throws {
    let responseFile = try createResponseFile(
      "quoted.txt",
      content: #"""
        --input "file with spaces.txt"
        --output 'another file.txt'
        """#)

    AssertParse(MultipleArgsCommand.self, ["@\(responseFile)"]) { command in
      XCTAssertEqual(command.input, "file with spaces.txt")
      XCTAssertEqual(command.output, "another file.txt")
    }
  }

  func testResponseFileWithComments() throws {
    let responseFile = try createResponseFile(
      "commented.txt",
      content: """
        # This is a comment
        --input
        input.txt
        # Another comment
        --output
        output.txt
        --force  # End of line comment
        """)

    AssertParse(MultipleArgsCommand.self, ["@\(responseFile)"]) { command in
      XCTAssertEqual(command.input, "input.txt")
      XCTAssertEqual(command.output, "output.txt")
      XCTAssertTrue(command.force)
    }
  }

  func testResponseFileWithEmptyLines() throws {
    let responseFile = try createResponseFile(
      "empty_lines.txt",
      content: """
        --input
        input.txt


        --output
        output.txt

        --force

        """)

    AssertParse(MultipleArgsCommand.self, ["@\(responseFile)"]) { command in
      XCTAssertEqual(command.input, "input.txt")
      XCTAssertEqual(command.output, "output.txt")
      XCTAssertTrue(command.force)
    }
  }
}

// MARK: - Nested Response Files

extension ResponseFileEndToEndTests {
  func testNestedResponseFiles() throws {
    let innerFile = try createResponseFile(
      "inner.txt",
      content: """
        --count
        42
        --verbose
        """)

    let outerFile = try createResponseFile(
      "outer.txt",
      content: """
        --name
        TestName
        @\(innerFile)
        """)

    AssertParse(SimpleCommand.self, ["@\(outerFile)"]) { command in
      XCTAssertEqual(command.name, "TestName")
      XCTAssertEqual(command.count, 42)
      XCTAssertTrue(command.verbose)
    }
  }

  func testRecursiveResponseFileDetection() throws {
    let file1 = try createResponseFile(
      "recursive1.txt",
      content: """
        --name
        Test
        @recursive2.txt
        """)

    let file2 = try createResponseFile(
      "recursive2.txt",
      content: """
        --count
        10
        @recursive1.txt
        """)

    // This should throw an error for recursive response files
    XCTAssertThrowsError(try SimpleCommand.parse(["@\(file1)"])) { error in
      // Verify it's an error (specific error type will be defined in implementation)
      // We'll validate the specific error type once the implementation is complete
    }
  }

  func testDeepNestedResponseFiles() throws {
    let level3 = try createResponseFile(
      "level3.txt",
      content: """
        --verbose
        """)

    let level2 = try createResponseFile(
      "level2.txt",
      content: """
        --count
        100
        @\(level3)
        """)

    let level1 = try createResponseFile(
      "level1.txt",
      content: """
        --name
        DeepNested
        @\(level2)
        """)

    AssertParse(SimpleCommand.self, ["@\(level1)"]) { command in
      XCTAssertEqual(command.name, "DeepNested")
      XCTAssertEqual(command.count, 100)
      XCTAssertTrue(command.verbose)
    }
  }
}

// MARK: - Positional Arguments

extension ResponseFileEndToEndTests {
  func testResponseFileWithPositionalArgs() throws {
    let responseFile = try createResponseFile(
      "positional.txt",
      content: """
        file1.txt
        file2.txt
        file3.txt
        --output
        result.txt
        """)

    AssertParse(PositionalCommand.self, ["@\(responseFile)"]) { command in
      XCTAssertEqual(command.files, ["file1.txt", "file2.txt", "file3.txt"])
      XCTAssertEqual(command.output, "result.txt")
    }
  }

  func testResponseFileWithPositionalAndRegularArgs() throws {
    let responseFile = try createResponseFile(
      "mixed_pos.txt",
      content: """
        fromfile1.txt
        fromfile2.txt
        """)

    AssertParse(
      PositionalCommand.self,
      ["regular1.txt", "@\(responseFile)", "regular2.txt"]
    ) { command in
      XCTAssertEqual(
        command.files,
        ["regular1.txt", "fromfile1.txt", "fromfile2.txt", "regular2.txt"])
    }
  }
}

// MARK: - Subcommands

extension ResponseFileEndToEndTests {
  func testResponseFileWithSubcommands() throws {
    let responseFile = try createResponseFile(
      "subcommand.txt",
      content: """
        subcommand-child
        --value
        TestValue
        """)

    AssertParseCommand(
      SubcommandParent.self, SubcommandChild.self, ["@\(responseFile)"]
    ) { command in
      XCTAssertEqual(command.value, "TestValue")
    }
  }

  func testResponseFileBeforeSubcommand() throws {
    let responseFile = try createResponseFile(
      "before_sub.txt",
      content: """
        # Global options would go here if SubcommandParent had any
        """)

    AssertParseCommand(
      SubcommandParent.self, SubcommandChild.self,
      ["@\(responseFile)", "subcommand-child", "--value", "Test"]
    ) { command in
      XCTAssertEqual(command.value, "Test")
    }
  }
}

// MARK: - Error Cases

extension ResponseFileEndToEndTests {
  func testNonexistentResponseFile() throws {
    XCTAssertThrowsError(try SimpleCommand.parse(["@/nonexistent/file.txt"])) {
      error in
      // Should throw a file not found error
    }
  }

  func testInvalidResponseFilePermissions() throws {
    let responseFile = try createResponseFile(
      "noaccess.txt", content: "--name Test")

    // Remove read permissions (this may not work in all test environments)
    try? FileManager.default.setAttributes(
      [.posixPermissions: 0o000],
      ofItemAtPath: responseFile
    )

    XCTAssertThrowsError(try SimpleCommand.parse(["@\(responseFile)"])) {
      error in
      // Should throw a permission error
    }

    // Restore permissions for cleanup
    try? FileManager.default.setAttributes(
      [.posixPermissions: 0o644],
      ofItemAtPath: responseFile
    )
  }

  func testEmptyResponseFile() throws {
    let responseFile = try createResponseFile("empty.txt", content: "")

    // Empty response file should be valid and not add any arguments
    AssertParse(SimpleCommand.self, ["@\(responseFile)", "--name", "Test"]) {
      command in
      XCTAssertEqual(command.name, "Test")
      XCTAssertEqual(command.count, 1)  // default value
      XCTAssertFalse(command.verbose)
    }
  }

  func testMalformedArgumentsInResponseFile() throws {
    let responseFile = try createResponseFile(
      "malformed.txt",
      content: """
        --name
        # Missing value for --name
        --count
        notanumber
        """)

    XCTAssertThrowsError(try SimpleCommand.parse(["@\(responseFile)"])) {
      error in
      // Should throw parsing error for invalid arguments
    }
  }
}

// MARK: - Edge Cases

extension ResponseFileEndToEndTests {
  func testResponseFileNameWithSpaces() throws {
    let responseFile = try createResponseFile(
      "file with spaces.txt",
      content: """
        --name
        Test
        """)

    AssertParse(SimpleCommand.self, ["@\(responseFile)"]) { command in
      XCTAssertEqual(command.name, "Test")
    }
  }

  func testLiteralAtSignArgument() throws {
    // Test that we can still pass literal @something arguments
    // This would need special escaping mechanism, like @@file.txt for literal @file.txt
    let responseFile = try createResponseFile(
      "literal.txt",
      content: """
        --name
        @@notafile
        """)

    AssertParse(SimpleCommand.self, ["@\(responseFile)"]) { command in
      XCTAssertEqual(command.name, "@notafile")
    }
  }

  func testResponseFileWithTerminator() throws {
    let responseFile = try createResponseFile(
      "terminator.txt",
      content: """
        --output
        result.txt
        --
        file1.txt
        file2.txt
        """)

    AssertParse(PositionalCommand.self, ["@\(responseFile)"]) { command in
      XCTAssertEqual(command.files, ["file1.txt", "file2.txt"])
      XCTAssertEqual(command.output, "result.txt")
    }
  }

  func testResponseFileWithEqualsFormat() throws {
    let responseFile = try createResponseFile(
      "equals.txt",
      content: """
        --name=TestName
        --count=42
        """)

    AssertParse(SimpleCommand.self, ["@\(responseFile)"]) { command in
      XCTAssertEqual(command.name, "TestName")
      XCTAssertEqual(command.count, 42)
    }
  }

  func testVeryLargeResponseFile() throws {
    // Test with a response file containing many arguments
    var content = ""
    for i in 1...1000 {
      content += "arg\(i).txt\n"
    }
    let responseFile = try createResponseFile("large.txt", content: content)

    AssertParse(PositionalCommand.self, ["@\(responseFile)"]) { command in
      XCTAssertEqual(command.files.count, 1000)
      XCTAssertEqual(command.files.first, "arg1.txt")
      XCTAssertEqual(command.files.last, "arg1000.txt")
    }
  }
}

// MARK: - Configuration Options

extension ResponseFileEndToEndTests {
  // These tests will verify that response file support can be configured
  // The actual configuration mechanism will be defined during implementation

  func testDisableResponseFileSupport() throws {
    // Test that response file support can be disabled per command
    // This would be implemented as a configuration option
    // For now, this is a placeholder for the feature

    // When disabled, @file should be treated as a literal argument
    // Implementation details TBD
  }

  func testCustomResponseFilePrefix() throws {
    // Test that the @ prefix can be customized
    // This would allow using different prefixes like +file or -file
    // Implementation details TBD
  }

  func testResponseFileSearchPaths() throws {
    // Test that response files can be searched in multiple directories
    // Implementation details TBD
  }
}

// MARK: - AsyncParsableCommand Support Tests

extension ResponseFileEndToEndTests {
  func testResponseFileWithAsyncParsableCommand() throws {
    let responseFile = try createResponseFile(
      "async-args.txt",
      content: """
        --name
        AsyncTest
        --count
        42
        """)

    struct AsyncTestCommand: AsyncParsableCommand {
      @Option var name: String
      @Option var count: Int

      func run() async throws {
        // Test command that uses async
      }
    }

    AssertParse(AsyncTestCommand.self, ["@\(responseFile)"]) { command in
      XCTAssertEqual(command.name, "AsyncTest")
      XCTAssertEqual(command.count, 42)
    }
  }

  func testResponseFileWithAsyncSubcommand() throws {
    let responseFile = try createResponseFile(
      "async-sub-args.txt",
      content: """
        sub
        --value
        AsyncSubTest
        """)

    struct AsyncParentCommand: AsyncParsableCommand {
      static let configuration = CommandConfiguration(
        commandName: "async-parent",
        subcommands: [AsyncSubCommand.self]
      )
    }

    struct AsyncSubCommand: AsyncParsableCommand {
      static let configuration = CommandConfiguration(commandName: "sub")
      @Option var value: String

      func run() async throws {
        // Async subcommand implementation
      }
    }

    AssertParseCommand(
      AsyncParentCommand.self, AsyncSubCommand.self, ["@\(responseFile)"]
    ) { command in
      XCTAssertEqual(command.value, "AsyncSubTest")
    }
  }

  func testResponseFileWithMixedAsyncArgs() throws {
    let responseFile = try createResponseFile(
      "mixed-async.txt",
      content: """
        --input
        input.txt
        --async-flag
        """)

    struct MixedAsyncCommand: AsyncParsableCommand {
      @Option var input: String
      @Option var output: String = "default.txt"
      @Flag var asyncFlag: Bool = false

      func run() async throws {
        // Mixed args async command
      }
    }

    AssertParse(
      MixedAsyncCommand.self, ["@\(responseFile)", "--output", "override.txt"]
    ) { command in
      XCTAssertEqual(command.input, "input.txt")
      // CLI arg overrides default
      XCTAssertEqual(command.output, "override.txt")
      XCTAssertTrue(command.asyncFlag)
    }
  }
}
