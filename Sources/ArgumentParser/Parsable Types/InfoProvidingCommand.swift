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

/// A parsable command that can provide information back to the user while it
/// runs.
///
/// The user may request information from a running process via a
/// platform-specific mechanism:
///
/// - On Apple platforms, FreeBSD, and OpenBSD, by sending `SIGINFO` to the
///   process or by pressing Ctrl+T in the Terminal application.
/// - On Linux, by sending the `SIGUSR1` signal to the process.
/// - On Windows, by pressing Ctrl+Break in the Terminal application.
///
/// If your root command conforms to this protocol, Swift Argument Parser
/// automatically sets up a signal handler to listen for `SIGINFO` (or the
/// platform-specific equivalent).
///
/// On platforms that do not support providing information, conformance to this
/// protocol has no effect.
@available(macOS 10.15, macCatalyst 13, iOS 13, tvOS 13, watchOS 6, *)
public protocol InfoProvidingParsableCommand: Sendable, ParsableCommand {
  #if compiler(>=6.2)
  /// Provide information about the state of the process and about the
  /// currently-running command.
  ///
  /// The information you provide is program-specific. Programs will often
  /// provide a status update such as the percentage or count of work completed,
  /// information about the currently-running work item, etc.
  ///
  /// - Important: Swift Argument Parser calls this function asynchronously
  ///   while your program is running. If your command type is actor-isolated,
  ///   ensure your ``AsyncParsableCommand/run()`` implementation periodically
  ///   yields control by suspending, sleeping, or calling [`Task.yield()`](https://developer.apple.com/documentation/swift/task/yield()).
  ///
  ///   If ``AsyncParsableCommand/run()`` never yields, the Swift runtime may
  ///   not be able to schedule calls to this function and it will appear to the
  ///   user as if it is not implemented.
  nonisolated(nonsending) func provideInfo() async
  #else
  func provideInfo() async
  #endif
}

// MARK: -

@available(macOS 10.15, macCatalyst 13, iOS 13, tvOS 13, watchOS 6, *)
extension SIGINFOHandler {
  convenience init<T>(for command: T) where T: InfoProvidingParsableCommand {
    self.init {
      guard #available(macOS 26, iOS 26, watchOS 26, tvOS 26, visionOS 26, *)
      else {
        _ = Task.detached {
          await command.provideInfo()
        }
        return
      }
      #if compiler(>=6.3)
      _ = Task.immediateDetached {
        await command.provideInfo()
      }
      #endif
    }
  }
}
