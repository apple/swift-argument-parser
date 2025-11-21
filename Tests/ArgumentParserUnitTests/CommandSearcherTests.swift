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

import XCTest

@testable import ArgumentParser

final class CommandSearcherTests: XCTestCase {}

// MARK: - Test Commands

private struct SimpleCommand: ParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "A simple command for testing",
    discussion: "This command has a longer discussion about what it does."
  )

  @Option(help: "The user's name")
  var name: String

  @Option(help: "The user's age")
  var age: Int?

  @Flag(help: "Enable verbose output")
  var verbose: Bool = false

  @Argument(help: "Files to process")
  var files: [String] = []
}

private struct ParentCommand: ParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "Parent command with subcommands",
    subcommands: [ChildOne.self, ChildTwo.self]
  )

  struct ChildOne: ParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "child-one",
      abstract: "First child command"
    )

    @Option(help: "Configuration file path")
    var config: String?
  }

  struct ChildTwo: ParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "child-two",
      abstract: "Second child for searching",
      aliases: ["c2", "child2"]
    )

    @Flag(help: "Force the operation")
    var force: Bool = false
  }
}

private enum OutputFormat: String, CaseIterable, ExpressibleByArgument {
  case json, xml, yaml
}

private struct CommandWithEnums: ParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "Command with enumeration options"
  )

  @Option(help: "Output format")
  var format: OutputFormat = .json
}

// MARK: - Basic Search Tests

extension CommandSearcherTests {
  func testSearch_CommandName() {
    let tree = CommandParser(ParentCommand.self).commandTree
    let engine = CommandSearcher(
      rootNode: tree,
      commandStack: [ParentCommand.self],
      visibility: .default
    )

    let results = engine.search(for: "child")

    // Should find both child commands
    XCTAssertEqual(results.count, 2)
    XCTAssertTrue(results.allSatisfy { $0.isCommandMatch })

    // Both should be command name matches
    XCTAssertTrue(
      results.allSatisfy {
        if case .commandName = $0.matchType { return true }
        return false
      })
  }

  func testSearch_CommandAlias() {
    let tree = CommandParser(ParentCommand.self).commandTree
    let engine = CommandSearcher(
      rootNode: tree,
      commandStack: [ParentCommand.self],
      visibility: .default
    )

    let results = engine.search(for: "c2")

    XCTAssertEqual(results.count, 1)
    guard case .commandName(let matched) = results.first?.matchType else {
      XCTFail("Expected command name match")
      return
    }
    XCTAssertEqual(matched, "c2")
  }

  func testSearch_CommandAbstract() {
    let tree = CommandParser(SimpleCommand.self).commandTree
    let engine = CommandSearcher(
      rootNode: tree,
      commandStack: [SimpleCommand.self],
      visibility: .default
    )

    let results = engine.search(for: "testing")

    XCTAssertEqual(results.count, 1)
    guard case .commandDescription = results.first?.matchType else {
      XCTFail("Expected command description match")
      return
    }
  }

  func testSearch_CommandDiscussion() {
    let tree = CommandParser(SimpleCommand.self).commandTree
    let engine = CommandSearcher(
      rootNode: tree,
      commandStack: [SimpleCommand.self],
      visibility: .default
    )

    let results = engine.search(for: "longer discussion")

    XCTAssertEqual(results.count, 1)
    guard case .commandDescription = results.first?.matchType else {
      XCTFail("Expected command description match")
      return
    }
  }
}

// MARK: - Argument Search Tests

extension CommandSearcherTests {
  func testSearch_ArgumentName() {
    let tree = CommandParser(SimpleCommand.self).commandTree
    let engine = CommandSearcher(
      rootNode: tree,
      commandStack: [SimpleCommand.self],
      visibility: .default
    )

    let results = engine.search(for: "name")

    XCTAssertEqual(results.count, 1)
    XCTAssertFalse(results[0].isCommandMatch)
    guard case .argumentName(let name, _) = results[0].matchType else {
      XCTFail("Expected argument name match")
      return
    }
    XCTAssertEqual(name, "--name")
  }

