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

import ArgumentParserTestHelpers
import Foundation
import Testing

@testable import ArgumentParser

extension ResponseFileExpander {
  fileprivate init(maxNestingDepth: Int = 32) {
    self.init(prefix: "@", maxNestingDepth: maxNestingDepth)
  }

  /// Test helper: tokenize `input` as a single response-file line and
  /// return the first token's value.
  ///
  /// Preserves the ergonomics of the removed `parseQuotedArgument` for the
  /// quote-focused tests below, while routing through the actual production
  /// entry point.
  fileprivate mutating func firstToken(
    _ input: String, from fileURL: URL
  ) throws -> String {
    guard let token = try parseFileContent(input, fileURL: fileURL).first
    else { return "" }
    return token.value
  }
}

@Suite struct ResponseFileExpanderTests {}

// MARK: - ResponseFileExpander Unit Tests

extension ResponseFileExpanderTests {

  @Test func expandArgumentsWithNoResponseFiles() throws {
    var expander = ResponseFileExpander()
    let input = ["--name", "test", "--count", "42"]
    let result = try expander.expandArguments(input)

    #expect(
      result.arguments.map { $0.value } == input,
      "Arguments without @ prefix should remain unchanged")
    #expect(
      !result.hasResponseFile,
      "hasResponseFile should be false when no @file is present")
    #expect(
      result.arguments.map { $0.chain }
        == [
          [.argv(index: 0)], [.argv(index: 1)], [.argv(index: 2)],
          [.argv(index: 3)],
        ],
      "Argv-only args should each carry a single-step argv chain")
  }

  @Test func expandArgumentsWithSingleResponseFile() async throws {
    try await withTemporaryFile(
      "simple.txt",
      content: """
        --name
        TestName
        --count
        42
        """
    ) { responseFile in
      var expander = ResponseFileExpander()
      let input = ["@\(responseFile)"]
      let result = try expander.expandArguments(input)

      #expect(
        result.arguments.map { $0.value }
          == ["--name", "TestName", "--count", "42"])
      #expect(result.hasResponseFile)
      // Every expanded arg should carry a chain ending in argv[0].
      #expect(result.arguments.count == 4)
      for arg in result.arguments {
        #expect(arg.chain.last == .argv(index: 0))
      }
    }
  }

  @Test func expandArgumentsMixedResponseFileAndRegular() async throws {
    try await withTemporaryFile(
      "mixed.txt",
      content: """
        --name
        FromFile
        """
    ) { responseFile in
      var expander = ResponseFileExpander()
      let input = ["--verbose", "@\(responseFile)", "--count", "100"]
      let result = try expander.expandArguments(input)

      #expect(
        result.arguments.map { $0.value }
          == ["--verbose", "--name", "FromFile", "--count", "100"])
      #expect(result.hasResponseFile)
    }
  }
}

// MARK: - File Content Parsing Tests

extension ResponseFileExpanderTests {

