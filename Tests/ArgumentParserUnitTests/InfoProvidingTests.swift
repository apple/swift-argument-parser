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
import Testing

@testable import ArgumentParser

#if os(Windows)
import WinSDK
#endif

@Suite struct InfoProvidingTests {
  struct SeedCommand: AsyncParsableCommand, InfoProvidingParsableCommand {
    @Argument var seedValue: String

    func run() async {
      while !Task.isCancelled {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
      }
    }

    func provideInfo() {
      print("\(seedValue)")
      Self.exit()
    }
  }
}

extension InfoProvidingTests {
  static let seedValue = "c6466b3a7881998f6bef30616fcd1769"

  #if compiler(>=6.2)
  @Test func siginfoHandled() async throws {
    #if os(macOS) || os(FreeBSD) || os(OpenBSD) || os(Linux) || os(Android) || os(Windows)
    let results = try await #require(
      processExitsWith: .success,
      observing: [\.standardOutputContent]
    ) {
      #if os(Linux) || os(Android)
      // The default signal handler for SIGUSR1 aborts, and we are in a race to
      // raise SIGUSR1 after the real signal handler has been set up, so ensure
      // we're ignoring it instead until that happens.
      signal(SIGUSR1, SIG_IGN)
      #elseif os(Windows)
      // As with Linux, Windows generates SIGBREAK by default.
      SetConsoleCtrlHandler({ WindowsBool($0 == CTRL_BREAK_EVENT) }, true)
      #endif

      try await withThrowingDiscardingTaskGroup { taskGroup in
        taskGroup.addTask {
          await SeedCommand.main([Self.seedValue])
        }
        taskGroup.addTask {
          // The main function is running asynchronously in another task, so we
          // can't really predict when it will have set up the signal handler
          // without plumbing through an invasive hook/callback. Instead, just
          // spam ourselves with the signal.
          while !Task.isCancelled {
            #if os(macOS) || os(FreeBSD) || os(OpenBSD)
            raise(SIGINFO)
            #elseif os(Linux) || os(Android)
            kill(getpid(), SIGUSR1)  // ignore-unacceptable-language
            #elseif os(Windows)
            GenerateConsoleCtrlEvent(DWORD(CTRL_BREAK_EVENT), 0)
            #endif
            await Task.yield()
          }
        }
      }
    }

    #expect(results.standardOutputContent.contains(Self.seedValue.utf8))
    #else
    try Test.cancel("Exit tests are unsupported on this platform")
    #endif
  }
  #endif
}
