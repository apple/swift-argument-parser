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
import Foundation
import Testing

// Shared helpers for the source-location tracking test suites.

/// Drives `T.parse(arguments)` expecting failure, then returns the short error message produced by the framework.
///
/// Records an issue if parsing unexpectedly succeeded.
func errorMessage<T: ParsableArguments>(
  for type: T.Type,
  arguments: [String],
  sourceLocation: SourceLocation = #_sourceLocation
) throws -> String {
  #if compiler(>=6.1)
  let error = try #require(
    throws: (any Error).self,
    "Parsing should have failed for \(arguments).",
    sourceLocation: sourceLocation,
  ) {
    _ = try T.parse(arguments)
  }
  return T.message(for: error)
  #else
  do {
    _ = try T.parse(arguments)
    Issue.record(
      "Parsing should have failed for \(arguments).",
      sourceLocation: sourceLocation)
    return ""
  } catch {
    return T.message(for: error)
  }
  #endif
}

/// Drives `T.parseAsRoot(arguments)` expecting the framework to throw (either a real parse error or a clean-exit signal such as a dump request), then returns the full rendered message.
///
/// Records an issue if parsing succeeded.
func fullMessage<T: ParsableCommand>(
  for type: T.Type,
  arguments: [String],
  sourceLocation: SourceLocation = #_sourceLocation
) throws -> String {
  #if compiler(>=6.1)
  let error = try #require(
    throws: (any Error).self,
    "Parsing should have thrown for \(arguments).",
    sourceLocation: sourceLocation,
  ) {
    _ = try type.parseAsRoot(arguments)
  }
  return type.fullMessage(for: error)
  #else
  do {
    _ = try type.parseAsRoot(arguments)
    Issue.record(
      "Parsing should have thrown for \(arguments).",
      sourceLocation: sourceLocation)
    return ""
  } catch {
    return type.fullMessage(for: error)
  }
  #endif
}

/// Drives `T.parseAsRoot(arguments)` expecting failure, then returns the short error message.
///
/// Records an issue if parsing succeeded.
func rootErrorMessage<T: ParsableCommand>(
  for type: T.Type,
  arguments: [String],
  sourceLocation: SourceLocation = #_sourceLocation
) throws -> String {
  #if compiler(>=6.1)
  let error = try #require(
    throws: (any Error).self,
    "Parsing should have failed for \(arguments).",
    sourceLocation: sourceLocation,
  ) {
    _ = try type.parseAsRoot(arguments)
  }
  return type.message(for: error)
  #else
  do {
    _ = try type.parseAsRoot(arguments)
    Issue.record(
      "Parsing should have failed for \(arguments).",
      sourceLocation: sourceLocation)
    return ""
  } catch {
    return type.message(for: error)
  }
  #endif
}
