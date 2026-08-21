//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2025-2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import ArgumentParser
import ArgumentParserTestHelpers
import Testing

@Suite struct DefaultAsFlagEndToEndTests {

  // MARK: - Test Cases

  // Test struct for defaultAsFlag without transform - explicit nil
  private struct CommandWithDefaultAsFlagWithoutTransformExplicitNil:
    ParsableCommand
  {
    @Option(name: .customLong("bin-path"), defaultAsFlag: "/default/path")
    var showBinPath: String? = nil
  }

  // Test struct for defaultAsFlag without transform - no explicit default
  private struct CommandWithDefaultAsFlagWithoutTransformNoExplicitNil:
    ParsableCommand
  {
    @Option(name: .customLong("bin-path"), defaultAsFlag: "/default/path")
    var showBinPath: String?
  }

  // Test struct for defaultAsFlag with transform - explicit nil
  private struct CommandWithDefaultAsFlagWithTransformExplicitNil:
    ParsableCommand
  {
    @Option(
      name: .customLong("bin-path"), defaultAsFlag: "/default/path",
      transform: { $0.uppercased() })
    var showBinPath: String? = nil
  }

  // Test struct for defaultAsFlag with transform - no explicit default
  private struct CommandWithDefaultAsFlagWithTransformNoExplicitNil:
    ParsableCommand
  {
    @Option(
      name: .customLong("bin-path"), defaultAsFlag: "/default/path",
      transform: { $0.uppercased() })
    var showBinPath: String?
  }

  @Test func defaultAsFlagWithExplicitNil() throws {
    // When no argument is provided, should be nil
    expectParse(CommandWithDefaultAsFlagWithoutTransformExplicitNil.self, []) {
      cmd in
      #expect(cmd.showBinPath == nil)
    }

    // When flag is provided without value, should use defaultAsFlag
    expectParse(
      CommandWithDefaultAsFlagWithoutTransformExplicitNil.self, ["--bin-path"]
    ) { cmd in
      #expect(cmd.showBinPath == "/default/path")
    }

    // When flag is provided with value, should use provided value
    expectParse(
      CommandWithDefaultAsFlagWithoutTransformExplicitNil.self,
      ["--bin-path", "/custom/path"]
    ) { cmd in
      #expect(cmd.showBinPath == "/custom/path")
    }
  }

  @Test func defaultAsFlagWithoutExplicitDefault() throws {
    // When no argument is provided, should be nil
    expectParse(CommandWithDefaultAsFlagWithoutTransformNoExplicitNil.self, [])
    { cmd in
      #expect(cmd.showBinPath == nil)
    }

    // When flag is provided without value, should use defaultAsFlag
    expectParse(
      CommandWithDefaultAsFlagWithoutTransformNoExplicitNil.self, ["--bin-path"]
    ) { cmd in
      #expect(cmd.showBinPath == "/default/path")
    }

    // When flag is provided with value, should use provided value
    expectParse(
      CommandWithDefaultAsFlagWithoutTransformNoExplicitNil.self,
      ["--bin-path", "/custom/path"]
    ) { cmd in
      #expect(cmd.showBinPath == "/custom/path")
    }
  }

  @Test func defaultAsFlagWithTransformWithExplicitNil() throws {
    // When no argument is provided, should be nil
    expectParse(CommandWithDefaultAsFlagWithTransformExplicitNil.self, []) {
      cmd in
      #expect(cmd.showBinPath == nil)
    }

    // When flag is provided without value, should use defaultAsFlag
    expectParse(
      CommandWithDefaultAsFlagWithTransformExplicitNil.self, ["--bin-path"]
    ) { cmd in
      #expect(cmd.showBinPath == "/default/path")
    }

    // When flag is provided with value, should use provided value with transform
    expectParse(
      CommandWithDefaultAsFlagWithTransformExplicitNil.self,
      ["--bin-path", "/custom/path"]
    ) { cmd in
      #expect(cmd.showBinPath == "/CUSTOM/PATH")
    }
  }

  @Test func defaultAsFlagWithTransformWithoutExplicitDefault() throws {
    // When no argument is provided, should be nil
    expectParse(CommandWithDefaultAsFlagWithTransformNoExplicitNil.self, []) {
      cmd in
      #expect(cmd.showBinPath == nil)
    }

    // When flag is provided without value, should use defaultAsFlag
    expectParse(
      CommandWithDefaultAsFlagWithTransformNoExplicitNil.self, ["--bin-path"]
    ) { cmd in
      #expect(cmd.showBinPath == "/default/path")
    }

    // When flag is provided with value, should use provided value with transform
    expectParse(
      CommandWithDefaultAsFlagWithTransformNoExplicitNil.self,
      ["--bin-path", "/custom/path"]
    ) { cmd in
      #expect(cmd.showBinPath == "/CUSTOM/PATH")
    }
  }

  // MARK: - Tests for -- terminator behavior

  private struct CommandWithDefaultAsFlagAndArguments: ParsableCommand {
    @Option(defaultAsFlag: "default")
    var option: String?

    @Argument
    var files: [String] = []
  }

  @Test func defaultAsFlagWithTerminatorFlagBeforeTerminator() throws {
    // --option -- value
    // Should use defaultAsFlag value, "value" becomes positional argument
    expectParse(
      CommandWithDefaultAsFlagAndArguments.self, ["--option", "--", "value"]
    ) { cmd in
      #expect(cmd.option == "default")
      #expect(cmd.files == ["value"])
    }
  }