  func testSearch_ArgumentHelp() {
    let tree = CommandParser(SimpleCommand.self).commandTree
    let engine = CommandSearcher(
      rootNode: tree,
      commandStack: [SimpleCommand.self],
      visibility: .default
    )

    let results = engine.search(for: "user's")

    XCTAssertGreaterThanOrEqual(results.count, 1)
    // Should find matches in help text
    let helpMatches = results.filter {
      if case .argumentDescription = $0.matchType { return true }
      return false
    }
    XCTAssertGreaterThan(helpMatches.count, 0)
  }

  func testSearch_ArgumentValue() {
    let tree = CommandParser(CommandWithEnums.self).commandTree
    let engine = CommandSearcher(
      rootNode: tree,
      commandStack: [CommandWithEnums.self],
      visibility: .default
    )

    let results = engine.search(for: "json")

    XCTAssertGreaterThanOrEqual(results.count, 1)
    // Should find in possible values or default value
    let valueMatches = results.filter {
      if case .argumentValue = $0.matchType { return true }
      return false
    }
    XCTAssertGreaterThan(valueMatches.count, 0)
  }

  func testSearch_PositionalArgument() {
    let tree = CommandParser(SimpleCommand.self).commandTree
    let engine = CommandSearcher(
      rootNode: tree,
      commandStack: [SimpleCommand.self],
      visibility: .default
    )

    let results = engine.search(for: "files")

    XCTAssertGreaterThanOrEqual(results.count, 1)
    // Positional arguments should be searchable
    let positionalMatches = results.filter {
      if case .argumentName(let name, _) = $0.matchType {
        return name.contains("<files>")
      }
      return false
    }
    XCTAssertGreaterThan(positionalMatches.count, 0)
  }

  func testSearch_ArgumentDiscussion() {
    struct TestCommand: ParsableCommand {
      @Option(
        help: ArgumentHelp(
          "Short help",
          discussion:
            "This is a much longer discussion that explains the configuration file format in detail."
        ))
      var config: String?
    }

    let tree = CommandParser(TestCommand.self).commandTree
    let engine = CommandSearcher(
      rootNode: tree,
      commandStack: [TestCommand.self],
      visibility: .default
    )

    let results = engine.search(for: "configuration file format")

    XCTAssertGreaterThanOrEqual(results.count, 1)
    // Should find match in discussion
    let discussionMatches = results.filter {
      if case .argumentDescription = $0.matchType { return true }
      return false
    }
    XCTAssertGreaterThan(discussionMatches.count, 0)
    // Should match in discussion, not in the short help
    XCTAssertTrue(
      results[0].contextSnippet.contains("configuration file format"))
  }

  func testSearch_ArgumentDefaultValue() {
    struct TestCommand: ParsableCommand {
      @Option(help: "The output format")
      var format: OutputFormat = .json
    }

    let tree = CommandParser(TestCommand.self).commandTree
    let engine = CommandSearcher(
      rootNode: tree,
      commandStack: [TestCommand.self],
      visibility: .default
    )

    let results = engine.search(for: "json")

    XCTAssertGreaterThanOrEqual(results.count, 1)
    // Should find match in default value
    let valueMatches = results.filter {
      if case .argumentValue = $0.matchType { return true }
      return false
    }
    XCTAssertGreaterThan(
      valueMatches.count, 0,
      "Should find 'json' in default value or possible values")
  }

