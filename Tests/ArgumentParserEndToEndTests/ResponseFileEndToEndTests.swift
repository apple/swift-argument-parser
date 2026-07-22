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
import Testing

@Suite struct ResponseFileEndToEndTests {}

// MARK: - Test Commands

private struct SimpleCommand: ParsableCommand {
  static var responseFilePrefix: Character? { "@" }

  @Option var name: String
  @Option var count: Int = 1
  @Flag var verbose = false
}

private struct MultipleArgsCommand: ParsableCommand {
  static var responseFilePrefix: Character? { "@" }

  @Option var input: String
  @Option var output: String
  @Option var format: String = "json"
  @Flag var force = false
  @Flag var quiet = false
}

private struct PositionalCommand: ParsableCommand {
  static var responseFilePrefix: Character? { "@" }

  @Argument var files: [String] = []
  @Option var output: String?
}

private struct PlusPrefixCommand: ParsableCommand {
  static var responseFilePrefix: Character? { "+" }

  @Option var name: String
  @Option var count: Int = 1
  @Flag var verbose = false
  @Argument var files: [String] = []
}

private struct HashPrefixCommand: ParsableCommand {
  static var responseFilePrefix: Character? { "#" }

  @Argument var files: [String] = []
}

private struct PlusPrefixSubcommandParent: ParsableCommand {
  static var responseFilePrefix: Character? { "+" }
  static let configuration = CommandConfiguration(
    subcommands: [SubcommandChild.self]
  )
}

private struct SubcommandParent: ParsableCommand {
  static var responseFilePrefix: Character? { "@" }
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
  @Test func basicResponseFile() async throws {
    try await withTemporaryFile(
      "args.txt",
      content: """
        --name
        TestName
        --count
        42
        --verbose
        """
    ) { responseFile in
      expectParse(SimpleCommand.self, ["@\(responseFile)"]) { command in
        #expect(command.name == "TestName")
        #expect(command.count == 42)
        #expect(command.verbose == true)
      }
    }
  }

  @Test func responseFileWithMixedArgs() async throws {
    try await withTemporaryFile(
      "partial.txt",
      content: """
        --name
        FromFile
        """
    ) { responseFile in
      expectParse(SimpleCommand.self, ["@\(responseFile)", "--count", "100"]) {
        command in
        #expect(command.name == "FromFile")
        #expect(command.count == 100)
        #expect(command.verbose == false)
      }
    }
  }

  @Test func responseFileWithMixedArgsLastWinsCLI() async throws {
    try await withTemporaryFile(
      "partial.txt",
      content: """
        --name
        FromFile
        --count
        2
        """
    ) { responseFile in
      expectParse(SimpleCommand.self, ["@\(responseFile)", "--count", "100"]) {
        command in
        #expect(command.name == "FromFile")
        #expect(command.count == 100)
        #expect(command.verbose == false)
      }
    }
  }

  @Test func responseFileWithMixedArgsLastWinsResponseFile() async throws {
    try await withTemporaryFile(
      "partial.txt",
      content: """
        --name
        FromFile
        --count
        2
        """
    ) { responseFile in
      expectParse(SimpleCommand.self, ["--count", "100", "@\(responseFile)"]) {
        command in
        #expect(command.name == "FromFile")
        #expect(command.count == 2)
        #expect(command.verbose == false)
      }
    }
  }

  @Test func multipleResponseFiles() async throws {
    try await withTemporaryDirectory { dir in
      let file1 = try dir.createTestFile(
        "file1.txt",
        content: """
          --name
          TestName
          """)

      let file2 = try dir.createTestFile(
        "file2.txt",
        content: """
          --count
          50
          --verbose
          """)

      expectParse(SimpleCommand.self, ["@\(file1)", "@\(file2)"]) { command in
        #expect(command.name == "TestName")
        #expect(command.count == 50)
        #expect(command.verbose == true)
      }
    }
  }
}

// MARK: - Response File Formats

extension ResponseFileEndToEndTests {
  @Test func responseFileOneArgPerLine() async throws {
    try await withTemporaryFile(
      "oneline.txt",
      content: """
        --input
        input.txt
        --output
        output.txt
        --format
        xml
        --force
        """
    ) { responseFile in
      expectParse(MultipleArgsCommand.self, ["@\(responseFile)"]) { command in
        #expect(command.input == "input.txt")
        #expect(command.output == "output.txt")
        #expect(command.format == "xml")
        #expect(command.force == true)
        #expect(command.quiet == false)
      }
    }
  }

  @Test func responseFileSpaceSeparated() async throws {
    try await withTemporaryFile(
      "spaced.txt",
      content: """
        --input input.txt --output output.txt --force
        """
    ) { responseFile in
      expectParse(MultipleArgsCommand.self, ["@\(responseFile)"]) { command in
        #expect(command.input == "input.txt")
        #expect(command.output == "output.txt")
        #expect(command.force == true)
      }
    }
  }

