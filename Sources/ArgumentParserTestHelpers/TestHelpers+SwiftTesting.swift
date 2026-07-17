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
import Testing

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