  func testSearch_StringDefaultValue() {
    // Test specifically for Check 5: default value search on String options
    // This ensures we hit the default value code path, not allValueStrings
    struct TestCommand: ParsableCommand {
      @Option(help: "The target path")
      var target: String = "/var/log/myapp"
    }

    let tree = CommandParser(TestCommand.self).commandTree
    let engine = CommandSearcher(
      rootNode: tree,
      commandStack: [TestCommand.self],
      visibility: .default
    )

    // Search for something that ONLY appears in the default value
    let results = engine.search(for: "myapp")

    XCTAssertGreaterThanOrEqual(
      results.count, 1, "Should find match in default value")

    // Should find match as argumentValue
    let valueMatches = results.filter {
      if case .argumentValue(_, let matchedText) = $0.matchType {
        // Verify it's matching the default value
        return matchedText.contains("/var/log/myapp")
      }
      return false
    }
    XCTAssertGreaterThan(
      valueMatches.count, 0,
      "Should find 'myapp' in the default value '/var/log/myapp'")

    // Verify the snippet indicates it's a default value
    let hasDefaultSnippet = results.contains { result in
      result.contextSnippet.contains("default:")
    }
    XCTAssertTrue(
      hasDefaultSnippet,
      "Context snippet should indicate this is a default value")
  }

  func testSearch_PossibleValues_Explicit() {
    // Test that all possible enum values are searchable
    let tree = CommandParser(CommandWithEnums.self).commandTree
    let engine = CommandSearcher(
      rootNode: tree,
      commandStack: [CommandWithEnums.self],
      visibility: .default
    )

    // Test each enum value
    for searchTerm in ["json", "xml", "yaml"] {
      let results = engine.search(for: searchTerm)
      XCTAssertGreaterThanOrEqual(
        results.count, 1, "Should find '\(searchTerm)'")

      let valueMatches = results.filter {
        if case .argumentValue = $0.matchType { return true }
        return false
      }
      XCTAssertGreaterThan(
        valueMatches.count, 0, "'\(searchTerm)' should match as a value")
    }
  }
}

// MARK: - Case Sensitivity Tests

extension CommandSearcherTests {
  func testSearch_CaseInsensitive() {
    let tree = CommandParser(SimpleCommand.self).commandTree
    let engine = CommandSearcher(
      rootNode: tree,
      commandStack: [SimpleCommand.self],
      visibility: .default
    )

    let resultsLower = engine.search(for: "verbose")
    let resultsUpper = engine.search(for: "VERBOSE")
    let resultsMixed = engine.search(for: "VeRbOsE")

    XCTAssertEqual(resultsLower.count, resultsUpper.count)
    XCTAssertEqual(resultsLower.count, resultsMixed.count)
    XCTAssertGreaterThan(resultsLower.count, 0)
  }
}

// MARK: - Result Ordering Tests

extension CommandSearcherTests {
  func testSearch_ResultOrdering() {
    let tree = CommandParser(ParentCommand.self).commandTree
    let engine = CommandSearcher(
      rootNode: tree,
      commandStack: [ParentCommand.self],
      visibility: .default
    )

    // Search for "command" which appears in both command names and descriptions
    let results = engine.search(for: "command")

    // Command matches should come before argument matches
    var seenArgumentMatch = false
    for result in results {
      if !result.isCommandMatch {
        seenArgumentMatch = true
      } else if seenArgumentMatch {
        XCTFail("Command match found after argument match")
      }
    }
  }
}

// MARK: - Empty and No-Match Tests

extension CommandSearcherTests {
  func testSearch_EmptyTerm() {
    let tree = CommandParser(SimpleCommand.self).commandTree
    let engine = CommandSearcher(
      rootNode: tree,
      commandStack: [SimpleCommand.self],
      visibility: .default
    )

    let results = engine.search(for: "")

    XCTAssertEqual(results.count, 0)
  }

  func testSearch_NoMatches() {
    let tree = CommandParser(SimpleCommand.self).commandTree
    let engine = CommandSearcher(
      rootNode: tree,
      commandStack: [SimpleCommand.self],
      visibility: .default
    )

    let results = engine.search(for: "xyzzynonexistent")

    XCTAssertEqual(results.count, 0)
  }
}

// MARK: - Priority Tests