  @Test func responseFileWithQuotedArguments() async throws {
    try await withTemporaryFile(
      "quoted.txt",
      content: #"""
        --input "file with spaces.txt"
        --output 'another file.txt'
        """#
    ) { responseFile in
      expectParse(MultipleArgsCommand.self, ["@\(responseFile)"]) { command in
        #expect(command.input == "file with spaces.txt")
        #expect(command.output == "another file.txt")
      }
    }
  }

  @Test func responseFileWithComments() async throws {
    try await withTemporaryFile(
      "commented.txt",
      content: """
        # This is a comment
        --input
        input.txt
        # Another comment
        --output
        output.txt
        --force  # End of line comment
        """
    ) { responseFile in
      expectParse(MultipleArgsCommand.self, ["@\(responseFile)"]) { command in
        #expect(command.input == "input.txt")
        #expect(command.output == "output.txt")
        #expect(command.force == true)
      }
    }
  }

  @Test func responseFileWithEmptyLines() async throws {
    try await withTemporaryFile(
      "empty_lines.txt",
      content: """
        --input
        input.txt


        --output
        output.txt

        --force

        """
    ) { responseFile in
      expectParse(MultipleArgsCommand.self, ["@\(responseFile)"]) { command in
        #expect(command.input == "input.txt")
        #expect(command.output == "output.txt")
        #expect(command.force == true)
      }
    }
  }
}

// MARK: - Quoted Empty String Positional Arguments

// Response files must preserve empty string arguments produced by quoted
// empty tokens (`""` or `''`) when they land in an `@Argument` collection.
// Silently dropping them would make it impossible to pass an empty
// positional value through a response file. See the discussion on
// apple/swift-argument-parser#909.
extension ResponseFileEndToEndTests {
  @Test func doubleQuotedEmptyPositionalPreservedOnOwnLine() async throws {
    try await withTemporaryFile(
      "positional_empty_double_line.txt",
      content: #"""
        first.txt
        ""
        last.txt
        """#
    ) { responseFile in
      expectParse(PositionalCommand.self, ["@\(responseFile)"]) { command in
        #expect(command.files == ["first.txt", "", "last.txt"])
      }
    }
  }

  @Test func singleQuotedEmptyPositionalPreservedOnOwnLine() async throws {
    try await withTemporaryFile(
      "positional_empty_single_line.txt",
      content: #"""
        first.txt
        ''
        last.txt
        """#
    ) { responseFile in
      expectParse(PositionalCommand.self, ["@\(responseFile)"]) { command in
        #expect(command.files == ["first.txt", "", "last.txt"])
      }
    }
  }

  @Test func multipleEmptyQuotedPositionalsOnSameLine() async throws {
    try await withTemporaryFile(
      "positional_many_empties.txt",
      content: #"""
        "" '' ""
        """#
    ) { responseFile in
      expectParse(PositionalCommand.self, ["@\(responseFile)"]) { command in
        #expect(command.files == ["", "", ""])
      }
    }
  }

  @Test func emptyQuotedPositionalsInterleavedWithValues() async throws {
    try await withTemporaryFile(
      "positional_interleaved.txt",
      content: #"""
        a.txt "" b.txt '' c.txt
        """#
    ) { responseFile in
      expectParse(PositionalCommand.self, ["@\(responseFile)"]) { command in
        #expect(command.files == ["a.txt", "", "b.txt", "", "c.txt"])
      }
    }
  }

  @Test func emptyQuotedPositionalAtStartOfLine() async throws {
    try await withTemporaryFile(
      "positional_empty_leading.txt",
      content: #"""
        "" a.txt b.txt
        """#
    ) { responseFile in
      expectParse(PositionalCommand.self, ["@\(responseFile)"]) { command in
        #expect(command.files == ["", "a.txt", "b.txt"])
      }
    }
  }

  @Test func emptyQuotedPositionalAtEndOfLine() async throws {
    try await withTemporaryFile(
      "positional_empty_trailing.txt",
      content: #"""
        a.txt b.txt ""
        """#
    ) { responseFile in
      expectParse(PositionalCommand.self, ["@\(responseFile)"]) { command in
        #expect(command.files == ["a.txt", "b.txt", ""])
      }
    }
  }

  // An unquoted blank line is treated as whitespace and skipped, but a
  // line that is *only* a quoted empty string must still contribute an
  // argument. This regression-guards the boundary between the two.
  @Test func blankLineSkippedButEmptyQuotedLinePreserved() async throws {
    try await withTemporaryFile(
      "positional_blank_vs_quoted.txt",
      content: #"""
        first.txt

        ""

        last.txt
        """#
    ) { responseFile in
      expectParse(PositionalCommand.self, ["@\(responseFile)"]) { command in
        #expect(command.files == ["first.txt", "", "last.txt"])
      }
    }
  }
}

// MARK: - Quoted String Content Positional Arguments

// The remaining `@Argument`-focused response-file coverage: verify that
// quoting preserves whitespace, escape sequences, and characters that
// would otherwise be interpreted by the response-file parser (comment
// markers, response-file prefix, option-looking tokens). These exercise
// the full quoting contract advertised by `parseQuotedArgument` /
// `unescapeString`, not just the empty-string edge case above.
extension ResponseFileEndToEndTests {

  // MARK: Whitespace preservation

  @Test func doubleQuotedPositionalPreservesInternalSpaces() async throws {
    try await withTemporaryFile(
      "positional_spaces_double.txt",
      content: #"""
        "hello world"
        "a b c"
        """#
    ) { responseFile in
      expectParse(PositionalCommand.self, ["@\(responseFile)"]) { command in
        #expect(command.files == ["hello world", "a b c"])
      }
    }
  }

  @Test func singleQuotedPositionalPreservesInternalSpaces() async throws {
    try await withTemporaryFile(
      "positional_spaces_single.txt",
      content: #"""
        'hello world'
        'a b c'
        """#
    ) { responseFile in
      expectParse(PositionalCommand.self, ["@\(responseFile)"]) { command in
        #expect(command.files == ["hello world", "a b c"])
      }
    }
  }

  @Test func quotedPositionalPreservesLeadingAndTrailingSpaces() async throws {
    try await withTemporaryFile(
      "positional_pad.txt",
      content: #"""
        "  leading and trailing  "
        '  and here too  '
        """#
    ) { responseFile in
      expectParse(PositionalCommand.self, ["@\(responseFile)"]) { command in
        #expect(
          command.files == [
            "  leading and trailing  ",
            "  and here too  ",
          ])
      }
    }
  }

  @Test func quotedPositionalWithTabCharacter() async throws {
    // A literal tab character (not the `\t` escape) between two words
    // must survive the parser intact when inside quotes.
    try await withTemporaryFile(
      "positional_tab.txt",
      content: "\"col1\tcol2\"\n'col3\tcol4'\n"
    ) { responseFile in
      expectParse(PositionalCommand.self, ["@\(responseFile)"]) { command in
        #expect(command.files == ["col1\tcol2", "col3\tcol4"])
      }
    }
  }

  // MARK: Escape sequences inside double quotes

  // `\"` is the only reliable way to embed a literal double quote inside
  // a double-quoted token, since a bare `"` would end the quoted region.
  @Test func doubleQuotedEscapedDoubleQuote() async throws {
    try await withTemporaryFile(
      "positional_escaped_quote.txt",
      content: #"""
        "say \"hello\" now"
        """#
    ) { responseFile in
      expectParse(PositionalCommand.self, ["@\(responseFile)"]) { command in
        #expect(command.files == [#"say "hello" now"#])
      }
    }
  }

  @Test func doubleQuotedEscapedBackslash() async throws {
    // `\\` inside double quotes produces a single literal backslash.
    try await withTemporaryFile(
      "positional_escaped_backslash.txt",
      content: #"""
        "path\\to\\file"
        """#
    ) { responseFile in
      expectParse(PositionalCommand.self, ["@\(responseFile)"]) { command in
        #expect(command.files == [#"path\to\file"#])
      }
    }
  }

  // The example called out in the PR feedback: a `\n` escape inside a
  // double-quoted token must yield an actual newline character in the
  // resulting positional argument.
  @Test func doubleQuotedEscapedNewline() async throws {
    try await withTemporaryFile(
      "positional_escaped_newline.txt",
      content: #"""
        "line1\nline2"
        """#
    ) { responseFile in
      expectParse(PositionalCommand.self, ["@\(responseFile)"]) { command in
        #expect(command.files == ["line1\nline2"])
      }
    }
  }

  @Test func doubleQuotedEscapedTab() async throws {
    try await withTemporaryFile(
      "positional_escaped_tab.txt",
      content: #"""
        "col1\tcol2"
        """#
    ) { responseFile in
      expectParse(PositionalCommand.self, ["@\(responseFile)"]) { command in
        #expect(command.files == ["col1\tcol2"])
      }
    }
  }

  @Test func doubleQuotedEscapedCarriageReturn() async throws {
    try await withTemporaryFile(
      "positional_escaped_cr.txt",
      content: #"""
        "before\rafter"
        """#
    ) { responseFile in
      expectParse(PositionalCommand.self, ["@\(responseFile)"]) { command in
        #expect(command.files == ["before\rafter"])
      }
    }
  }

  @Test func doubleQuotedMixedEscapeSequences() async throws {
    try await withTemporaryFile(
      "positional_mixed_escapes.txt",
      content: #"""
        "tab\there\nnewline\\backslash\"quote"
        """#
    ) { responseFile in
      expectParse(PositionalCommand.self, ["@\(responseFile)"]) { command in
        #expect(command.files == ["tab\there\nnewline\\backslash\"quote"])
      }
    }
  }

  // MARK: Escape sequences inside single quotes

  // Single quotes are literal — no escape processing at all — so a
  // backslash sequence must be preserved character-for-character.
  @Test func singleQuotedPreservesBackslashEscapesLiterally() async throws {
    try await withTemporaryFile(
      "positional_single_literal.txt",
      content: #"""
        'line1\nline2'
        'tab\there'
        'back\\slash'
        """#
    ) { responseFile in
      expectParse(PositionalCommand.self, ["@\(responseFile)"]) { command in
        #expect(
          command.files == [
            #"line1\nline2"#,
            #"tab\there"#,
            #"back\\slash"#,
          ])
      }
    }
  }

  // MARK: Reserved characters preserved inside quotes

  // `#` normally starts an end-of-line comment; inside quotes it must be
  // treated as a plain character.
  @Test func quotedHashDoesNotStartComment() async throws {
    try await withTemporaryFile(
      "positional_quoted_hash.txt",
      content: #"""
        "issue #42 fixed"
        'tag: #urgent'
        """#
    ) { responseFile in
      expectParse(PositionalCommand.self, ["@\(responseFile)"]) { command in
        #expect(command.files == ["issue #42 fixed", "tag: #urgent"])
      }
    }
  }

  // A quoted token that starts with the response-file prefix must pass
  // through as a literal positional value rather than triggering a
  // nested response-file expansion. This is the escape mechanism callers
  // rely on to pass an argument value that legitimately begins with `@`.
  @Test func quotedResponseFilePrefixIsLiteralPositional() async throws {
    try await withTemporaryFile(
      "positional_quoted_prefix.txt",
      content: #"""
        "@not-a-response-file.txt"
        '@also-not-one.txt'
        """#
    ) { responseFile in
      expectParse(PositionalCommand.self, ["@\(responseFile)"]) { command in
        #expect(
          command.files == [
            "@not-a-response-file.txt",
            "@also-not-one.txt",
          ])
      }
    }
  }

  // A quoted token that looks like an option (`--flag`, `-x`) must reach
  // the argument parser as a plain positional string. Positional args in
  // `PositionalCommand` accept anything, so option-looking values should
  // land in `files` untouched rather than being treated as unknown flags.
  @Test func quotedOptionSyntaxIsPositional() async throws {
    try await withTemporaryFile(
      "positional_quoted_option.txt",
      content: #"""
        "--not-a-flag"
        '-x'
        "--"
        """#
    ) { responseFile in
      expectParse(
        PositionalCommand.self, ["@\(responseFile)", "--output", "o.txt"]
      ) { command in
        #expect(command.files == ["--not-a-flag", "-x", "--"])
        #expect(command.output == "o.txt")
      }
    }
  }

  // MARK: Non-ASCII content

  @Test func quotedPositionalWithUnicode() async throws {
    try await withTemporaryFile(
      "positional_unicode.txt",
      content: #"""
        "café ☕ résumé"
        '日本語 🇯🇵'
        "emoji: 👋🌍"
        """#
    ) { responseFile in
      expectParse(PositionalCommand.self, ["@\(responseFile)"]) { command in
        #expect(
          command.files == [
            "café ☕ résumé",
            "日本語 🇯🇵",
            "emoji: 👋🌍",
          ])
      }
    }
  }

  // MARK: Mixed and adjacent quoting

  @Test func multipleQuotedPositionalsOnSameLine() async throws {
    try await withTemporaryFile(
      "positional_many_quoted.txt",
      content: #"""
        "first arg" "second arg" "third arg"
        """#
    ) { responseFile in
      expectParse(PositionalCommand.self, ["@\(responseFile)"]) { command in
        #expect(command.files == ["first arg", "second arg", "third arg"])
      }
    }
  }

  @Test func mixedQuoteStylesOnSameLine() async throws {
    try await withTemporaryFile(
      "positional_mixed_quotes.txt",
      content: #"""
        "double quoted" 'single quoted' unquoted
        """#
    ) { responseFile in
      expectParse(PositionalCommand.self, ["@\(responseFile)"]) { command in
        #expect(
          command.files == ["double quoted", "single quoted", "unquoted"])
      }
    }
  }

  @Test func quotedTokensAcrossMultipleLines() async throws {
    try await withTemporaryFile(
      "positional_multiline.txt",
      content: #"""
        "first quoted"
        second-unquoted
        'third quoted'
        "fourth quoted"
        """#
    ) { responseFile in
      expectParse(PositionalCommand.self, ["@\(responseFile)"]) { command in
        #expect(
          command.files == [
            "first quoted",
            "second-unquoted",
            "third quoted",
            "fourth quoted",
          ])
      }
    }
  }

  // MARK: Juxtaposed quoted segments

  // Adjacent quoted segments with no whitespace between them concatenate
  // into a single token. An empty quoted segment (`""` or `''`) next to
  // other segments contributes nothing to the string content, but still
  // forces the resulting token to exist (and to be marked as quoted).

  @Test func juxtaposedEmptyDoubleQuotesOnOwnLine() async throws {
    // `""""` is two empty double-quoted segments juxtaposed — still one
    // empty positional argument.
    try await withTemporaryFile(
      "positional_juxta_empty_double.txt",
      content: #"""
        """"
        """#
    ) { responseFile in
      expectParse(PositionalCommand.self, ["@\(responseFile)"]) { command in
        #expect(command.files == [""])
      }
    }
  }

  @Test func juxtaposedEmptySingleQuotesOnOwnLine() async throws {
    // `''''` is two empty single-quoted segments juxtaposed — still one
    // empty positional argument.
    try await withTemporaryFile(
      "positional_juxta_empty_single.txt",
      content: #"""
        ''''
        """#
    ) { responseFile in
      expectParse(PositionalCommand.self, ["@\(responseFile)"]) { command in
        #expect(command.files == [""])
      }
    }
  }

  @Test func multipleJuxtaposedEmptyQuoteRunsOnSameLine() async throws {
    // Each whitespace-separated group of juxtaposed empty quotes is one
    // empty positional argument; three groups → three empty arguments.
    try await withTemporaryFile(
      "positional_juxta_empty_multi.txt",
      content: #"""
        '''' """" ''""
        """#
    ) { responseFile in
      expectParse(PositionalCommand.self, ["@\(responseFile)"]) { command in
        #expect(command.files == ["", "", ""])
      }
    }
  }

  @Test func juxtaposedUnquotedAndDoubleQuotedConcatenates() async throws {
    // `a""a` → `aa`: the empty double-quoted segment is a no-op, but the
    // surrounding unquoted characters join into one token.
    try await withTemporaryFile(
      "positional_juxta_a_empty_a.txt",
      content: #"""
        a""a
        """#
    ) { responseFile in
      expectParse(PositionalCommand.self, ["@\(responseFile)"]) { command in
        #expect(command.files == ["aa"])
      }
    }
  }

  @Test func juxtaposedDoubleQuotedSegmentsConcatenate() async throws {
    // `"foo""bar"` → `foobar`: two adjacent double-quoted segments merge
    // into a single positional argument.
    try await withTemporaryFile(
      "positional_juxta_double.txt",
      content: #"""
        "foo""bar"
        """#
    ) { responseFile in
      expectParse(PositionalCommand.self, ["@\(responseFile)"]) { command in
        #expect(command.files == ["foobar"])
      }
    }
  }

  @Test func juxtaposedSingleQuotedSegmentsConcatenate() async throws {
    try await withTemporaryFile(
      "positional_juxta_single.txt",
      content: #"""
        'foo''bar'
        """#
    ) { responseFile in
      expectParse(PositionalCommand.self, ["@\(responseFile)"]) { command in
        #expect(command.files == ["foobar"])
      }
    }
  }

  @Test func complexJuxtaposedSegmentsWithinAndBetweenTokens() async throws {
    // A single line combining empty and non-empty juxtaposed segments of
    // both quote styles: each whitespace-separated group forms one
    // token, with adjacent segments concatenated.
    try await withTemporaryFile(
      "positional_juxta_complex.txt",
      content: #"""
        a""a ""b c"" d''d ''e f''
        """#
    ) { responseFile in
      expectParse(PositionalCommand.self, ["@\(responseFile)"]) { command in
        #expect(command.files == ["aa", "b", "c", "dd", "e", "f"])
      }
    }
  }

  @Test func juxtaposedMixedQuoteStyles() async throws {
    // A single token composed of double-then-single-then-double
    // segments must produce a single string that preserves the inner
    // quote characters that were themselves quoted by the *other*
    // style.
    try await withTemporaryFile(
      "positional_juxta_mixed.txt",
      content: #"""
        "'a'"'"b"'
        """#
    ) { responseFile in
      expectParse(PositionalCommand.self, ["@\(responseFile)"]) { command in
        #expect(command.files == [#"'a'"b""#])
      }
    }
  }

  // MARK: Line-level whitespace

  @Test func leadingAndTrailingWhitespaceOnLineIsIgnored() async throws {
    // Extra whitespace at the start/end of a line, and the runs of
    // spaces between arguments, must not produce spurious empty
    // arguments.
    try await withTemporaryFile(
      "positional_ws.txt",
      content: #"""
          a b c '' d
        """#
    ) { responseFile in
      expectParse(PositionalCommand.self, ["@\(responseFile)"]) { command in
        #expect(command.files == ["a", "b", "c", "", "d"])
      }
    }
  }

  // MARK: Unterminated quotes

  // A quote that is opened but never closed absorbs input until end of
  // file. Any content between the opening quote and EOF (including
  // newlines) becomes part of the resulting token.

  @Test func unterminatedSingleQuoteAloneProducesEmptyArg() async throws {
    // `a b '` at EOF → three arguments, the last of which is an empty
    // string (the opening `'` with no content).
    try await withTemporaryFile(
      "positional_unterm_empty.txt",
      content: #"""
        a b '
        """#
    ) { responseFile in
      expectParse(PositionalCommand.self, ["@\(responseFile)"]) { command in
        #expect(command.files == ["a", "b", ""])
      }
    }
  }

  @Test func unterminatedSingleQuoteWithContentProducesLiteralTail()
    async throws
  {
    // `a b 'c d` at EOF → `["a","b","c d"]`. The opening `'` starts a
    // quoted segment that runs to EOF, absorbing the intervening
    // whitespace as literal content.
    try await withTemporaryFile(
      "positional_unterm_content.txt",
      content: #"""
        a b 'c d
        """#
    ) { responseFile in
      expectParse(PositionalCommand.self, ["@\(responseFile)"]) { command in
        #expect(command.files == ["a", "b", "c d"])
      }
    }
  }

  @Test func unterminatedDoubleQuoteBehavesTheSame() async throws {
    // Double quotes get the same implicit-terminator treatment as
    // single quotes.
    try await withTemporaryFile(
      "positional_unterm_double.txt",
      content: #"""
        x y "z with spaces
        """#
    ) { responseFile in
      expectParse(PositionalCommand.self, ["@\(responseFile)"]) { command in
        #expect(command.files == ["x", "y", "z with spaces"])
      }
    }
  }

  @Test func unterminatedQuoteAbsorbsSubsequentLines() async throws {
    // With whole-file tokenization, an unterminated quote keeps
    // absorbing input past the newline — the intervening newline is
    // literal content inside the still-open quoted segment, and the
    // next line's opening `'` closes the segment. That means what
    // looks like three tokens across two lines is actually just two.
    try await withTemporaryFile(
      "positional_unterm_multi.txt",
      content: #"""
        first 'unterminated
        'second closed'
        """#
    ) { responseFile in
      expectParse(PositionalCommand.self, ["@\(responseFile)"]) { command in
        #expect(
          command.files == [
            "first",
            "unterminated\nsecond",
            "closed",
          ])
      }
    }
  }

  // MARK: Literal newlines inside quoted strings

  // A newline character that appears *inside* a quoted segment must be
  // preserved as part of that token instead of terminating it. This
  // requires a whole-file tokenizer (rather than a naive line-based one)
  // so that quote state carries across the newline.

  @Test func literalNewlineInsideSingleQuotesSpansLines() async throws {
    // `a 'b\nc' d` (with `\n` being a real newline byte) →
    // `["a", "b\nc", "d"]`.
    try await withTemporaryFile(
      "positional_newline_single.txt",
      content: "a 'b\nc' d\n"
    ) { responseFile in
      expectParse(PositionalCommand.self, ["@\(responseFile)"]) { command in
        #expect(command.files == ["a", "b\nc", "d"])
      }
    }
  }

  @Test func literalNewlineInsideDoubleQuotesSpansLines() async throws {
    try await withTemporaryFile(
      "positional_newline_double.txt",
      content: "a \"b\nc\" d\n"
    ) { responseFile in
      expectParse(PositionalCommand.self, ["@\(responseFile)"]) { command in
        #expect(command.files == ["a", "b\nc", "d"])
      }
    }
  }

  @Test func quotedTokenSpansManyLines() async throws {
    // A token whose opening quote appears on one line and closing quote
    // appears several lines later must land in `files` as a single
    // multi-line string.
    let content = "\"first line\nsecond line\nthird line\" tail\n"
    try await withTemporaryFile(
      "positional_multiline_token.txt",
      content: content
    ) { responseFile in
      expectParse(PositionalCommand.self, ["@\(responseFile)"]) { command in
        #expect(
          command.files == [
            "first line\nsecond line\nthird line",
            "tail",
          ])
      }
    }
  }

  @Test func multipleTokensSurroundingMultilineQuotedToken() async throws {
    // Tokens before and after a multi-line quoted token are still
    // parsed normally, and the multi-line token is exactly one
    // positional value.
    let content = "head \"line1\nline2\" tail\n"
    try await withTemporaryFile(
      "positional_multiline_surrounded.txt",
      content: content
    ) { responseFile in
      expectParse(PositionalCommand.self, ["@\(responseFile)"]) { command in
        #expect(command.files == ["head", "line1\nline2", "tail"])
      }
    }
  }

  @Test func hashInsideMultilineQuoteIsLiteral() async throws {
    // `#` inside a quoted token — even when it's the first character of
    // a line inside the token — is a literal, not the start of a
    // comment. Guards against a naive "start-of-line `#` is a comment"
    // check that could break multi-line quotes.
    let content = "before \"start\n# not a comment\nend\" after\n"
    try await withTemporaryFile(
      "positional_hash_in_multiline.txt",
      content: content
    ) { responseFile in
      expectParse(PositionalCommand.self, ["@\(responseFile)"]) { command in
        #expect(
          command.files == [
            "before",
            "start\n# not a comment\nend",
            "after",
          ])
      }
    }
  }
}

// MARK: - Nested Response Files

extension ResponseFileEndToEndTests {
  @Test func nestedResponseFiles() async throws {
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

      expectParse(SimpleCommand.self, ["@\(outerFile)"]) { command in
        #expect(command.name == "TestName")
        #expect(command.count == 42)
        #expect(command.verbose == true)
      }
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

      // This should throw an error for recursive response files
      #expect(throws: (any Error).self) {
        try SimpleCommand.parse(["@\(file1)"])
      }
    }
  }

  @Test func deepNestedResponseFiles() async throws {
    try await withTemporaryDirectory { dir in
      let level3 = try dir.createTestFile(
        "level3.txt",
        content: """
          --verbose
          """)

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
          DeepNested
          @\(level2)
          """)

      expectParse(SimpleCommand.self, ["@\(level1)"]) { command in
        #expect(command.name == "DeepNested")
        #expect(command.count == 100)
        #expect(command.verbose == true)
      }
    }
  }
}

