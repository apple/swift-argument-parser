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

import Foundation
import XCTest

@testable import ArgumentParserOpenCLI

final class OpenCLITests: XCTestCase {

  func testDecodeExampleJSON() throws {
    let jsonString = """
      {
          "$schema": "https://opencli.org/draft.json",
          "opencli": "0.1",
          "info": {
              "title": "dotnet",
              "version": "9.0.1",
              "description": "The .NET CLI",
              "license": {
                  "name": "MIT License",
                  "identifier": "MIT"
              }
          },
          "options": [
              {
                  "name": "--help",
                  "aliases": [ "-h" ],
                  "description": "Display help."
              },
              {
                  "name": "--info",
                  "description": "Display .NET information."
              },
              {
                  "name": "--list-sdks",
                  "description": "Display the installed SDKs."
              },
              {
                  "name": "--list-runtimes",
                  "description": "Display the installed runtimes."
              }
          ],
          "commands": [
              {
                  "name": "build",
                  "arguments": [
                      {
                          "name": "PROJECT | SOLUTION",
                          "description": "The project or solution file to operate on. If a file is not specified, the command will search the current directory for one."
                      }
                  ],
                  "options": [
                      {
                          "name": "--configuration",
                          "aliases": [ "-c" ],
                          "description": "The configuration to use for building the project. The default for most projects is 'Debug'.",
                          "arguments": [
                              {
                                  "name": "CONFIGURATION",
                                  "required": true,
                                  "arity": {
                                      "minimum": 1,
                                      "maximum": 1
                                  }
                              }
                          ]
                      }
                  ]
              }
          ]
      }
      """

    let jsonData = jsonString.data(using: .utf8)!
    let decoder = JSONDecoder()

    let openCLI = try decoder.decode(OpenCLIv0_1.self, from: jsonData)

    // Verify root properties
    XCTAssertEqual(openCLI.opencli, "0.1")

    // Verify info
    XCTAssertEqual(openCLI.info.title, "dotnet")
    XCTAssertEqual(openCLI.info.version, "9.0.1")
    XCTAssertEqual(openCLI.info.description, "The .NET CLI")
    XCTAssertEqual(openCLI.info.license?.name, "MIT License")
    XCTAssertEqual(openCLI.info.license?.identifier, "MIT")

    // Verify options
    XCTAssertEqual(openCLI.options?.count, 4)

    let helpOption = openCLI.options?[0]
    XCTAssertEqual(helpOption?.name, "--help")
    XCTAssertEqual(helpOption?.aliases, ["-h"])
    XCTAssertEqual(helpOption?.description, "Display help.")

    let infoOption = openCLI.options?[1]
    XCTAssertEqual(infoOption?.name, "--info")
    XCTAssertEqual(infoOption?.description, "Display .NET information.")

    // Verify commands
    XCTAssertEqual(openCLI.commands?.count, 1)

    let buildCommand = openCLI.commands?[0]
    XCTAssertEqual(buildCommand?.name, "build")

    // Verify command arguments
    XCTAssertEqual(buildCommand?.arguments?.count, 1)
    let projectArg = buildCommand?.arguments?[0]
    XCTAssertEqual(projectArg?.name, "PROJECT | SOLUTION")
    XCTAssertEqual(
      projectArg?.description,
      "The project or solution file to operate on. If a file is not specified, the command will search the current directory for one."
    )

    // Verify command options
    XCTAssertEqual(buildCommand?.options?.count, 1)
    let configOption = buildCommand?.options?[0]
    XCTAssertEqual(configOption?.name, "--configuration")
    XCTAssertEqual(configOption?.aliases, ["-c"])
    XCTAssertEqual(
      configOption?.description,
      "The configuration to use for building the project. The default for most projects is 'Debug'."
    )

    // Verify option arguments with arity
    XCTAssertEqual(configOption?.arguments?.count, 1)
    let configArg = configOption?.arguments?[0]
    XCTAssertEqual(configArg?.name, "CONFIGURATION")
    XCTAssertEqual(configArg?.required, true)
    XCTAssertEqual(configArg?.arity?.minimum, 1)
    XCTAssertEqual(configArg?.arity?.maximum, 1)
  }