extension CommandSearcherTests {
  func testSearch_MatchPriority() {
    // When a term matches multiple attributes of the same item,
    // only the highest priority match should be returned

    struct TestCommand: ParsableCommand {
      static let configuration = CommandConfiguration(
        abstract: "A test command"
      )

      @Option(help: "test option help")
      var test: String?
    }

    let tree = CommandParser(TestCommand.self).commandTree
    let engine = CommandSearcher(
      rootNode: tree,
      commandStack: [TestCommand.self],
      visibility: .default
    )

    let results = engine.search(for: "test")

    // Should get matches for both command and argument, but not duplicates
    // Command should match in abstract, argument should match in name
    let commandMatches = results.filter { $0.isCommandMatch }
    let argumentMatches = results.filter { !$0.isCommandMatch }

    XCTAssertEqual(
      commandMatches.count, 1, "Should have exactly one command match")
    XCTAssertEqual(
      argumentMatches.count, 1, "Should have exactly one argument match")

    // The argument match should be for the name (higher priority than help)
    guard case .argumentName = argumentMatches.first?.matchType else {
      XCTFail("Expected argument name match, not help match")
      return
    }
  }
}

// MARK: - ANSI Highlighting Tests

extension CommandSearcherTests {
  func testANSI_Highlight() {
    let text = "This is a test string"
    let highlighted = ANSICode.highlightMatches(
      in: text, matching: "test", enabled: true)
    XCTAssertEqual(
      highlighted,
      "This is a " + ANSICode.bold + "test" + ANSICode.reset + " string")
  }

  func testANSI_HighlightDisabled() {
    let text = "This is a test string"
    let highlighted = ANSICode.highlightMatches(
      in: text, matching: "test", enabled: false)

    XCTAssertEqual(highlighted, text)
    XCTAssertFalse(highlighted.contains(ANSICode.bold))
  }

  func testANSI_HighlightMultipleMatches() {
    let text = "test this test that test"
    let highlighted = ANSICode.highlightMatches(
      in: text, matching: "test", enabled: true)

    // Should highlight all three occurrences
    let boldCount = highlighted.components(separatedBy: ANSICode.bold).count - 1
    XCTAssertEqual(boldCount, 3)
  }

  func testANSI_HighlightCaseInsensitive() {
    let text = "Test this TEST that TeSt"
    let highlighted = ANSICode.highlightMatches(
      in: text, matching: "test", enabled: true)

    // Should highlight all three occurrences regardless of case
    let boldCount = highlighted.components(separatedBy: ANSICode.bold).count - 1
    XCTAssertEqual(boldCount, 3)
  }
}

// MARK: - Snippet Extraction Tests

extension CommandSearcherTests {
  func testSnippet_CenteredOnMatch() {
    struct TestCommand: ParsableCommand {
      static let configuration = CommandConfiguration(
        discussion:
          "This is a very long discussion that contains many words and the word needle appears somewhere in the middle of all this text."
      )
    }

    let tree = CommandParser(TestCommand.self).commandTree
    let engine = CommandSearcher(
      rootNode: tree,
      commandStack: [TestCommand.self],
      visibility: .default
    )

    let results = engine.search(for: "needle")

    XCTAssertEqual(results.count, 1)
    // Snippet should contain the match and surrounding context
    XCTAssertTrue(results[0].contextSnippet.contains("needle"))
    // Should be reasonably short (around 80 chars)
    XCTAssertLessThan(results[0].contextSnippet.count, 100)
  }
}

// MARK: - Format Results Tests

extension CommandSearcherTests {
  func testFormatResults_NoMatches() {
    let formatted = CommandSearcher.formatResults(
      [],
      term: "test",
      toolName: "mytool",
      screenWidth: 80,
      useHighlighting: false
    )

    XCTAssertTrue(formatted.contains("No matches found"))
    XCTAssertTrue(formatted.contains("test"))
    XCTAssertTrue(formatted.contains("--help"))
  }

  func testFormatResults_WithMatches() {
    let tree = CommandParser(SimpleCommand.self).commandTree
    let engine = CommandSearcher(
      rootNode: tree,
      commandStack: [SimpleCommand.self],
      visibility: .default
    )

    let results = engine.search(for: "name")
    let formatted = CommandSearcher.formatResults(
      results,
      term: "name",
      toolName: "simple-command",
      screenWidth: 80
    )

    XCTAssertTrue(formatted.contains("Found"))
    XCTAssertTrue(formatted.contains("match"))
    XCTAssertTrue(formatted.contains("name"))
  }

