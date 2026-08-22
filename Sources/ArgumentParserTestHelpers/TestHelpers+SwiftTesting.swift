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
import ArgumentParserToolInfo
import Foundation
import Testing

private final class _BundleMarker {}

private var _debugURL: URL {
  let bundleURL = Bundle(for: _BundleMarker.self).bundleURL
  return bundleURL.lastPathComponent.hasSuffix("xctest")
    ? bundleURL.deletingLastPathComponent()
    : bundleURL
}

public func expectResultFailure<T, U: Error>(
  _ expression: @autoclosure () -> Result<T, U>,
  _ message: @autoclosure () -> String = "",
  sourceLocation: SourceLocation = #_sourceLocation
) {
  AssertResultFailure(expression(), message(), sourceLocation: sourceLocation)
}

public func expectErrorMessage<A: ParsableArguments>(
  _ type: A.Type, _ arguments: [String], _ errorMessage: String,
  sourceLocation: SourceLocation = #_sourceLocation
) {
  AssertErrorMessage(
    type, arguments, errorMessage, sourceLocation: sourceLocation)
}

public func expectFullErrorMessage<A: ParsableArguments>(
  _ type: A.Type, _ arguments: [String], _ errorMessage: String,
  sourceLocation: SourceLocation = #_sourceLocation
) {
  AssertFullErrorMessage(
    type, arguments, errorMessage, sourceLocation: sourceLocation)
}

public func expectParse<A: ParsableArguments>(
  _ type: A.Type, _ arguments: [String],
  sourceLocation: SourceLocation = #_sourceLocation,
  closure: (A) throws -> Void
) {
  AssertParse(type, arguments, sourceLocation: sourceLocation) {
    try closure($0)
  }
}

public func expectParseCommand<A: ParsableCommand>(
  _ rootCommand: ParsableCommand.Type, _ type: A.Type, _ arguments: [String],
  sourceLocation: SourceLocation = #_sourceLocation,
  closure: (A) throws -> Void
) {
  AssertParseCommand(
    rootCommand, type, arguments, sourceLocation: sourceLocation
  ) {
    try closure($0)
  }
}

public func expectEqualStrings(
  actual: String,
  expected: String,
  sourceLocation: SourceLocation = #_sourceLocation
) {
  AssertEqualStrings(
    actual: actual, expected: expected, sourceLocation: sourceLocation)
}

@discardableResult
public func requireExecuteCommand(
  command: String,
  expected: String? = nil,
  exitCode: ExitCode = .success,
  environment: [String: String] = [:],
  sourceLocation: SourceLocation = #_sourceLocation
) throws -> String {
  try requireExecuteCommand(
    command: command.split(separator: " ").map(String.init),
    expected: expected,
    exitCode: exitCode,
    environment: environment,
    sourceLocation: sourceLocation)
}

@discardableResult
public func requireExecuteCommand(
  command: [String],
  expected: String? = nil,
  exitCode: ExitCode = .success,
  environment: [String: String] = [:],
  sourceLocation: SourceLocation = #_sourceLocation
) throws -> String {
  #if os(Windows)
  return ""
  #elseif !canImport(Darwin) || os(macOS)
  let arguments = Array(command.dropFirst())
  let commandName = String(command.first!)
  let commandURL = _debugURL.appendingPathComponent(commandName)
  _ = try #require(
    try commandURL.checkResourceIsReachable(),
    "No executable at '\(commandURL.standardizedFileURL.path)'.",
    sourceLocation: sourceLocation
  )

  let process = Process()
  process.executableURL = commandURL
  process.arguments = arguments

  let output = Pipe()
  process.standardOutput = output
  let error = Pipe()
  process.standardError = error

  if !environment.isEmpty {
    if let existingEnvironment = process.environment {
      process.environment =
        existingEnvironment.merging(environment) { (_, new) in new }
    } else {
      process.environment = environment
    }
  }

  try #require(
    try? process.run(),
    "Couldn't run command process.",
    sourceLocation: sourceLocation
  )
  process.waitUntilExit()

  let outputData = output.fileHandleForReading.readDataToEndOfFile()
  let outputActual = String(data: outputData, encoding: .utf8)!

  let errorData = error.fileHandleForReading.readDataToEndOfFile()
  let errorActual = String(data: errorData, encoding: .utf8)!

  if let expected = expected {
    expectEqualStrings(
      actual: errorActual + outputActual,
      expected: expected,
      sourceLocation: sourceLocation)
  }

  #expect(
    process.terminationStatus == exitCode.rawValue,
    sourceLocation: sourceLocation)
  return outputActual
  #else
  return ""
  #endif
}