// MARK: - Positional Arguments

extension ResponseFileEndToEndTests {
  @Test func responseFileWithPositionalArgs() async throws {
    try await withTemporaryFile(
      "positional.txt",
      content: """
        file1.txt
        file2.txt
        file3.txt
        --output
        result.txt
        """
    ) { responseFile in
      expectParse(PositionalCommand.self, ["@\(responseFile)"]) { command in
        #expect(command.files == ["file1.txt", "file2.txt", "file3.txt"])
        #expect(command.output == "result.txt")
      }
    }
  }

  @Test func responseFileWithPositionalAndRegularArgs() async throws {
    try await withTemporaryFile(
      "mixed_pos.txt",
      content: """
        fromfile1.txt
        fromfile2.txt
        """
    ) { responseFile in
      expectParse(
        PositionalCommand.self,
        ["regular1.txt", "@\(responseFile)", "regular2.txt"]
      ) { command in
        #expect(
          command.files
            == [
              "regular1.txt", "fromfile1.txt", "fromfile2.txt", "regular2.txt",
            ]
        )
      }
    }
  }
}

// MARK: - Subcommands

extension ResponseFileEndToEndTests {
  @Test func responseFileWithSubcommands() async throws {
    try await withTemporaryFile(
      "subcommand.txt",
      content: """
        subcommand-child
        --value
        TestValue
        """
    ) { responseFile in
      expectParseCommand(
        SubcommandParent.self, SubcommandChild.self, ["@\(responseFile)"]
      ) { command in
        #expect(command.value == "TestValue")
      }
    }
  }