  @Test func defaultAsFlagWithTerminatorValueBeforeTerminator() throws {
    // --option custom -- other
    // Should use "custom" as option value, "other" becomes positional argument
    expectParse(
      CommandWithDefaultAsFlagAndArguments.self,
      ["--option", "custom", "--", "other"]
    ) { cmd in
      #expect(cmd.option == "custom")
      #expect(cmd.files == ["other"])
    }
  }

  func implTestDefaultAsFlagWithTerminatorValueBeforeTerminator(
    optionValue: String,
    sourceLocation: SourceLocation = #_sourceLocation
  ) throws {
    // --option custom -- other
    // Should use "custom" as option value, "other" becomes positional argument
    expectParse(
      CommandWithDefaultAsFlagAndArguments.self,
      ["--option", optionValue, "--", "other"],
      sourceLocation: sourceLocation
    ) { cmd in
      #expect(cmd.option == optionValue, sourceLocation: sourceLocation)
      #expect(cmd.files == ["other"], sourceLocation: sourceLocation)
    }
  }

  @Test func defaultAsFlagWithValueWithTerminatorValueBeforeTerminator() throws
  {
    try implTestDefaultAsFlagWithTerminatorValueBeforeTerminator(
      optionValue: "custom")
  }

  @Test
  func defaultAsFlagWithCompleteValueAndWithTerminatorValueBeforeTerminator()
    throws
  {
    try implTestDefaultAsFlagWithTerminatorValueBeforeTerminator(
      optionValue: "--somearg=value")
  }

  @Test
  func
    defaultAsFlagWithCompleteValueAndWithTerminatorValueInQuotesBeforeTerminator()
    throws
  {
    try implTestDefaultAsFlagWithTerminatorValueBeforeTerminator(
      optionValue: "--somearg=\"value\"")
  }

  @Test func defaultAsFlagWithTerminatorOptionAfterTerminator() throws {
    // -- --option
    // Should treat "--option" as positional argument, option should be nil
    expectParse(CommandWithDefaultAsFlagAndArguments.self, ["--", "--option"]) {
      cmd in
      #expect(cmd.option == nil)
      #expect(cmd.files == ["--option"])
    }
  }

  @Test func defaultAsFlagWithTerminatorComplexScenario() throws {
    // --option -- --another-option value
    // Should use defaultAsFlag, everything after -- is positional
    expectParse(
      CommandWithDefaultAsFlagAndArguments.self,
      ["--option", "--", "--another-option", "value"]
    ) { cmd in
      #expect(cmd.option == "default")
      #expect(cmd.files == ["--another-option", "value"])
    }
  }

  @Test func defaultAsFlagWithTerminatorValueAfterTerminatorNotConsumed() throws
  {
    // --option -- value1 value2
    // Should use defaultAsFlag, both values become positional arguments
    expectParse(
      CommandWithDefaultAsFlagAndArguments.self,
      ["--option", "--", "value1", "value2"]
    ) { cmd in
      #expect(cmd.option == "default")
      #expect(cmd.files == ["value1", "value2"])
    }
  }

  // MARK: - Tests for parsing strategy compilation restrictions

  @Test func defaultAsFlagCompilationRestrictionsWork() throws {
    // This test verifies that DefaultAsFlagParsingStrategy only allows compatible strategies
    // and prevents .unconditional at compile time

    struct CommandWithAllowedStrategies: ParsableCommand {
      // These should compile successfully
      @Option(defaultAsFlag: "next", parsing: .next)
      var nextStrategy: String?

      @Option(defaultAsFlag: "scanning", parsing: .scanningForValue)
      var scanningStrategy: String?
    }

    // Verify that the allowed strategies work correctly
    expectParse(CommandWithAllowedStrategies.self, ["--next-strategy"]) { cmd in
      #expect(cmd.nextStrategy == "next")
      #expect(cmd.scanningStrategy == nil)
    }

    expectParse(CommandWithAllowedStrategies.self, ["--scanning-strategy"]) {
      cmd in
      #expect(cmd.nextStrategy == nil)
      #expect(cmd.scanningStrategy == "scanning")
    }

    expectParse(
      CommandWithAllowedStrategies.self, ["--next-strategy", "custom"]
    ) { cmd in
      #expect(cmd.nextStrategy == "custom")
      #expect(cmd.scanningStrategy == nil)
    }

    expectParse(
      CommandWithAllowedStrategies.self,
      ["--scanning-strategy", "--next-strategy", "next-custom"]
    ) { cmd in
      #expect(cmd.nextStrategy == "next-custom")
      #expect(cmd.scanningStrategy == "scanning")
    }

    expectParse(
      CommandWithAllowedStrategies.self,
      ["--next-strategy", "next-custom", "--scanning-strategy"]
    ) { cmd in
      #expect(cmd.nextStrategy == "next-custom")
      #expect(cmd.scanningStrategy == "scanning")
    }

    expectParse(
      CommandWithAllowedStrategies.self,
      [
        "--scanning-strategy", "scanning-custom", "--next-strategy",
        "next-custom",
      ]
    ) { cmd in
      #expect(cmd.nextStrategy == "next-custom")
      #expect(cmd.scanningStrategy == "scanning-custom")
    }

  }
}
