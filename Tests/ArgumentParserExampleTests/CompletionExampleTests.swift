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

#if os(macOS) || os(Linux)
import Foundation
import Testing

private final class CompletionBundleMarker {}

struct CompletionExampleTests {
  enum Shell: String, CaseIterable {
    case bash, zsh, fish

    static var available: [Self] {
      allCases.filter {
        CompletionExampleTests.isExecutableAvailable($0.rawValue)
      }
    }
  }

  static func isExecutableAvailable(_ name: String) -> Bool {
    (ProcessInfo.processInfo.environment["PATH"] ?? "")
      .split(separator: ":")
      .contains {
        FileManager.default.isExecutableFile(atPath: "\($0)/\(name)")
      }
  }

  @Test(
    .enabled(if: isExecutableAvailable("python3")),
    arguments: Shell.available, 0..<3
  )
  func interactiveCompletion(shell: Shell, fixture: Int) throws {
    let bundleURL = Bundle(for: CompletionBundleMarker.self).bundleURL
    let binaryDirectory =
      bundleURL.lastPathComponent.hasSuffix("xctest")
      ? bundleURL.deletingLastPathComponent() : bundleURL
    let script = try #require(
      Bundle.module.url(
        forResource: "test_completions", withExtension: "py",
        subdirectory: "CompletionTests"))
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = [
      "python3", script.path, "--bin-dir", binaryDirectory.path,
      "--shell", shell.rawValue, "--case", String(fixture),
    ]
    let output = Pipe()
    process.standardOutput = output
    process.standardError = output
    try process.run()
    let data = output.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    let transcript = String(decoding: data, as: UTF8.self)
    #expect(process.terminationStatus == 0, "\(transcript)")
  }
}
#endif