  @Test func parseFileContentOneArgumentPerLine() throws {
    let content = """
      --input
      input.txt
      --output
      output.txt
      --force
      """

    var expander = ResponseFileExpander()
    let result = try expander.parseFileContent(
      content, fileURL: URL(fileURLWithPath: "test.txt"))

    #expect(
      result.map { $0.value }
        == ["--input", "input.txt", "--output", "output.txt", "--force"])
  }

  @Test func parseFileContentSpaceSeparated() throws {
    let content = "--input input.txt --output output.txt --force"

    var expander = ResponseFileExpander()
    let result = try expander.parseFileContent(
      content, fileURL: URL(fileURLWithPath: "test.txt"))

    #expect(
      result.map { $0.value }
        == ["--input", "input.txt", "--output", "output.txt", "--force"])
  }

  @Test func parseFileContentWithQuotes() throws {
    let content = #"""
      --input "file with spaces.txt"
      --output 'another file.txt'
      --message "hello world"
      """#

    var expander = ResponseFileExpander()
    let result = try expander.parseFileContent(
      content, fileURL: URL(fileURLWithPath: "test.txt"))

    #expect(
      result.map { $0.value }
        == [
          "--input", "file with spaces.txt",
          "--output", "another file.txt",
          "--message", "hello world",
        ])
  }

  @Test func parseFileContentWithComments() throws {
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
    let result = try expander.parseFileContent(
      content, fileURL: URL(fileURLWithPath: "test.txt"))

    #expect(
      result.map { $0.value }
        == ["--input", "input.txt", "--output", "output.txt", "--force"])
  }

  @Test func parseFileContentWithEmptyLines() throws {
    let content = """
      --input
      input.txt


      --output
      output.txt

      --force

      """

    var expander = ResponseFileExpander()
    let result = try expander.parseFileContent(
      content, fileURL: URL(fileURLWithPath: "test.txt"))

    #expect(
      result.map { $0.value }
        == ["--input", "input.txt", "--output", "output.txt", "--force"])
  }

  @Test func parseFileContentWithEqualsFormat() throws {
    let content = """
      --input=input.txt
      --output=output.txt
      --count=42
      """

    var expander = ResponseFileExpander()
    let result = try expander.parseFileContent(
      content, fileURL: URL(fileURLWithPath: "test.txt"))

    #expect(
      result.map { $0.value }
        == ["--input=input.txt", "--output=output.txt", "--count=42"])
  }

  @Test func parseFileContentWithEscapedAtSign() throws {
    let content = """
      --name
      @@literal
      --value
      @@@another
      """

    var expander = ResponseFileExpander()
    let result = try expander.parseFileContent(
      content, fileURL: URL(fileURLWithPath: "test.txt"))

    #expect(
      result.map { $0.value }
        == ["--name", "@literal", "--value", "@@another"])
  }
}

// MARK: - Nested Response File Tests

extension ResponseFileExpanderTests {

  @Test func expandNestedResponseFiles() async throws {
    try await withTemporaryDirectory { dir in
      let innerFile = try dir.createTestFile(
        "inner.txt",
        content: """
          --count
          42
          --verbose
          """)

      let outerFile = try dir.createTestFile(
        "outer.txt",
        content: """
          --name
          TestName
          @\(innerFile)
          """)

      var expander = ResponseFileExpander()
      let input = ["@\(outerFile)"]
      let result = try expander.expandArguments(input)

      #expect(
        result.arguments.map { $0.value }
          == ["--name", "TestName", "--count", "42", "--verbose"])
    }
  }

  @Test func expandDeepNestedResponseFiles() async throws {
    try await withTemporaryDirectory { dir in
      let level3 = try dir.createTestFile("level3.txt", content: "--verbose")
      let level2 = try dir.createTestFile(
        "level2.txt",
        content: """
          --count
          100
          @\(level3)
          """)
      let level1 = try dir.createTestFile(
        "level1.txt",
        content: """
          --name
          DeepTest
          @\(level2)
          """)

      var expander = ResponseFileExpander()
      let input = ["@\(level1)"]
      let result = try expander.expandArguments(input)

      #expect(
        result.arguments.map { $0.value }
          == ["--name", "DeepTest", "--count", "100", "--verbose"])
    }
  }

  @Test func recursiveResponseFileDetection() async throws {
    try await withTemporaryDirectory { dir in
      let file1 = try dir.createTestFile(
        "recursive1.txt",
        content: """
          --name
          Test
          @recursive2.txt
          """)

      _ = try dir.createTestFile(
        "recursive2.txt",
        content: """
          --count
          10
          @recursive1.txt
          """)

      var expander = ResponseFileExpander()
      let input = ["@\(file1)"]

      #expect(throws: (any Error).self) {
        try expander.expandArguments(input)
      }

      do {
        _ = try expander.expandArguments(input)
        Issue.record("Expected ResponseFileError")
      } catch let responseError as ResponseFileExpander.ResponseFileError {
        if case .recursiveInclude(let url) = responseError {
          #expect(url.path.contains("recursive"))
        } else {
          Issue.record("Expected recursiveInclude error, got \(responseError)")
        }
      } catch {
        Issue.record("Expected ResponseFileError, got \(type(of: error))")
      }
    }
  }

  @Test func selfRecursiveResponseFile() async throws {
    try await withTemporaryFile(
      "self.txt",
      content: """
        --name
        Test
        @self.txt
        """
    ) { selfFile in
      var expander = ResponseFileExpander()
      let input = ["@\(selfFile)"]

      do {
        _ = try expander.expandArguments(input)
        Issue.record("Expected ResponseFileError")
      } catch let responseError as ResponseFileExpander.ResponseFileError {
        if case .recursiveInclude = responseError {
          // Expected behavior
        } else {
          Issue.record("Expected recursiveInclude error, got \(responseError)")
        }
      } catch {
        Issue.record("Expected ResponseFileError, got \(type(of: error))")
      }
    }
  }
}

// MARK: - Error Handling Tests

extension ResponseFileExpanderTests {

  @Test func fileNotFoundError() throws {
    var expander = ResponseFileExpander()
    let input = ["@/nonexistent/file.txt"]

    do {
      _ = try expander.expandArguments(input)
      Issue.record("Expected ResponseFileError")
    } catch let responseError as ResponseFileExpander.ResponseFileError {
      if case .fileNotFound = responseError {
        // Expected behavior
      } else {
        Issue.record("Expected fileNotFound error, got \(responseError)")
      }
    } catch {
      Issue.record("Expected ResponseFileError, got \(type(of: error))")
    }
  }

  @Test func filePermissionError() async throws {
    try await withTemporaryFile(
      "restricted.txt", content: "--name Test"
    ) { restrictedFile in
      // Remove read permissions
      try FileManager.default.setAttributes(
        [.posixPermissions: 0o000],
        ofItemAtPath: restrictedFile
      )
      defer {
        // Restore permissions for cleanup
        try? FileManager.default.setAttributes(
          [.posixPermissions: 0o644],
          ofItemAtPath: restrictedFile
        )
      }

      // Skip on platforms/environments where POSIX permissions don't
      // actually restrict reads — most notably root inside a Docker
      // container (root bypasses mode bits) and Windows (NTFS ACLs, not
      // POSIX modes, gate access).
      guard !FileManager.default.isReadableFile(atPath: restrictedFile) else {
        return
      }

      var expander = ResponseFileExpander()
      let input = ["@\(restrictedFile)"]

      do {
        _ = try expander.expandArguments(input)
        Issue.record("Expected ResponseFileError")
      } catch let responseError as ResponseFileExpander.ResponseFileError {
        if case .readError = responseError {
          // Expected behavior
        } else {
          Issue.record("Expected readError, got \(responseError)")
        }
      } catch {
        Issue.record("Expected ResponseFileError, got \(type(of: error))")
      }
    }
  }

  @Test func emptyResponseFile() async throws {
    try await withTemporaryFile("empty.txt", content: "") { emptyFile in
      var expander = ResponseFileExpander()
      let input = ["@\(emptyFile)", "--name", "test"]
      let result = try expander.expandArguments(input)

      #expect(result.arguments.map { $0.value } == ["--name", "test"])
    }
  }

  @Test func unclosedQuotesTerminateAtEndOfFile() throws {
    // Once a token opens a quoted segment, it keeps consuming input —
    // including intervening newlines and any subsequent characters —
    // until it either encounters a matching quote or reaches EOF, at
    // which point the accumulated content becomes a single token.
    let content = #"""
      --input "unclosed quote
      --output 'another unclosed
      """#

    var expander = ResponseFileExpander()
    let result = try expander.parseFileContent(
      content, fileURL: URL(fileURLWithPath: "test.txt"))

    #expect(
      result.map { $0.value }
        == [
          "--input",
          "unclosed quote\n--output 'another unclosed",
        ])
  }
}

// MARK: - Quote Parsing Tests

extension ResponseFileExpanderTests {

  @Test func parseQuotedArguments() throws {
    var expander = ResponseFileExpander()
    let fileUrl = URL(fileURLWithPath: "usedForReporting.txt")

    // Test double quotes
    let doubleQuoted = #""hello world""#
    let result1 = try expander.firstToken(doubleQuoted, from: fileUrl)
    #expect(result1 == "hello world")

    // Test single quotes
    let singleQuoted = "'hello world'"
    let result2 = try expander.firstToken(singleQuoted, from: fileUrl)
    #expect(result2 == "hello world")

    // Test unquoted
    let unquoted = "hello"
    let result3 = try expander.firstToken(unquoted, from: fileUrl)
    #expect(result3 == "hello")
  }

  @Test func parseQuotedArgumentsWithEscapes() throws {
    var expander = ResponseFileExpander()
    let fileUrl = URL(fileURLWithPath: "usedForReporting.txt")

    // Test escaped quotes within double quotes
    let escaped = #""hello \"world\"""#
    let result = try expander.firstToken(escaped, from: fileUrl)
    #expect(result == #"hello "world""#)
  }

  @Test func parseQuotedArgumentsWithInternalQuotes() throws {
    var expander = ResponseFileExpander()
    let fileUrl = URL(fileURLWithPath: "usedForReporting.txt")

    // Test single quotes within double quotes
    let mixed = #""hello 'world'""#
    let result = try expander.firstToken(mixed, from: fileUrl)
    #expect(result == "hello 'world'")
  }
}

// MARK: - Quote parsing — documented behaviors
//
// These tests pin the behaviors promised by
// `Sources/ArgumentParser/Documentation.docc/Articles/ResponseFiles.md`
// under "Quoted Arguments". Each test corresponds to one bullet or
// example in that section.

extension ResponseFileExpanderTests {
  private var fileUrl: URL {
    URL(fileURLWithPath: "usedForReporting.txt")
  }

  // MARK: Escape sequences (double quotes only)

  @Test func doubleQuotesDecodeNewlineEscape() throws {
    var expander = ResponseFileExpander()
    let result = try expander.firstToken(
      #""line one\nline two""#, from: fileUrl)
    #expect(result == "line one\nline two")
  }

  @Test func doubleQuotesDecodeTabEscape() throws {
    var expander = ResponseFileExpander()
    let result = try expander.firstToken(
      #""col1\tcol2""#, from: fileUrl)
    #expect(result == "col1\tcol2")
  }

  @Test func doubleQuotesDecodeCarriageReturnEscape() throws {
    var expander = ResponseFileExpander()
    let result = try expander.firstToken(
      #""left\rright""#, from: fileUrl)
    #expect(result == "left\rright")
  }

  @Test func doubleQuotesDecodeBackslashEscape() throws {
    var expander = ResponseFileExpander()
    let result = try expander.firstToken(
      #""C:\\Users\\Bob\\file.txt""#, from: fileUrl)
    #expect(result == #"C:\Users\Bob\file.txt"#)
  }

  @Test func doubleQuotesPreserveUnknownEscapeVerbatim() throws {
    // `\d` isn't a recognized escape, so it should survive verbatim
    // rather than silently dropping the backslash.
    var expander = ResponseFileExpander()
    let result = try expander.firstToken(
      #""foo\dbar""#, from: fileUrl)
    #expect(result == #"foo\dbar"#)
  }

  // MARK: Single quotes preserve everything literally

  @Test func singleQuotesPreserveBackslashesLiterally() throws {
    var expander = ResponseFileExpander()
    let result = try expander.firstToken(
      #"'foo\d+\.bar'"#, from: fileUrl)
    #expect(result == #"foo\d+\.bar"#)
  }

  @Test func singleQuotesPreserveDoubleQuotesLiterally() throws {
    var expander = ResponseFileExpander()
    let result = try expander.firstToken(
      #"'{"key": "value"}'"#, from: fileUrl)
    #expect(result == #"{"key": "value"}"#)
  }

  @Test func singleQuotesDoNotProcessEscapeSequences() throws {
    // The documented pitfall: `\n` inside single quotes is 2 literal
    // characters, not a newline.
    var expander = ResponseFileExpander()
    let result = try expander.firstToken(
      #"'a\nb'"#, from: fileUrl)
    #expect(result == #"a\nb"#)
  }

  // MARK: Nested quotes

  @Test func doubleQuotesPreserveInternalSingleQuotesUnescaped() throws {
    var expander = ResponseFileExpander()
    let result = try expander.firstToken(
      #""SELECT * FROM 'users'""#, from: fileUrl)
    #expect(result == "SELECT * FROM 'users'")
  }

  @Test func singleQuotesPreserveInternalDoubleQuotesUnescaped() throws {
    var expander = ResponseFileExpander()
    let result = try expander.firstToken(
      #"'the "special" one'"#, from: fileUrl)
    #expect(result == #"the "special" one"#)
  }

  // MARK: Whitespace preservation

  @Test func quotedValuesPreserveInternalWhitespace() throws {
    var expander = ResponseFileExpander()
    let content = #"""
      --title "Grand Total"
      --tags  '  keep   the   spaces  '
      """#
    let result = try expander.parseFileContent(
      content, fileURL: URL(fileURLWithPath: "test.txt"))
    #expect(
      result.map { $0.value }
        == ["--title", "Grand Total", "--tags", "  keep   the   spaces  "])
  }

  // MARK: `@file` inside a quoted argument is literal

  @Test func doubleQuotedAtPrefixIsLiteralValue() throws {
    // The `@` in `"@admin"` must NOT trigger a response-file lookup —
    // otherwise this test would throw `.fileNotFound`.
    var expander = ResponseFileExpander()
    let content = #"""
      --username "@admin"
      """#
    let result = try expander.parseFileContent(
      content, fileURL: URL(fileURLWithPath: "test.txt"))
    #expect(
      result.map { $0.value }
        == ["--username", "@admin"])
  }

  @Test func singleQuotedAtPrefixIsLiteralValue() throws {
    var expander = ResponseFileExpander()
    let content = #"""
      --pattern '@daily'
      """#
    let result = try expander.parseFileContent(
      content, fileURL: URL(fileURLWithPath: "test.txt"))
    #expect(
      result.map { $0.value }
        == ["--pattern", "@daily"])
  }

  // MARK: Mixed-quote value round-tripped through parseFileContent

  @Test func doubleQuotedJSONValueRoundTripsThroughParseFileContent() throws {
    var expander = ResponseFileExpander()
    let content = #"""
      --json '{"key": "value"}'
      """#
    let result = try expander.parseFileContent(
      content, fileURL: URL(fileURLWithPath: "test.txt"))
    #expect(
      result.map { $0.value }
        == ["--json", #"{"key": "value"}"#])
  }

  // MARK: Mismatched-style quotes are implicitly terminated

  @Test func mismatchedQuoteStyleOpensDoubleClosesSingle() throws {
    // Opening `"` and closing `'` is an unterminated double-quote as
    // far as the parser is concerned — the trailing `'` is literal
    // content inside the open double-quoted segment, and the whole
    // thing implicitly terminates at end-of-line.
    var expander = ResponseFileExpander()
    let content = #"""
      --title "unterminated'
      """#
    let result = try expander.parseFileContent(
      content, fileURL: URL(fileURLWithPath: "test.txt"))
    #expect(result.map { $0.value } == ["--title", "unterminated'"])
  }

  @Test func mismatchedQuoteStyleOpensSingleClosesDouble() throws {
    var expander = ResponseFileExpander()
    let content = #"""
      --title 'unterminated"
      """#
    let result = try expander.parseFileContent(
      content, fileURL: URL(fileURLWithPath: "test.txt"))
    #expect(result.map { $0.value } == ["--title", #"unterminated""#])
  }
}

// MARK: - Comment Stripping Tests

extension ResponseFileExpanderTests {

  @Test func stripComments() throws {
    let expander = ResponseFileExpander()

    // Test full line comment
    #expect(expander.stripComment("# This is a comment") == "")

    // Test end of line comment
    #expect(expander.stripComment("--name test # comment") == "--name test")

    // Test no comment
    #expect(expander.stripComment("--name test") == "--name test")

    // Test comment within quotes (should not be stripped)
    #expect(
      expander.stripComment(#"--message "hello # world""#)
        == #"--message "hello # world""#)
  }

  @Test func stripCommentsWithQuotedContent() throws {
    let expander = ResponseFileExpander()

    // Comments inside quotes should be preserved
    let quotedComment =
      #"--message "hello # this is not a comment" # but this is"#
    let result = expander.stripComment(quotedComment)
    #expect(result == #"--message "hello # this is not a comment""#)
  }
}

// MARK: - Response File Detection Tests

extension ResponseFileExpanderTests {

  @Test func isResponseFileArgument() throws {
    let expander = ResponseFileExpander()

    #expect(expander.isResponseFileArgument("@file.txt"))
    #expect(expander.isResponseFileArgument("@/path/to/file.txt"))
    #expect(expander.isResponseFileArgument("@file with spaces.txt"))

    #expect(!expander.isResponseFileArgument("--option"))
    #expect(!expander.isResponseFileArgument("value"))
    // Double @ is literal
    #expect(!expander.isResponseFileArgument("@@literal"))
    #expect(!expander.isResponseFileArgument(""))
    // Just @ without filename
    #expect(!expander.isResponseFileArgument("@"))
  }

  @Test func extractResponseFileName() throws {
    let expander = ResponseFileExpander()

    #expect(expander.extractResponseFileName("@file.txt") == "file.txt")
    #expect(
      expander.extractResponseFileName("@/path/to/file.txt")
        == "/path/to/file.txt")
    #expect(
      expander.extractResponseFileName("@file with spaces.txt")
        == "file with spaces.txt")

    #expect(expander.extractResponseFileName("--option") == nil)
    #expect(expander.extractResponseFileName("@@literal") == nil)
    #expect(expander.extractResponseFileName("@") == nil)
  }
}

// MARK: - Configuration Tests (Future)

extension ResponseFileExpanderTests {

  @Test func customPrefix() throws {
    // Test ability to use custom prefixes like +file or -file
    // This will be implemented as a configuration option

    let expander = ResponseFileExpander(prefix: "+")

    #expect(expander.isResponseFileArgument("+file.txt"))
    #expect(!expander.isResponseFileArgument("@file.txt"))
  }

  @Test func maxNestingDepth() async throws {
    // Test that we can limit nesting depth to prevent deep recursion
    // This will be implemented as a configuration option

    try await withTemporaryDirectory { dir in
      var expander = ResponseFileExpander(maxNestingDepth: 2)

      // Create deeply nested files that exceed the limit
      let level3 = try dir.createTestFile("deep3.txt", content: "--verbose")
      let level2 = try dir.createTestFile("deep2.txt", content: "@\(level3)")
      let level1 = try dir.createTestFile("deep1.txt", content: "@\(level2)")
      let level0 = try dir.createTestFile("deep0.txt", content: "@\(level1)")

      let input = ["@\(level0)"]

      do {
        _ = try expander.expandArguments(input)
        Issue.record("Expected ResponseFileError")
      } catch let responseError as ResponseFileExpander.ResponseFileError {
        if case .maxNestingDepthExceeded = responseError {
          // Expected behavior
        } else {
          Issue.record("Expected maxNestingDepthExceeded error")
        }
      } catch {
        Issue.record("Expected ResponseFileError")
      }
    }
  }
}

// MARK: - Performance Tests

extension ResponseFileExpanderTests {

  @Test func largeResponseFile() async throws {
    // Test performance with a large number of arguments
    var content = ""
    for i in 1...10000 {
      content += "arg\(i)\n"
    }

    try await withTemporaryFile("large.txt", content: content) { largeFile in
      var expander = ResponseFileExpander()
      let input = ["@\(largeFile)"]

      let clock: ContinuousClock = ContinuousClock()
      let startTime = clock.now
      let result = try expander.expandArguments(input)
      let endTime = clock.now

      #expect(result.arguments.count == 10000)
      #expect(
        endTime - startTime
          < Duration(secondsComponent: 1, attosecondsComponent: 0),
        "Should process large file within 1 second")
    }
  }

  @Test func manySmallResponseFiles() async throws {
    // Test performance with many small response files
    try await withTemporaryDirectory { dir in
      var files: [String] = []

      for i in 1...100 {
        let file = try dir.createTestFile(
          "small\(i).txt", content: "--arg\(i) value\(i)")
        files.append("@\(file)")
      }

      var expander = ResponseFileExpander()

      let clock: ContinuousClock = ContinuousClock()
      let startTime = clock.now
      let result = try expander.expandArguments(files)
      let endTime = clock.now

      #expect(result.arguments.count == 200)  // 100 files * 2 args each
      #expect(
        endTime - startTime
          < Duration(secondsComponent: 1, attosecondsComponent: 0),
        "Should process many files within 1 second"
      )
    }
  }
}
