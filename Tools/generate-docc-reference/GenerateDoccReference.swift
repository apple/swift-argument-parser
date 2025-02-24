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
import ArgumentParserToolInfo
import Foundation

enum GenerateDoccReferenceError: Error {
  case failedToRunSubprocess(error: Error)
  case unableToParseToolOutput(error: Error)
  case unsupportedDumpHelpVersion(expected: Int, found: Int)
  case failedToGenerateDoccReference(error: Error)
}

extension GenerateDoccReferenceError: CustomStringConvertible {
  var description: String {
    switch self {
    case .failedToRunSubprocess(let error):
      return "Failed to run subprocess: \(error)"
    case .unableToParseToolOutput(let error):
      return "Failed to parse tool output: \(error)"
    case .unsupportedDumpHelpVersion(let expected, let found):
      return
        "Unsupported dump help version, expected '\(expected)' but found: '\(found)'"
    case .failedToGenerateDoccReference(let error):
      return "Failed to generated docc reference: \(error)"
    }
  }
}

@main
struct GenerateDoccReference: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "generate-docc-reference",
    abstract: "Generate a docc reference for the provided tool.")

  @Argument(help: "Tool to generate docc reference for.")
  var tool: String

  @Option(
    name: .shortAndLong,
    help: "Directory to save generated docc reference. Use '-' for stdout.")
  var outputDirectory: String

  func validate() throws {
    if outputDirectory != "-" {
      // outputDirectory must already exist, `GenerateDoccReference` will not create it.
      var objcBool: ObjCBool = true
      guard
        FileManager.default.fileExists(
          atPath: outputDirectory, isDirectory: &objcBool)
      else {
        throw ValidationError(
          "Output directory \(outputDirectory) does not exist")
      }

      guard objcBool.boolValue else {
        throw ValidationError(
          "Output directory \(outputDirectory) is not a directory")
      }
    }
  }

  func run() throws {
    let data: Data
    do {
      let tool = URL(fileURLWithPath: tool)
      let output = try executeCommand(
        executable: tool, arguments: ["--experimental-dump-help"])
      data = output.data(using: .utf8) ?? Data()
    } catch {
      throw GenerateDoccReferenceError.failedToRunSubprocess(error: error)
    }

    do {
      let toolInfoThin = try JSONDecoder().decode(
        ToolInfoHeader.self, from: data)
      guard toolInfoThin.serializationVersion == 0 else {
        throw GenerateDoccReferenceError.unsupportedDumpHelpVersion(
          expected: 0,
          found: toolInfoThin.serializationVersion)
      }
    } catch {
      throw GenerateDoccReferenceError.unableToParseToolOutput(error: error)
    }

    let toolInfo: ToolInfoV0
    do {
      toolInfo = try JSONDecoder().decode(ToolInfoV0.self, from: data)
    } catch {
      throw GenerateDoccReferenceError.unableToParseToolOutput(error: error)
    }

    do {
      if self.outputDirectory == "-" {
        try self.generatePages(from: toolInfo.command, savingTo: nil)
      } else {
        try self.generatePages(
          from: toolInfo.command,
          savingTo: URL(fileURLWithPath: outputDirectory))
      }
    } catch {
      throw GenerateDoccReferenceError.failedToGenerateDoccReference(
        error: error)
    }
  }

  func generatePages(
    from command: CommandInfoV0, savingTo directory: URL?
  ) throws {
    let page = command.toMarkdown([])

    if let directory = directory {
      let fileName = command.doccReferenceFileName
      let outputPath = directory.appendingPathComponent(fileName)
      try page.write(to: outputPath, atomically: false, encoding: .utf8)
    } else {
      print(page)
    }
  }
}