  @Test func responseFileBeforeSubcommand() async throws {
    try await withTemporaryFile(
      "before_sub.txt",
      content: """
        # Global options would go here if SubcommandParent had any
        """
    ) { responseFile in
      expectParseCommand(
        SubcommandParent.self, SubcommandChild.self,
        ["@\(responseFile)", "subcommand-child", "--value", "Test"]
      ) { command in
        #expect(command.value == "Test")
      }
    }
  }
}

// MARK: - Error Cases

extension ResponseFileEndToEndTests {
  @Test func nonexistentResponseFile() throws {
    #expect(throws: (any Error).self) {
      try SimpleCommand.parse(["@/nonexistent/file.txt"])
    }
  }

  @Test func invalidResponseFilePermissions() async throws {
    try await withTemporaryFile(
      "noaccess.txt", content: "--name Test"
    ) { responseFile in
      // Remove read permissions (this may not work in all test environments)
      try? FileManager.default.setAttributes(
        [.posixPermissions: 0o000],
        ofItemAtPath: responseFile
      )
      defer {
        // Restore permissions for cleanup
        try? FileManager.default.setAttributes(
          [.posixPermissions: 0o644],
          ofItemAtPath: responseFile
        )
      }

      // Skip on platforms/environments where POSIX permissions don't
      // actually restrict reads — most notably root inside a Docker
      // container (root bypasses mode bits) and Windows (NTFS ACLs, not
      // POSIX modes, gate access).
      guard !FileManager.default.isReadableFile(atPath: responseFile) else {
        return
      }

      #expect(throws: (any Error).self) {
        try SimpleCommand.parse(["@\(responseFile)"])
      }
    }
  }

  @Test func emptyResponseFile() async throws {
    try await withTemporaryFile("empty.txt", content: "") { responseFile in
      // Empty response file should be valid and not add any arguments
      expectParse(SimpleCommand.self, ["@\(responseFile)", "--name", "Test"]) {
        command in
        #expect(command.name == "Test")
        #expect(command.count == 1)  // default value
        #expect(command.verbose == false)
      }
    }
  }

  @Test func malformedArgumentsInResponseFile() async throws {
    try await withTemporaryFile(
      "malformed.txt",
      content: """
        --name
        # Missing value for --name
        --count
        notanumber
        """
    ) { responseFile in
      #expect(throws: (any Error).self) {
        try SimpleCommand.parse(["@\(responseFile)"])
      }
    }
  }
}

