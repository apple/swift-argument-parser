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

import Foundation
import XCTest

@testable import ArgumentParser

final class ResponseFileExpanderTests: XCTestCase {

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
      .appendingPathComponent("ResponseFileExpanderUnitTests")
  }

  private func createTestFile(_ name: String, content: String) throws -> String
  {
    let fileURL = temporaryDirectory.appendingPathComponent(name)
    try content.write(to: fileURL, atomically: true, encoding: .utf8)
    return fileURL.path
  }
}

// MARK: - ResponseFileExpander Unit Tests

extension ResponseFileExpanderTests {

  func testExpandArgumentsWithNoResponseFiles() throws {
    var expander = ResponseFileExpander()
    let input = ["--name", "test", "--count", "42"]
    let result = try expander.expandArguments(input)

    XCTAssertEqual(
      result, input, "Arguments without @ prefix should remain unchanged")
  }

  func testExpandArgumentsWithSingleResponseFile() throws {
    let responseFile = try createTestFile(
      "simple.txt",
      content: """
        --name
        TestName
        --count
        42
        """)

    var expander = ResponseFileExpander()
    let input = ["@\(responseFile)"]
    let result = try expander.expandArguments(input)

    XCTAssertEqual(result, ["--name", "TestName", "--count", "42"])
  }

  func testExpandArgumentsMixedResponseFileAndRegular() throws {
    let responseFile = try createTestFile(
      "mixed.txt",
      content: """
        --name
        FromFile
        """)

    var expander = ResponseFileExpander()
    let input = ["--verbose", "@\(responseFile)", "--count", "100"]
    let result = try expander.expandArguments(input)

    XCTAssertEqual(
      result, ["--verbose", "--name", "FromFile", "--count", "100"])
  }
}

// MARK: - File Content Parsing Tests

extension ResponseFileExpanderTests {

  func testParseFileContentOneArgumentPerLine() throws {
    let content = """
      --input
      input.txt
      --output
      output.txt
      --force
      """

    var expander = ResponseFileExpander()
    let result = try expander.parseFileContent(content, filePath: "test.txt")

    XCTAssertEqual(
      result, ["--input", "input.txt", "--output", "output.txt", "--force"])
  }

  func testParseFileContentSpaceSeparated() throws {
    let content = "--input input.txt --output output.txt --force"

    var expander = ResponseFileExpander()
    let result = try expander.parseFileContent(content, filePath: "test.txt")

    XCTAssertEqual(
      result, ["--input", "input.txt", "--output", "output.txt", "--force"])
  }