  func testFormatResults_GroupsByType() {
    let tree = CommandParser(ParentCommand.self).commandTree
    let engine = CommandSearcher(
      rootNode: tree,
      commandStack: [ParentCommand.self],
      visibility: .default
    )

    let results = engine.search(for: "child")
    let formatted = CommandSearcher.formatResults(
      results,
      term: "child",
      toolName: "parent-command",
      screenWidth: 80,
      useHighlighting: false
    )

    // Should have COMMANDS section for command matches
    XCTAssertTrue(formatted.contains("COMMANDS:"))
  }

  func testFormatResults_CommandDescriptionFormatting() {
    struct TestCommand: ParsableCommand {
      static let configuration = CommandConfiguration(
        abstract:
          "This is a test command that performs various operations on data files."
      )
    }

    let tree = CommandParser(TestCommand.self).commandTree
    let engine = CommandSearcher(
      rootNode: tree,
      commandStack: [TestCommand.self],
      visibility: .default
    )

    let results = engine.search(for: "operations")
    let formatted = CommandSearcher.formatResults(
      results,
      term: "operations",
      toolName: "test-command",
      screenWidth: 80,
      useHighlighting: false
    )

    // Should find the command description match
    XCTAssertTrue(formatted.contains("Found"))
    XCTAssertTrue(formatted.contains("match"))
    // Should show the command path
    XCTAssertTrue(formatted.contains("test-command"))
    // Should contain the matched term
    XCTAssertTrue(formatted.contains("operations"))
    // Should have the context snippet with description text
    XCTAssertTrue(
      formatted.contains("performs") || formatted.contains("data files"))
  }

  func testFormatResults_CommandDescriptionWrapping() {
    struct TestCommand: ParsableCommand {
      static let configuration = CommandConfiguration(
        discussion:
          "This is a very long discussion that contains many words and should wrap when displayed in the search results because it exceeds the screen width limit that we set for formatting purposes."
      )
    }

    let tree = CommandParser(TestCommand.self).commandTree
    let engine = CommandSearcher(
      rootNode: tree,
      commandStack: [TestCommand.self],
      visibility: .default
    )

    let results = engine.search(for: "screen width")
    let formatted = CommandSearcher.formatResults(
      results,
      term: "screen width",
      toolName: "test-command",
      screenWidth: 60,  // Narrow width to force wrapping
      useHighlighting: false
    )

    // Should find the match
    XCTAssertGreaterThan(results.count, 0)
    // Should contain the matched terms
    XCTAssertTrue(formatted.contains("screen"))
    XCTAssertTrue(formatted.contains("width"))
    // Should have proper indentation (wrapped lines indented by 6 spaces)
    // The formatting adds 4 spaces base indent + wrapping indent
    let lines = formatted.split(separator: "\n")
    let hasIndentedLine = lines.contains { line in
      line.starts(with: "      ")  // 6 spaces for continuation lines
    }
    XCTAssertTrue(
      hasIndentedLine, "Should have wrapped lines with proper indentation")
  }

  func testFormatResults_ArgumentDescriptionFormatting() {
    // Test the .argumentDescription case formatting
    struct TestCommand: ParsableCommand {
      @Option(
        help:
          "This option controls the maximum retry attempts for network requests"
      )
      var maxRetries: Int = 3
    }

    let tree = CommandParser(TestCommand.self).commandTree
    let engine = CommandSearcher(
      rootNode: tree,
      commandStack: [TestCommand.self],
      visibility: .default
    )

    let results = engine.search(for: "network requests")
    let formatted = CommandSearcher.formatResults(
      results,
      term: "network requests",
      toolName: "test-command",
      screenWidth: 80,
      useHighlighting: false
    )

    // Should find the match
    XCTAssertGreaterThan(results.count, 0)
    // Should have OPTIONS section for argument matches
    XCTAssertTrue(formatted.contains("OPTIONS:"))
    // Should show argument name with colon format: "    --max-retries: <snippet>"
    XCTAssertTrue(formatted.contains("--max-retries:"))
    // Should contain the matched terms
    XCTAssertTrue(formatted.contains("network"))
    XCTAssertTrue(formatted.contains("requests"))
  }