// MARK: - Edge Cases

extension ResponseFileEndToEndTests {
  @Test func responseFileNameWithSpaces() async throws {
    try await withTemporaryFile(
      "file with spaces.txt",
      content: """
        --name
        Test
        """
    ) { responseFile in
      expectParse(SimpleCommand.self, ["@\(responseFile)"]) { command in
        #expect(command.name == "Test")
      }
    }
  }

  @Test func literalAtSignArgument() async throws {
    // Test that we can still pass literal @something arguments
    // This would need special escaping mechanism, like @@file.txt for literal @file.txt
    try await withTemporaryFile(
      "literal.txt",
      content: """
        --name
        @@notafile
        """
    ) { responseFile in
      expectParse(SimpleCommand.self, ["@\(responseFile)"]) { command in
        #expect(command.name == "@notafile")
      }
    }
  }

  @Test func responseFileWithTerminator() async throws {
    try await withTemporaryFile(
      "terminator.txt",
      content: """
        --output
        result.txt
        --
        file1.txt
        file2.txt
        """
    ) { responseFile in
      expectParse(PositionalCommand.self, ["@\(responseFile)"]) { command in
        #expect(command.files == ["file1.txt", "file2.txt"])
        #expect(command.output == "result.txt")
      }
    }
  }

  @Test func responseFileWithEqualsFormat() async throws {
    try await withTemporaryFile(
      "equals.txt",
      content: """
        --name=TestName
        --count=42
        """
    ) { responseFile in
      expectParse(SimpleCommand.self, ["@\(responseFile)"]) { command in
        #expect(command.name == "TestName")
        #expect(command.count == 42)
      }
    }
  }