  func testParseFileContentWithQuotes() throws {
    let content = #"""
      --input "file with spaces.txt"
      --output 'another file.txt'
      --message "hello world"
      """#

    var expander = ResponseFileExpander()
    let result = try expander.parseFileContent(content, filePath: "test.txt")

    XCTAssertEqual(
      result,
      [
        "--input", "file with spaces.txt",
        "--output", "another file.txt",
        "--message", "hello world",
      ])
  }

  func testParseFileContentWithComments() throws {
    let content = """
      # This is a comment
      --input
      input.txt  # End of line comment
      # Another comment
      --output
      output.txt
      --force
      """

    var expander = ResponseFileExpander()
    let result = try expander.parseFileContent(content, filePath: "test.txt")

    XCTAssertEqual(
      result, ["--input", "input.txt", "--output", "output.txt", "--force"])
  }

  func testParseFileContentWithEmptyLines() throws {
    let content = """
      --input
      input.txt


      --output
      output.txt

      --force

      """

    var expander = ResponseFileExpander()
    let result = try expander.parseFileContent(content, filePath: "test.txt")

    XCTAssertEqual(
      result, ["--input", "input.txt", "--output", "output.txt", "--force"])
  }

  func testParseFileContentWithEqualsFormat() throws {
    let content = """
      --input=input.txt
      --output=output.txt
      --count=42
      """

    var expander = ResponseFileExpander()
    let result = try expander.parseFileContent(content, filePath: "test.txt")

    XCTAssertEqual(
      result, ["--input=input.txt", "--output=output.txt", "--count=42"])
  }

  func testParseFileContentWithEscapedAtSign() throws {
    let content = """
      --name
      @@literal
      --value
      @@@another
      """

    var expander = ResponseFileExpander()
    let result = try expander.parseFileContent(content, filePath: "test.txt")

    XCTAssertEqual(result, ["--name", "@literal", "--value", "@@another"])
  }
}

// MARK: - Nested Response File Tests

extension ResponseFileExpanderTests {

  func testExpandNestedResponseFiles() throws {
    let innerFile = try createTestFile(
      "inner.txt",
      content: """
        --count
        42
        --verbose
        """)

    let outerFile = try createTestFile(
      "outer.txt",
      content: """
        --name
        TestName
        @\(innerFile)
        """)

    var expander = ResponseFileExpander()
    let input = ["@\(outerFile)"]
    let result = try expander.expandArguments(input)

    XCTAssertEqual(
      result, ["--name", "TestName", "--count", "42", "--verbose"])
  }

  func testExpandDeepNestedResponseFiles() throws {
    let level3 = try createTestFile("level3.txt", content: "--verbose")
    let level2 = try createTestFile(
      "level2.txt",
      content: """
        --count
        100
        @\(level3)
        """)
    let level1 = try createTestFile(
      "level1.txt",
      content: """
        --name
        DeepTest
        @\(level2)
        """)

    var expander = ResponseFileExpander()
    let input = ["@\(level1)"]
    let result = try expander.expandArguments(input)

    XCTAssertEqual(
      result, ["--name", "DeepTest", "--count", "100", "--verbose"])
  }

  func testRecursiveResponseFileDetection() throws {
    let file1 = try createTestFile(
      "recursive1.txt",
      content: """
        --name
        Test
        @recursive2.txt
        """)

    let _ = try createTestFile(
      "recursive2.txt",
      content: """
        --count
        10
        @recursive1.txt
        """)

    var expander = ResponseFileExpander()
    let input = ["@\(file1)"]

    XCTAssertThrowsError(try expander.expandArguments(input)) { error in
      guard let responseError = error as? ResponseFileExpander.ResponseFileError
      else {
        XCTFail("Expected ResponseFileError, got \(type(of: error))")
        return
      }

      if case .recursiveInclude(let path) = responseError {
        XCTAssertTrue(path.contains("recursive"))
      } else {
        XCTFail("Expected recursiveInclude error, got \(responseError)")
      }
    }
  }

  func testSelfRecursiveResponseFile() throws {
    let selfFile = try createTestFile(
      "self.txt",
      content: """
        --name
        Test
        @self.txt
        """)

    var expander = ResponseFileExpander()
    let input = ["@\(selfFile)"]

    XCTAssertThrowsError(try expander.expandArguments(input)) { error in
      guard let responseError = error as? ResponseFileExpander.ResponseFileError
      else {
        XCTFail("Expected ResponseFileError, got \(type(of: error))")
        return
      }

      if case .recursiveInclude = responseError {
        // Expected behavior
      } else {
        XCTFail("Expected recursiveInclude error, got \(responseError)")
      }
    }
  }
}

// MARK: - Error Handling Tests

extension ResponseFileExpanderTests {

  func testFileNotFoundError() throws {
    var expander = ResponseFileExpander()
    let input = ["@/nonexistent/file.txt"]

    XCTAssertThrowsError(try expander.expandArguments(input)) { error in
      guard let responseError = error as? ResponseFileExpander.ResponseFileError
      else {
        XCTFail("Expected ResponseFileError, got \(type(of: error))")
        return
      }

      if case .fileNotFound = responseError {
        // Expected behavior
      } else {
        XCTFail("Expected fileNotFound error, got \(responseError)")
      }
    }
  }

  func testFilePermissionError() throws {
    let restrictedFile = try createTestFile(
      "restricted.txt", content: "--name Test")

    // Remove read permissions
    try FileManager.default.setAttributes(
      [.posixPermissions: 0o000],
      ofItemAtPath: restrictedFile
    )

    var expander = ResponseFileExpander()
    let input = ["@\(restrictedFile)"]

    XCTAssertThrowsError(try expander.expandArguments(input)) { error in
      guard let responseError = error as? ResponseFileExpander.ResponseFileError
      else {
        XCTFail("Expected ResponseFileError, got \(type(of: error))")
        return
      }

      if case .readError = responseError {
        // Expected behavior
      } else {
        XCTFail("Expected readError, got \(responseError)")
      }
    }

    // Restore permissions for cleanup
    try? FileManager.default.setAttributes(
      [.posixPermissions: 0o644],
      ofItemAtPath: restrictedFile
    )
  }

  func testEmptyResponseFile() throws {
    let emptyFile = try createTestFile("empty.txt", content: "")

    var expander = ResponseFileExpander()
    let input = ["@\(emptyFile)", "--name", "test"]
    let result = try expander.expandArguments(input)

    XCTAssertEqual(result, ["--name", "test"])
  }

  func testMalformedQuotes() throws {
    let content = #"""
      --input "unclosed quote
      --output 'another unclosed
      """#

    var expander = ResponseFileExpander()

    XCTAssertThrowsError(
      try expander.parseFileContent(content, filePath: "test.txt")
    ) { error in
      guard let responseError = error as? ResponseFileExpander.ResponseFileError
      else {
        XCTFail("Expected ResponseFileError, got \(type(of: error))")
        return
      }

      if case .malformedContent = responseError {
        // Expected behavior
      } else {
        XCTFail("Expected malformedContent error, got \(responseError)")
      }
    }
  }
}

// MARK: - Quote Parsing Tests

extension ResponseFileExpanderTests {

  func testParseQuotedArguments() throws {
    var expander = ResponseFileExpander()

    // Test double quotes
    let doubleQuoted = #""hello world""#
    let result1 = try expander.parseQuotedArgument(doubleQuoted)
    XCTAssertEqual(result1, "hello world")

    // Test single quotes
    let singleQuoted = "'hello world'"
    let result2 = try expander.parseQuotedArgument(singleQuoted)
    XCTAssertEqual(result2, "hello world")

    // Test unquoted
    let unquoted = "hello"
    let result3 = try expander.parseQuotedArgument(unquoted)
    XCTAssertEqual(result3, "hello")
  }

  func testParseQuotedArgumentsWithEscapes() throws {
    var expander = ResponseFileExpander()

    // Test escaped quotes within double quotes
    let escaped = #""hello \"world\"""#
    let result = try expander.parseQuotedArgument(escaped)
    XCTAssertEqual(result, #"hello "world""#)
  }

  func testParseQuotedArgumentsWithInternalQuotes() throws {
    var expander = ResponseFileExpander()

    // Test single quotes within double quotes
    let mixed = #""hello 'world'""#
    let result = try expander.parseQuotedArgument(mixed)
    XCTAssertEqual(result, "hello 'world'")
  }
}

// MARK: - Comment Stripping Tests

extension ResponseFileExpanderTests {

  func testStripComments() throws {
    var expander = ResponseFileExpander()

    // Test full line comment
    XCTAssertEqual(expander.stripComment("# This is a comment"), "")

    // Test end of line comment
    XCTAssertEqual(
      expander.stripComment("--name test # comment"), "--name test")

    // Test no comment
    XCTAssertEqual(expander.stripComment("--name test"), "--name test")

    // Test comment within quotes (should not be stripped)
    XCTAssertEqual(
      expander.stripComment(#"--message "hello # world""#),
      #"--message "hello # world""#)
  }

  func testStripCommentsWithQuotedContent() throws {
    var expander = ResponseFileExpander()

    // Comments inside quotes should be preserved
    let quotedComment =
      #"--message "hello # this is not a comment" # but this is"#
    let result = expander.stripComment(quotedComment)
    XCTAssertEqual(result, #"--message "hello # this is not a comment""#)
  }
}

// MARK: - Response File Detection Tests

extension ResponseFileExpanderTests {

  func testIsResponseFileArgument() throws {
    let expander = ResponseFileExpander()

    XCTAssertTrue(expander.isResponseFileArgument("@file.txt"))
    XCTAssertTrue(expander.isResponseFileArgument("@/path/to/file.txt"))
    XCTAssertTrue(expander.isResponseFileArgument("@file with spaces.txt"))

    XCTAssertFalse(expander.isResponseFileArgument("--option"))
    XCTAssertFalse(expander.isResponseFileArgument("value"))
    // Double @ is literal
    XCTAssertFalse(expander.isResponseFileArgument("@@literal"))
    XCTAssertFalse(expander.isResponseFileArgument(""))
    // Just @ without filename
    XCTAssertFalse(expander.isResponseFileArgument("@"))
  }

  func testExtractResponseFileName() throws {
    let expander = ResponseFileExpander()

    XCTAssertEqual(expander.extractResponseFileName("@file.txt"), "file.txt")
    XCTAssertEqual(
      expander.extractResponseFileName("@/path/to/file.txt"),
      "/path/to/file.txt")
    XCTAssertEqual(
      expander.extractResponseFileName("@file with spaces.txt"),
      "file with spaces.txt")

    XCTAssertNil(expander.extractResponseFileName("--option"))
    XCTAssertNil(expander.extractResponseFileName("@@literal"))
    XCTAssertNil(expander.extractResponseFileName("@"))
  }
}

// MARK: - Configuration Tests (Future)

extension ResponseFileExpanderTests {

  func testCustomPrefix() throws {
    // Test ability to use custom prefixes like +file or -file
    // This will be implemented as a configuration option

    let expander = ResponseFileExpander(prefix: "+")

    XCTAssertTrue(expander.isResponseFileArgument("+file.txt"))
    XCTAssertFalse(expander.isResponseFileArgument("@file.txt"))
  }

  func testMaxNestingDepth() throws {
    // Test that we can limit nesting depth to prevent deep recursion
    // This will be implemented as a configuration option

    var expander = ResponseFileExpander(maxNestingDepth: 2)

    // Create deeply nested files that exceed the limit
    let level3 = try createTestFile("deep3.txt", content: "--verbose")
    let level2 = try createTestFile("deep2.txt", content: "@\(level3)")
    let level1 = try createTestFile("deep1.txt", content: "@\(level2)")
    let level0 = try createTestFile("deep0.txt", content: "@\(level1)")

    let input = ["@\(level0)"]

    XCTAssertThrowsError(try expander.expandArguments(input)) { error in
      guard let responseError = error as? ResponseFileExpander.ResponseFileError
      else {
        XCTFail("Expected ResponseFileError")
        return
      }

      if case .maxNestingDepthExceeded = responseError {
        // Expected behavior
      } else {
        XCTFail("Expected maxNestingDepthExceeded error")
      }
    }
  }
}

// MARK: - Performance Tests

extension ResponseFileExpanderTests {

  func testLargeResponseFile() throws {
    // Test performance with a large number of arguments
    var content = ""
    for i in 1...10000 {
      content += "arg\(i)\n"
    }

    let largeFile = try createTestFile("large.txt", content: content)

    var expander = ResponseFileExpander()
    let input = ["@\(largeFile)"]

    let clock: ContinuousClock = ContinuousClock()
    let startTime = clock.now
    let result = try expander.expandArguments(input)
    let endTime = clock.now

    XCTAssertEqual(result.count, 10000)
    XCTAssertLessThan(
      endTime - startTime,
      Duration(secondsComponent: 1, attosecondsComponent: 0),
      "Should process large file within 1 second")
  }

  func testManySmallResponseFiles() throws {
    // Test performance with many small response files
    var files: [String] = []

    for i in 1...100 {
      let file = try createTestFile(
        "small\(i).txt", content: "--arg\(i) value\(i)")
      files.append("@\(file)")
    }

    var expander = ResponseFileExpander()

    let clock: ContinuousClock = ContinuousClock()
    let startTime = clock.now
    let result = try expander.expandArguments(files)
    let endTime = clock.now

    XCTAssertEqual(result.count, 200)  // 100 files * 2 args each
    XCTAssertLessThan(
      endTime - startTime,
      Duration(secondsComponent: 1, attosecondsComponent: 0),
      "Should process many files within 1 second"
    )
  }
}