  func testFormatResults_ArgumentDescriptionWrapping() {
    // Test that argumentDescription wrapping works with 6-space indent
    struct TestCommand: ParsableCommand {
      @Option(
        help: ArgumentHelp(
          "Short help",
          discussion:
            "This is a very long discussion about an option that contains many words and should definitely wrap when displayed because it exceeds our screen width limit for testing purposes."
        ))
      var config: String?
    }

    let tree = CommandParser(TestCommand.self).commandTree
    let engine = CommandSearcher(
      rootNode: tree,
      commandStack: [TestCommand.self],
      visibility: .default
    )

    let results = engine.search(for: "screen width")
    let formatted = CommandSearcher.formatResults(
      results,
      term: "screen width",
      toolName: "test-command",
      screenWidth: 60,  // Narrow width to force wrapping
      useHighlighting: false
    )

    // Should find match
    XCTAssertGreaterThan(results.count, 0)
    // Should have OPTIONS section
    XCTAssertTrue(formatted.contains("OPTIONS:"))
    // Format should be "    --config: <wrapped text>"
    XCTAssertTrue(formatted.contains("--config:"))
    // Should have wrapped lines with proper indentation
    let lines = formatted.split(separator: "\n")
    let hasIndentedLine = lines.contains { line in
      line.starts(with: "      ")  // 6 spaces for continuation
    }
    XCTAssertTrue(
      hasIndentedLine, "Argument description should wrap with 6-space indent")
  }

  func testFormatResults_ArgumentValueFormatting() {
    // Test the .argumentValue case formatting
    struct TestCommand: ParsableCommand {
      @Option(help: "The output format")
      var format: OutputFormat = .yaml
    }

    let tree = CommandParser(TestCommand.self).commandTree
    let engine = CommandSearcher(
      rootNode: tree,
      commandStack: [TestCommand.self],
      visibility: .default
    )

    let results = engine.search(for: "yaml")
    let formatted = CommandSearcher.formatResults(
      results,
      term: "yaml",
      toolName: "test-command",
      screenWidth: 80,
      useHighlighting: false
    )

    // Should find the match
    XCTAssertGreaterThan(results.count, 0)
    // Should have OPTIONS section
    XCTAssertTrue(formatted.contains("OPTIONS:"))
    // Format should be "    --format (possible value: yaml)" or "    --format (default: yaml)"
    XCTAssertTrue(formatted.contains("--format"))
    XCTAssertTrue(formatted.contains("yaml"))
    // Should have parentheses around the value snippet
    XCTAssertTrue(formatted.contains("(") && formatted.contains(")"))
  }

  func testFormatResults_DefaultValueFormatting() {
    // Test .argumentValue formatting for default values specifically
    struct TestCommand: ParsableCommand {
      @Option(help: "Log file path")
      var logPath: String = "/tmp/app.log"
    }

    let tree = CommandParser(TestCommand.self).commandTree
    let engine = CommandSearcher(
      rootNode: tree,
      commandStack: [TestCommand.self],
      visibility: .default
    )

    let results = engine.search(for: "app.log")
    let formatted = CommandSearcher.formatResults(
      results,
      term: "app.log",
      toolName: "test-command",
      screenWidth: 80,
      useHighlighting: false
    )

    // Should find the match
    XCTAssertGreaterThan(results.count, 0)
    // Should have OPTIONS section
    XCTAssertTrue(formatted.contains("OPTIONS:"))
    // Format should be "    --log-path (default: /tmp/app.log)"
    XCTAssertTrue(formatted.contains("--log-path"))
    XCTAssertTrue(formatted.contains("default:"))
    // Check for parts of the path (the matched part may have ANSI codes)
    XCTAssertTrue(formatted.contains("/tmp/"))
    XCTAssertTrue(formatted.contains("app.log"))
  }
}
