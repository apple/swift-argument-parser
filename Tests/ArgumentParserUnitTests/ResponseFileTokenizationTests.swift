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
import Testing

@testable import ArgumentParser

// Unit-level tests for the response-file tokenizer: how raw file
// content is split into tokens, how quoted segments behave, how
// comments and escapes are handled. These tests exercise
// `parseFileContent`/`tokenizeContent` directly on
// `ResponseFileExpander`, without a `ParsableCommand` round trip.
//
// End-to-end tokenization behavior — the same rules observed through
// `expectParse` on a real command — lives in
// `Tests/ArgumentParserEndToEndTests/ResponseFileEndToEndTests.swift`.

extension ResponseFileExpander {
  /// Convenience init defaulting the prefix to `"@"`.
  ///
  /// Duplicated from `ResponseFileExpanderTests.swift` so both files
  /// can build expanders without repeating the prefix argument.
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

@Suite struct ResponseFileTokenizationTests {
  @Suite struct FileContentParsingTests {}
  @Suite struct QuoteParsingTests {}
  @Suite struct CommentStrippingTests {}
}

// MARK: - File Content Parsing Tests

extension ResponseFileTokenizationTests.FileContentParsingTests {

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

extension ResponseFileTokenizationTests.QuoteParsingTests {

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

extension ResponseFileTokenizationTests.QuoteParsingTests {
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

extension ResponseFileTokenizationTests.CommentStrippingTests {

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
