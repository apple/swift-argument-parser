//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import ArgumentParser
import ArgumentParserTestHelpers
import XCTest

final class DefaultAsFlagEndToEndTests: XCTestCase {}

// MARK: - Test Cases

extension DefaultAsFlagEndToEndTests {

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

  func testDefaultAsFlagWithExplicitNil() throws {
    // When no argument is provided, should be nil
    AssertParse(CommandWithDefaultAsFlagWithoutTransformExplicitNil.self, []) {
      cmd in
      XCTAssertNil(cmd.showBinPath)
    }

    // When flag is provided without value, should use defaultAsFlag
    AssertParse(
      CommandWithDefaultAsFlagWithoutTransformExplicitNil.self, ["--bin-path"]
    ) { cmd in
      XCTAssertEqual(cmd.showBinPath, "/default/path")
    }

    // When flag is provided with value, should use provided value
    AssertParse(
      CommandWithDefaultAsFlagWithoutTransformExplicitNil.self,
      ["--bin-path", "/custom/path"]
    ) { cmd in
      XCTAssertEqual(cmd.showBinPath, "/custom/path")
    }
  }

  func testDefaultAsFlagWithoutExplicitDefault() throws {
    // When no argument is provided, should be nil
    AssertParse(CommandWithDefaultAsFlagWithoutTransformNoExplicitNil.self, [])
    { cmd in
      XCTAssertNil(cmd.showBinPath)
    }

    // When flag is provided without value, should use defaultAsFlag
    AssertParse(
      CommandWithDefaultAsFlagWithoutTransformNoExplicitNil.self, ["--bin-path"]
    ) { cmd in
      XCTAssertEqual(cmd.showBinPath, "/default/path")
    }

    // When flag is provided with value, should use provided value
    AssertParse(
      CommandWithDefaultAsFlagWithoutTransformNoExplicitNil.self,
      ["--bin-path", "/custom/path"]
    ) { cmd in
      XCTAssertEqual(cmd.showBinPath, "/custom/path")
    }
  }

  func testDefaultAsFlagWithTransformWithExplicitNil() throws {
    // When no argument is provided, should be nil
    AssertParse(CommandWithDefaultAsFlagWithTransformExplicitNil.self, []) {
      cmd in
      XCTAssertNil(cmd.showBinPath)
    }

    // When flag is provided without value, should use defaultAsFlag
    AssertParse(
      CommandWithDefaultAsFlagWithTransformExplicitNil.self, ["--bin-path"]
    ) { cmd in
      XCTAssertEqual(cmd.showBinPath, "/default/path")
    }

    // When flag is provided with value, should use provided value with transform
    AssertParse(
      CommandWithDefaultAsFlagWithTransformExplicitNil.self,
      ["--bin-path", "/custom/path"]
    ) { cmd in
      XCTAssertEqual(cmd.showBinPath, "/CUSTOM/PATH")
    }
  }

  func testDefaultAsFlagWithTransformWithoutExplicitDefault() throws {
    // When no argument is provided, should be nil
    AssertParse(CommandWithDefaultAsFlagWithTransformNoExplicitNil.self, []) {
      cmd in
      XCTAssertNil(cmd.showBinPath)
    }

    // When flag is provided without value, should use defaultAsFlag
    AssertParse(
      CommandWithDefaultAsFlagWithTransformNoExplicitNil.self, ["--bin-path"]
    ) { cmd in
      XCTAssertEqual(cmd.showBinPath, "/default/path")
    }

    // When flag is provided with value, should use provided value with transform
    AssertParse(
      CommandWithDefaultAsFlagWithTransformNoExplicitNil.self,
      ["--bin-path", "/custom/path"]
    ) { cmd in
      XCTAssertEqual(cmd.showBinPath, "/CUSTOM/PATH")
    }
  }

  // MARK: - Tests for -- terminator behavior

  private struct CommandWithDefaultAsFlagAndArguments: ParsableCommand {
    @Option(defaultAsFlag: "default")
    var option: String?

    @Argument
    var files: [String] = []
  }

  func testDefaultAsFlagWithTerminatorFlagBeforeTerminator() throws {
    // --option -- value
    // Should use defaultAsFlag value, "value" becomes positional argument
    AssertParse(
      CommandWithDefaultAsFlagAndArguments.self, ["--option", "--", "value"]
    ) { cmd in
      XCTAssertEqual(cmd.option, "default")
      XCTAssertEqual(cmd.files, ["value"])
    }
  }

  func testDefaultAsFlagWithTerminatorValueBeforeTerminator() throws {
    // --option custom -- other
    // Should use "custom" as option value, "other" becomes positional argument
    AssertParse(
      CommandWithDefaultAsFlagAndArguments.self,
      ["--option", "custom", "--", "other"]
    ) { cmd in
      XCTAssertEqual(cmd.option, "custom")
      XCTAssertEqual(cmd.files, ["other"])
    }
  }

  func testDefaultAsFlagWithTerminatorOptionAfterTerminator() throws {
    // -- --option
    // Should treat "--option" as positional argument, option should be nil
    AssertParse(CommandWithDefaultAsFlagAndArguments.self, ["--", "--option"]) {
      cmd in
      XCTAssertNil(cmd.option)
      XCTAssertEqual(cmd.files, ["--option"])
    }
  }

  func testDefaultAsFlagWithTerminatorComplexScenario() throws {
    // --option -- --another-option value
    // Should use defaultAsFlag, everything after -- is positional
    AssertParse(
      CommandWithDefaultAsFlagAndArguments.self,
      ["--option", "--", "--another-option", "value"]
    ) { cmd in
      XCTAssertEqual(cmd.option, "default")
      XCTAssertEqual(cmd.files, ["--another-option", "value"])
    }
  }

  func testDefaultAsFlagWithTerminatorValueAfterTerminatorNotConsumed() throws {
    // --option -- value1 value2
    // Should use defaultAsFlag, both values become positional arguments
    AssertParse(
      CommandWithDefaultAsFlagAndArguments.self,
      ["--option", "--", "value1", "value2"]
    ) { cmd in
      XCTAssertEqual(cmd.option, "default")
      XCTAssertEqual(cmd.files, ["value1", "value2"])
    }
  }

  // MARK: - Tests for parsing strategy compilation restrictions

  func testDefaultAsFlagCompilationRestrictionsWork() throws {
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
    AssertParse(CommandWithAllowedStrategies.self, ["--next-strategy"]) { cmd in
      XCTAssertEqual(cmd.nextStrategy, "next")
      XCTAssertNil(cmd.scanningStrategy)
    }

    AssertParse(CommandWithAllowedStrategies.self, ["--scanning-strategy"]) {
      cmd in
      XCTAssertNil(cmd.nextStrategy)
      XCTAssertEqual(cmd.scanningStrategy, "scanning")
    }

    AssertParse(
      CommandWithAllowedStrategies.self, ["--next-strategy", "custom"]
    ) { cmd in
      XCTAssertEqual(cmd.nextStrategy, "custom")
      XCTAssertNil(cmd.scanningStrategy)
    }
  }
}
