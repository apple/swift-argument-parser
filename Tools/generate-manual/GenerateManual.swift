//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import ArgumentParser
import ArgumentParserToolInfo
import Foundation

@main
struct GenerateManual: ParsableCommand {
  enum Error: Swift.Error {
    case failedToRunSubprocess(error: Swift.Error)
    case unableToParseToolOutput(error: Swift.Error)
    case unsupportedDumpHelpVersion(expected: Int, found: Int)
    case failedToGenerateManualPages(error: Swift.Error)
  }

  static let configuration = CommandConfiguration(
    commandName: "generate-manual",
    abstract: "Generate a manual for the provided tool.",
    discussion: """
      The generate-manual tool powers the generate-manual plugin and typically \
      should not be directly invoked. Instead manuals should be generated \
      using the plugin which can be invoked via \
      `swift package generate-manual`.
      """,
    supplementalDiscussion: """
      The generate-manual tool invokes provided executable with the \
      `--experimental-dump-help` argument and decoding the output into a \
      `ToolInfo` structure provided by the `ArgumentParserToolInfo` library. \
      The executable's `ToolInfo` is then transformed into to an \
      `MDocComponent` tree using a SwiftUI-esk resultBuilder DSL. Next, the \
      `MDocComponent` tree is lowered into an `Array` of `MDocASTNode` trees. \
      Lastly, the `MDocASTNode` trees are serialized to a manual page on disk.
      """)

  @Argument(help: "Tool to generate manual for.")
  var tool: String

  @Flag(help: "Generate a separate manual for each subcommand.")
  var multiPage = false

  @Option(
    name: .long,
    help: "Override the creation date of the manual. Format: 'yyyy-mm-dd'.")
  var date: Date = Date()

  @Option(
    name: .long,
    help: .init(
      "The manual section.",
      discussion: """
        Manuals for executables are typically included in section 1, but may \
        also be found in other sections such as section 8.
        """,
      supplementalDiscussion: """
        A description of manual sections is included below:
        1) General Commands
        2) System Calls
        3) Library Functions
        4) Device Drivers
        5) File Formats
        6) Games
        7) Miscellaneous Information
        8) System Manager's Manual
        9) Kernel Developer's Manual
        """))
  var section: Int = 1

  @Option(
    name: .long,
    help: "Names and/or emails of the tool's authors. Format: 'name<email>'.")
  var authors: [AuthorArgument] = []

  @Option(
    name: .shortAndLong,
    help: "Directory to save generated manual. Use '-' for stdout.")
  var outputDirectory: String

  func validate() throws {
    // Only man pages 1 through 9 are valid.
    guard (1...9).contains(section) else {
      throw ValidationError("Invalid manual section passed to --section")
    }

    if outputDirectory != "-" {
      // `outputDirectory` must already exist, `GenerateManual` will not create
      // it.
      var objcBool: ObjCBool = true
      guard FileManager.default.fileExists(
        atPath: outputDirectory, isDirectory: &objcBool) else {
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
      throw Error.failedToRunSubprocess(error: error)
    }

    do {
      let decoder = JSONDecoder()
      let toolInfoHeader = try decoder.decode(ToolInfoHeader.self, from: data)
      guard toolInfoHeader.serializationVersion == 0 else {
        throw Error.unsupportedDumpHelpVersion(
          expected: 0,
          found: toolInfoHeader.serializationVersion)
      }
    } catch {
      throw Error.unableToParseToolOutput(error: error)
    }

    let toolInfo: ToolInfoV0
    do {
      toolInfo = try JSONDecoder().decode(ToolInfoV0.self, from: data)
    } catch {
      throw Error.unableToParseToolOutput(error: error)
    }

    do {
      if outputDirectory == "-" {
        try generatePages(from: toolInfo.command, savingTo: nil)
      } else {
        try generatePages(
          from: toolInfo.command,
          savingTo: URL(fileURLWithPath: outputDirectory))
      }
    } catch {
      throw Error.failedToGenerateManualPages(error: error)
    }
  }

  func generatePages(
    from command: CommandInfoV0, savingTo directory: URL?
  ) throws {
    let document = Document(
      multiPage: multiPage,
      date: date,
      section: section,
      authors: authors,
      command: command)
    let page = document.ast.map { $0.serialized() }.joined(separator: "\n")

    if let directory = directory {
      let fileName = command.manualPageFileName(section: section)
      let outputPath = directory.appendingPathComponent(fileName)
      try page.write(to: outputPath, atomically: false, encoding: .utf8)
    } else {
      print(page)
    }

    if multiPage {
      for subcommand in command.subcommands ?? [] {
        try generatePages(from: subcommand, savingTo: directory)
      }
    }
  }
}
