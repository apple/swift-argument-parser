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

import Foundation

/// Scoped scratch directory for Swift Testing suites.
///
/// Prefer the `withTemporaryFile` / `withTemporaryDirectory` free
/// functions over instantiating this type directly — the free functions
/// own the directory's lifetime and remove it when the closure returns
/// (success *or* failure).
public struct TemporaryFileFixture {
  /// The per-invocation temporary directory.
  public let temporaryDirectory: URL

  fileprivate init(temporaryDirectory: URL) {
    self.temporaryDirectory = temporaryDirectory
  }

  /// Writes `content` to a file named `name` inside the temporary
  /// directory and returns its absolute path.
  public func writeTemporaryFile(_ name: String, content: String) throws
    -> String
  {
    let fileURL = self.temporaryDirectory.appendingPathComponent(name)
    try content.write(to: fileURL, atomically: true, encoding: .utf8)
    return fileURL.path
  }

  public func createTestFile(_ name: String, content: String) throws -> String {
    try writeTemporaryFile(name, content: content)
  }
}

/// Runs `body` with a fresh UUID-suffixed scratch directory, then
/// removes the directory when `body` returns — including when it throws.
///
/// Use this variant when the test needs to create *multiple* files that
/// share a single parent directory (e.g., response files that reference
/// each other by relative name).
///
///     try await withTemporaryDirectory { dir in
///       let a = try dir.createTestFile("a.txt", content: "...")
///       let b = try dir.createTestFile("b.txt", content: "@a.txt")
///       // ...
///     }
public func withTemporaryDirectory<Result>(
  _ body: (TemporaryFileFixture) async throws -> Result
) async throws -> Result {
  let fileManager = FileManager()
  let temporaryDirectory =
    fileManager
    .temporaryDirectory
    .appendingPathComponent("SAP")
    .appendingPathComponent(UUID().uuidString)

  try fileManager.createDirectory(
    at: temporaryDirectory,
    withIntermediateDirectories: true,
    attributes: nil)

  defer {
    try? fileManager.removeItem(at: temporaryDirectory)
  }

  let fixture = TemporaryFileFixture(temporaryDirectory: temporaryDirectory)
  return try await body(fixture)
}

/// Runs `body` with a single temporary file whose lifetime is scoped to
/// the closure.
///
/// The file — and its enclosing per-invocation temporary
/// directory — is removed when `body` returns.
///
///     try await withTemporaryFile("args.txt", content: "--name a") { path in
///       // ...
///     }
public func withTemporaryFile<Result>(
  _ name: String,
  content: String,
  _ body: (String) async throws -> Result
) async throws -> Result {
  try await withTemporaryDirectory { fixture in
    let path = try fixture.createTestFile(name, content: content)
    return try await body(path)
  }
}