  @Test func veryLargeResponseFile() async throws {
    // Test with a response file containing many arguments
    var content = ""
    for i in 1...1000 {
      content += "arg\(i).txt\n"
    }

    try await withTemporaryFile("large.txt", content: content) { responseFile in
      expectParse(PositionalCommand.self, ["@\(responseFile)"]) { command in
        #expect(command.files.count == 1000)
        #expect(command.files.first == "arg1.txt")
        #expect(command.files.last == "arg1000.txt")
      }
    }
  }
}

// MARK: - Configuration Options

extension ResponseFileEndToEndTests {
  // These tests will verify that response file support can be configured
  // The actual configuration mechanism will be defined during implementation

  @Test func disableResponseFileSupport() throws {
    // Test that response file support can be disabled per command
    // This would be implemented as a configuration option
    // For now, this is a placeholder for the feature

    // When disabled, @file should be treated as a literal argument
    // Implementation details TBD
  }

  @Test func responseFileSearchPaths() throws {
    // Test that response files can be searched in multiple directories
    // Implementation details TBD
  }
}

// MARK: - AsyncParsableCommand Support Tests

extension ResponseFileEndToEndTests {
  @Test func responseFileWithAsyncParsableCommand() async throws {
    try await withTemporaryFile(
      "async-args.txt",
      content: """
        --name
        AsyncTest
        --count
        42
        """
    ) { responseFile in
      struct AsyncTestCommand: AsyncParsableCommand {
        static var responseFilePrefix: Character? { "@" }

        @Option var name: String
        @Option var count: Int

        func run() async throws {
          // Test command that uses async
        }
      }

      expectParse(AsyncTestCommand.self, ["@\(responseFile)"]) { command in
        #expect(command.name == "AsyncTest")
        #expect(command.count == 42)
      }
    }
  }

