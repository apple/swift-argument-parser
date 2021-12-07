//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// A type that can be executed as part of a nested tree of commands.
public protocol AsyncParsableCommand: ParsableCommand {
  mutating func run() async throws
}

extension AsyncParsableCommand {
  public static func main() async {
    do {
      var command = try parseAsRoot()
      if var asyncCommand = command as? AsyncParsableCommand {
        try await asyncCommand.run()
      } else {
        try command.run()
      }
    } catch {
      exit(withError: error)
    }
  }
}

@available(
  swift, deprecated: 5.6,
  message: "Use @main directly on your root `AsyncParsableCommand` type.")
public protocol AsyncMainProtocol {
  associatedtype Command: ParsableCommand
}

@available(swift, deprecated: 5.6)
extension AsyncMainProtocol {
  public static func main() async {
    do {
      var command = try Command.parseAsRoot()
      if var asyncCommand = command as? AsyncParsableCommand {
        try await asyncCommand.run()
      } else {
        try command.run()
      }
    } catch {
      Command.exit(withError: error)
    }
  }
}