@discardableResult
public func expectSnapshot(
  actual: String,
  extension: String,
  record: Bool = false,
  test: String = #function,
  filePath: StaticString = #filePath,
  sourceLocation: SourceLocation = #_sourceLocation
) throws -> String? {
  let snapshotDirectoryURL = URL(fileURLWithPath: "\(filePath)")
    .deletingLastPathComponent()
    .appendingPathComponent("Snapshots")
  let snapshotFileURL =
    snapshotDirectoryURL
    .appendingPathComponent("\(test).\(`extension`)")

  let snapshotExists = FileManager.default.fileExists(
    atPath: snapshotFileURL.path)
  let recordEnvironment =
    ProcessInfo.processInfo.environment["RECORD_SNAPSHOTS"] != nil

  if record || recordEnvironment || !snapshotExists {
    let recordedValue = actual
    try FileManager.default.createDirectory(
      at: snapshotDirectoryURL,
      withIntermediateDirectories: true,
      attributes: nil)
    try recordedValue.write(
      to: snapshotFileURL, atomically: true, encoding: .utf8)
    Issue.record("Recorded new baseline", sourceLocation: sourceLocation)
    return nil
  } else {
    let expected = try String(contentsOf: snapshotFileURL, encoding: .utf8)
    expectEqualStrings(
      actual: actual,
      expected: expected,
      sourceLocation: sourceLocation)
    return expected
  }
}

public func expectJSONEqualFromString<T: Codable & Equatable>(
  actual: String,
  expected: String,
  for type: T.Type,
  sourceLocation: SourceLocation = #_sourceLocation
) throws {
  expectEqualStrings(
    actual: actual,
    expected: expected,
    sourceLocation: sourceLocation
  )

  let actualJSONData = try #require(
    actual.data(using: .utf8),
    sourceLocation: sourceLocation
  )
  let actualDumpJSON = try JSONDecoder().decode(type, from: actualJSONData)

  let expectedJSONData = try #require(
    expected.data(using: .utf8),
    sourceLocation: sourceLocation
  )
  let expectedDumpJSON = try JSONDecoder().decode(type, from: expectedJSONData)

  #expect(
    actualDumpJSON == expectedDumpJSON,
    sourceLocation: sourceLocation
  )
}

public func expectDumpHelp<T: ParsableArguments>(
  type: T.Type,
  record: Bool = false,
  test: String = #function,
  filePath: StaticString = #filePath,
  sourceLocation: SourceLocation = #_sourceLocation
) throws {
  // TODO: migrate to the following API when the minimum Swift version supports it
  ///
  // let error = #expect(throws: (any Error).self) {
  //     _ = try T.parse(["--experimental-dump-help"])
  // }
  // let actual = T.fullMessage(for: error)
  let actual: String
  do {
    _ = try T.parse(["--experimental-dump-help"])
    Issue.record(
      "Expected T.parse to throw a help request.",
      sourceLocation: sourceLocation)
    return
  } catch {
    actual = T.fullMessage(for: error)
  }

  let apiOutput = T._dumpHelp()
  expectEqualStrings(
    actual: actual,
    expected: apiOutput,
    sourceLocation: sourceLocation
  )

  let expected = try expectSnapshot(
    actual: actual,
    extension: "json",
    record: record,
    test: test,
    filePath: filePath,
    sourceLocation: sourceLocation
  )

  guard let expected else { return }

  try expectJSONEqualFromString(
    actual: actual,
    expected: expected,
    for: ToolInfoV0.self,
    sourceLocation: sourceLocation
  )
}

public func expectDumpHelp(
  command: String,
  record: Bool = false,
  test: String = #function,
  filePath: StaticString = #filePath,
  sourceLocation: SourceLocation = #_sourceLocation
) throws {
  let actual = try requireExecuteCommand(
    command: command + " --experimental-dump-help",
    expected: nil,
    sourceLocation: sourceLocation
  )
  try expectSnapshot(
    actual: actual,
    extension: "json",
    record: record,
    test: test,
    filePath: filePath,
    sourceLocation: sourceLocation
  )
}

public func expectGenerateManual(
  multiPage: Bool,
  command: String,
  record: Bool = false,
  test: String = #function,
  filePath: StaticString = #filePath,
  sourceLocation: SourceLocation = #_sourceLocation
) throws {
  #if os(Windows)
  ""
  #else
  let commandURL = _debugURL.appendingPathComponent(command)
  var command = [
    "generate-manual", commandURL.path,
    "--date", "1996-05-12",
    "--section", "9",
    "--authors", "Jane Appleseed",
    "--authors", "<johnappleseed@apple.com>",
    "--authors", "The Appleseeds<appleseeds@apple.com>",
    "--output-directory", "-",
  ]
  if multiPage {
    command.append("--multi-page")
  }
  let actual = try requireExecuteCommand(
    command: command,
    sourceLocation: sourceLocation)

  try expectSnapshot(
    actual: actual,
    extension: "mdoc",
    record: record,
    test: test,
    filePath: filePath,
    sourceLocation: sourceLocation)
  #endif
}

public func expectGeneratedReference(
  command: String,
  doccFlavored: Bool,
  record: Bool = false,
  test: String = #function,
  filePath: StaticString = #filePath,
  sourceLocation: SourceLocation = #_sourceLocation
) throws {
  #if os(Windows)
  ""
  #else
  let commandURL = _debugURL.appendingPathComponent(command)
  let command: [String]
  if doccFlavored {
    command = [
      "generate-docc-reference", commandURL.path,
      "--output-directory", "-",
      "--style", "docc",
    ]
  } else {
    command = [
      "generate-docc-reference", commandURL.path,
      "--output-directory", "-",
    ]
  }
  let actual = try requireExecuteCommand(
    command: command,
    sourceLocation: sourceLocation)

  try expectSnapshot(
    actual: actual,
    extension: "md",
    record: record,
    test: test,
    filePath: filePath,
    sourceLocation: sourceLocation)
  #endif
}