  @Test func responseFileWithAsyncSubcommand() async throws {
    try await withTemporaryFile(
      "async-sub-args.txt",
      content: """
        sub
        --value
        AsyncSubTest
        """
    ) { responseFile in
      struct AsyncParentCommand: AsyncParsableCommand {
        static var responseFilePrefix: Character? { "@" }
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

      expectParseCommand(
        AsyncParentCommand.self, AsyncSubCommand.self, ["@\(responseFile)"]
      ) { command in
        #expect(command.value == "AsyncSubTest")
      }
    }
  }

  @Test func responseFileWithMixedAsyncArgs() async throws {
    try await withTemporaryFile(
      "mixed-async.txt",
      content: """
        --input
        input.txt
        --async-flag
        """
    ) { responseFile in
      struct MixedAsyncCommand: AsyncParsableCommand {
        static var responseFilePrefix: Character? { "@" }

        @Option var input: String
        @Option var output: String = "default.txt"
        @Flag var asyncFlag: Bool = false

        func run() async throws {
          // Mixed args async command
        }
      }

      expectParse(
        MixedAsyncCommand.self,
        ["@\(responseFile)", "--output", "override.txt"]
      ) { command in
        #expect(command.input == "input.txt")
        // CLI arg overrides default
        #expect(command.output == "override.txt")
        #expect(command.asyncFlag)
      }
    }
  }
}

// MARK: - Custom Response File Prefix

extension ResponseFileEndToEndTests {
  @Test func defaultResponseFilePrefixIsNil() {
    struct DefaultPrefixCommand: ParsableCommand {}
    struct DefaultPrefixSubcommandParent: ParsableCommand {
      static let configuration = CommandConfiguration(
        subcommands: [SubcommandChild.self]
      )
    }

    #expect(DefaultPrefixCommand.responseFilePrefix == nil)
    #expect(DefaultPrefixSubcommandParent.responseFilePrefix == nil)
    #expect(SubcommandChild.responseFilePrefix == nil)
  }

