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

import ArgumentParser
import ArgumentParserTestHelpers
import XCTest

@testable import ArgumentParserOpenCLI

final class OpenCLIEndToEndTests: XCTestCase {}

// MARK: OpenCLI Flag Recognition

private struct TestCommand: ParsableCommand {
  @Flag var verbose: Bool = false
  @ArgumentParser.Option var name: String = "test"
  @ArgumentParser.Argument var input: String
}

extension OpenCLIEndToEndTests {
  func testOpenCLIFlagRecognition() throws {
    // Test that the flag is recognized and triggers the appropriate error
    do {
      _ = try TestCommand.parse(["--help-dump-opencli-v0.1"])
      XCTFail("Expected parsing to fail with OpenCLI dump request")
    } catch {
      let message = TestCommand.fullMessage(for: error)

      // Verify it's JSON output containing OpenCLI structure
      XCTAssertTrue(message.contains("\"opencli\""))
      XCTAssertTrue(message.contains("\"info\""))

      // Verify it can be parsed as valid JSON
      let jsonData = message.data(using: .utf8)!
      let openCLI = try JSONDecoder().decode(OpenCLIv0_1.self, from: jsonData)
      XCTAssertEqual(openCLI.opencli, "0.1")
    }
  }

  func testOpenCLIFlagVersusHelp() throws {
    // Test that OpenCLI flag produces different output than regular help
    let openCLIOutput: String
    do {
      _ = try TestCommand.parse(["--help-dump-opencli-v0.1"])
      XCTFail("Expected parsing to fail")
      return
    } catch {
      openCLIOutput = TestCommand.fullMessage(for: error)
    }

    let helpOutput: String
    do {
      _ = try TestCommand.parse(["--help"])
      XCTFail("Expected parsing to fail")
      return
    } catch {
      helpOutput = TestCommand.fullMessage(for: error)
    }

    // Verify outputs are different
    XCTAssertNotEqual(openCLIOutput, helpOutput)

    // Verify OpenCLI is JSON
    XCTAssertTrue(openCLIOutput.hasPrefix("{"))
    XCTAssertTrue(openCLIOutput.hasSuffix("}"))

    // Verify help is text
    XCTAssertTrue(helpOutput.contains("USAGE:"))
    XCTAssertFalse(helpOutput.hasPrefix("{"))
  }

  func testOpenCLIFlagWithInvalidArguments() throws {
    // Test that OpenCLI flag works even when other arguments are invalid
    do {
      _ = try TestCommand.parse([
        "--help-dump-opencli-v0.1", "invalid", "extra", "args",
      ])
      XCTFail("Expected parsing to fail with OpenCLI dump request")
    } catch {
      let message = TestCommand.fullMessage(for: error)

      // Should still produce OpenCLI JSON, not validation errors
      XCTAssertTrue(message.contains("\"opencli\""))

      let jsonData = message.data(using: .utf8)!
      let openCLI = try JSONDecoder().decode(OpenCLIv0_1.self, from: jsonData)
      XCTAssertEqual(openCLI.opencli, "0.1")
    }
  }
}
