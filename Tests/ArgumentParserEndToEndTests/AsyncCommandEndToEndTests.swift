//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020-2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import ArgumentParser
import Testing

@Suite(.serialized) struct AsyncCommandEndToEndTests {}

actor AsyncStatusCheck {
  struct Status: OptionSet {
    var rawValue: UInt8

    static var root: Self { .init(rawValue: 1 << 0) }
    static var sub: Self { .init(rawValue: 1 << 1) }
  }

  @MainActor
  var status: Status = []

  @MainActor
  func update(_ status: Status) {
    self.status.insert(status)
  }
}

@MainActor
var statusCheck = AsyncStatusCheck()

// MARK: AsyncParsableCommand.main() testing

struct AsyncCommand: AsyncParsableCommand {
  static var configuration: CommandConfiguration {
    .init(subcommands: [SubCommand.self])
  }

  func run() async throws {
    await statusCheck.update(.root)
  }

  struct SubCommand: AsyncParsableCommand {
    func run() async throws {
      await statusCheck.update(.sub)
    }
  }
}

// swift-format-ignore: AlwaysUseLowerCamelCase
// https://github.com/apple/swift-argument-parser/issues/710
extension AsyncCommandEndToEndTests {
  @Test @MainActor func asyncMain_root() async throws {
    #expect(!statusCheck.status.contains(.root))
    await AsyncCommand.main([])
    #expect(statusCheck.status.contains(.root))
  }

  @Test @MainActor func asyncMain_sub() async throws {
    #expect(!statusCheck.status.contains(.sub))
    await AsyncCommand.main(["sub-command"])
    #expect(statusCheck.status.contains(.sub))
  }
}
