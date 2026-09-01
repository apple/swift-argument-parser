//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import ArgumentParser
import Foundation

@MainActor
final class Info {
  let start = Date()
  var signalCount = 0
}

let info = Info()

@main
@available(macOS 10.15, macCatalyst 13, iOS 13, tvOS 13, watchOS 6, *)
struct InfoProvider: AsyncParsableCommand, InfoProvidingParsableCommand {
  func run() async throws {
    _ = info

    #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS) || os(visionOS) || os(FreeBSD) || os(OpenBSD)
    print("Press Ctrl+T to see process information.")
    #elseif os(Linux) || os(Android)
    print("Send SIGUSR1 to \(getpid()) to see process information.")
    #elseif os(Windows)
    print("Press Ctrl+Break to see process information.")
    #endif

    let dot = [UInt8(ascii: ".")]
    while true {
      try await Task.sleep(nanoseconds: 1_000_000_000)
      if #available(macOS 10.15.4, iOS 13.4, watchOS 6.2, tvOS 13.4, *) {
        try? FileHandle.standardOutput.write(contentsOf: dot)
      } else {
        FileHandle.standardOutput.write(Data(dot))
      }
    }
  }

  @MainActor
  func provideInfo() {
    let timeRunning = Date().timeIntervalSince(info.start)
    print("Running for \(timeRunning) seconds.")

    info.signalCount += 1
    #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS) || os(visionOS) || os(FreeBSD) || os(OpenBSD)
    print("SIGINFO received \(info.signalCount) time(s)!")
    #elseif os(Linux) || os(Android)
    print("SIGUSR1 received \(info.signalCount) time(s)!")
    #elseif os(Windows)
    print("Ctrl+Break received \(info.signalCount) time(s)!")
    #endif
  }
}