  func testEncodeToJSON() throws {
    let license = OpenCLIv0_1.License(name: "MIT License", identifier: "MIT")
    let info = OpenCLIv0_1.CliInfo(
      title: "test-cli",
      version: "1.0.0",
      summary: "A test CLI",
      description: "Test CLI description",
      license: license
    )

    let helpOption = OpenCLIv0_1.Option(
      name: "--help",
      aliases: ["-h"],
      description: "Show help"
    )

    let arity = OpenCLIv0_1.Arity(minimum: 1, maximum: 1)
    let configArg = OpenCLIv0_1.Argument(
      name: "CONFIG",
      required: true,
      arity: arity
    )

    let configOption = OpenCLIv0_1.Option(
      name: "--config",
      aliases: ["-c"],
      arguments: [configArg],
      description: "Configuration option"
    )

    let buildCommand = OpenCLIv0_1.Command(
      name: "build",
      options: [configOption],
      description: "Build the project"
    )

    let openCLI = OpenCLIv0_1(
      opencli: "0.1",
      info: info,
      options: [helpOption],
      commands: [buildCommand]
    )

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

    let jsonData = try encoder.encode(openCLI)
    let jsonString = String(data: jsonData, encoding: .utf8)!

    // Verify we can encode and the result contains expected keys
    XCTAssertTrue(jsonString.contains("\"opencli\" : \"0.1\""))
    XCTAssertTrue(jsonString.contains("\"title\" : \"test-cli\""))
    XCTAssertTrue(jsonString.contains("\"name\" : \"build\""))
    XCTAssertTrue(jsonString.contains("\"--help\""))

    // Verify round-trip: decode the encoded JSON
    let decoder = JSONDecoder()
    let decodedOpenCLI = try decoder.decode(OpenCLIv0_1.self, from: jsonData)

    XCTAssertEqual(decodedOpenCLI.opencli, openCLI.opencli)
    XCTAssertEqual(decodedOpenCLI.info.title, openCLI.info.title)
    XCTAssertEqual(
      decodedOpenCLI.commands?.first?.name, openCLI.commands?.first?.name)
  }

  func testOpenCLIEquatable() throws {
    let license1 = OpenCLIv0_1.License(name: "MIT License", identifier: "MIT")
    let license2 = OpenCLIv0_1.License(name: "MIT License", identifier: "MIT")
    let license3 = OpenCLIv0_1.License(
      name: "Apache License", identifier: "Apache-2.0")

    let info1 = OpenCLIv0_1.CliInfo(
      title: "test", version: "1.0.0", license: license1)
    let info2 = OpenCLIv0_1.CliInfo(
      title: "test", version: "1.0.0", license: license2)
    let info3 = OpenCLIv0_1.CliInfo(
      title: "test", version: "2.0.0", license: license1)

    let openCLI1 = OpenCLIv0_1(opencli: "0.1", info: info1)
    let openCLI2 = OpenCLIv0_1(opencli: "0.1", info: info2)
    let openCLI3 = OpenCLIv0_1(opencli: "0.1", info: info3)

    // Test equality
    XCTAssertEqual(license1, license2)
    XCTAssertNotEqual(license1, license3)
    XCTAssertEqual(info1, info2)
    XCTAssertNotEqual(info1, info3)
    XCTAssertEqual(openCLI1, openCLI2)
    XCTAssertNotEqual(openCLI1, openCLI3)

    // Test AnyCodable equality
    let metadata1 = OpenCLIv0_1.Metadata(
      name: "key", value: OpenCLIv0_1.AnyCodable("value"))
    let metadata2 = OpenCLIv0_1.Metadata(
      name: "key", value: OpenCLIv0_1.AnyCodable("value"))
    let metadata3 = OpenCLIv0_1.Metadata(
      name: "key", value: OpenCLIv0_1.AnyCodable("different"))

    XCTAssertEqual(metadata1, metadata2)
    XCTAssertNotEqual(metadata1, metadata3)

    // Test complex structures
    let option1 = OpenCLIv0_1.Option(
      name: "--verbose", aliases: ["-v"], description: "Verbose output")
    let option2 = OpenCLIv0_1.Option(
      name: "--verbose", aliases: ["-v"], description: "Verbose output")
    let option3 = OpenCLIv0_1.Option(
      name: "--quiet", aliases: ["-q"], description: "Quiet output")

    XCTAssertEqual(option1, option2)
    XCTAssertNotEqual(option1, option3)
  }
}