  @Test func commandCanOverrideResponseFilePrefix() {
    #expect(PlusPrefixCommand.responseFilePrefix == "+")
    #expect(HashPrefixCommand.responseFilePrefix == "#")
    #expect(PlusPrefixSubcommandParent.responseFilePrefix == "+")
  }

  @Test func customPrefixExpandsResponseFile() async throws {
    try await withTemporaryFile(
      "custom-prefix.txt",
      content: """
        --name
        FromCustomPrefix
        --count
        7
        --verbose
        """
    ) { responseFile in
      expectParse(PlusPrefixCommand.self, ["+\(responseFile)"]) { command in
        #expect(command.name == "FromCustomPrefix")
        #expect(command.count == 7)
        #expect(command.verbose == true)
      }
    }
  }

  @Test func customPrefixDoesNotExpandAtSignArgument() async throws {
    // With the `+` prefix set, `@something` must be treated as a
    // literal positional value rather than a response file reference.
    try await withTemporaryFile(
      "custom-prefix-args.txt",
      content: """
        --name
        Sam
        """
    ) { responseFile in
      expectParse(
        PlusPrefixCommand.self,
        ["+\(responseFile)", "@not-a-response-file.txt"]
      ) { command in
        #expect(command.name == "Sam")
        #expect(command.files == ["@not-a-response-file.txt"])
      }
    }
  }

  @Test func defaultPrefixDoesNotExpandCustomPrefixArgument() async throws {
    // with the default `@` prefix, `+something` is an ordinary positional value.
    expectParse(
      PositionalCommand.self, ["+not-a-response-file.txt"]
    ) { command in
      #expect(command.files == ["+not-a-response-file.txt"])
    }
  }

  @Test func customPrefixQuotedIsLiteral() async throws {
    // Quoting a token in a response file passes it through verbatim,
    // so `"+file"` is treated as the literal value `+file` even though
    // the active response-file prefix is `+`.
    try await withTemporaryFile(
      "custom-escape.txt",
      content: """
        --name
        Escaped
        "+literal.txt"
        """
    ) { responseFile in
      expectParse(PlusPrefixCommand.self, ["+\(responseFile)"]) { command in
        #expect(command.name == "Escaped")
        #expect(command.files == ["+literal.txt"])
      }
    }
  }

  @Test func customPrefixDoubledIsLiteral() async throws {
    // Doubling the configured prefix escapes it: with `+` in effect,
    // `++file` becomes the literal `+file` (parallel to the built-in
    // `@@file` -> `@file` handling for the default prefix).
    try await withTemporaryFile(
      "custom-doubled.txt",
      content: """
        --name
        Escaped
        ++literal.txt
        """
    ) { responseFile in
      expectParse(PlusPrefixCommand.self, ["+\(responseFile)"]) { command in
        #expect(command.name == "Escaped")
        #expect(command.files == ["+literal.txt"])
      }
    }
  }

  @Test func customPrefixNestedResponseFiles() async throws {
    try await withTemporaryDirectory { dir in
      let inner = try dir.createTestFile(
        "inner.txt",
        content: """
          --count
          99
          --verbose
          """
      )
      let outer = try dir.createTestFile(
        "outer.txt",
        content: """
          --name
          Nested
          +\(inner)
          """
      )

      expectParse(PlusPrefixCommand.self, ["+\(outer)"]) { command in
        #expect(command.name == "Nested")
        #expect(command.count == 99)
        #expect(command.verbose == true)
      }
    }
  }

  @Test func customPrefixWithSubcommand() async throws {
    // The root command's prefix determines the response-file prefix
    // used for the entire invocation, including subcommand arguments.
    try await withTemporaryFile(
      "subcommand.txt",
      content: """
        subcommand-child
        --value
        FromCustomPrefix
        """
    ) { responseFile in
      expectParseCommand(
        PlusPrefixSubcommandParent.self, SubcommandChild.self,
        ["+\(responseFile)"]
      ) { command in
        #expect(command.value == "FromCustomPrefix")
      }
    }
  }

  @Test func customPrefixMissingFileThrows() throws {
    #expect(throws: (any Error).self) {
      try PlusPrefixCommand.parse(["+/nonexistent/file.txt"])
    }
  }

  @Test func customPrefixNonHashArgumentTreatedAsValue() async throws {
    // The `#` prefix is a common comment character in response file
    // content; verify overriding to `#` still triggers expansion when
    // used as an argument prefix on the command line.
    try await withTemporaryFile(
      "hash-prefix.txt",
      content: """
        a.txt
        b.txt
        """
    ) { responseFile in
      expectParse(HashPrefixCommand.self, ["#\(responseFile)"]) { command in
        #expect(command.files == ["a.txt", "b.txt"])
      }
    }
  }
}
