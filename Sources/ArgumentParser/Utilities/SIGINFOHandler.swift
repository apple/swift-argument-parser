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

#if canImport(Dispatch)
private import Dispatch
#endif

#if canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#elseif canImport(Darwin)
import Darwin
#elseif canImport(WinSDK)
import WinSDK
#elseif canImport(WASILibc)
import WASILibc
#elseif canImport(Android)
import Android
#endif

/// A class whose instances represent `SIGINFO` handlers configured in this
/// process.
///
/// - Note: This class is responsible for handling `SIGINFO`, `SIGUSR1` (Linux),
///   and Ctrl+Break (Windows). Naming is hard.
final class SIGINFOHandler: Sendable {
  /// The set of `SIGINFO` handlers configured in this process.
  ///
  /// Generally, this array will contain no more than `1` element, but it can be
  /// larger if multiple commands are made to run in a single process.
  private static let allSIGINFOHandlers = Mutex<[SIGINFOHandler]>([])

  #if canImport(Dispatch)
  /// The queue on which SIGINFO handler callbacks are invoked.
  ///
  /// Perhaps the natural queue for signal handling is the main queue, but we do
  /// not control user code and we cannot ensure that it doesn't block the main
  /// queue/thread/actor for long periods of time, which would prevent our
  /// dispatch source from ever firing its event handler.
  private static let siginfoQueue = DispatchQueue(
    label: "SIGINFO monitoring queue",
    qos: .userInitiated,
    autoreleaseFrequency: .workItem)

  /// The dispatch source that listens for `SIGINFO` (or the platform-specific
  /// equivalent).
  ///
  /// This declaration is annotated `nonisolated(unsafe)` because dispatch sources
  /// do not conform to `Sendable` on non-Darwin targets.
  private nonisolated(unsafe) static let siginfoSource: Any = {
    #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS) || os(visionOS) || os(FreeBSD) || os(OpenBSD)
    let source = DispatchSource.makeSignalSource(
      signal: SIGINFO, queue: siginfoQueue)
    #elseif os(Linux) || os(Android)
    // On Linux, SIGINFO is not defined, so we'll use SIGUSR1 for this purpose.
    let source = DispatchSource.makeSignalSource(
      signal: SIGUSR1, queue: siginfoQueue)
    #elseif os(Windows)
    let source = DispatchSource.makeUserDataAddSource(queue: siginfoQueue)
    SetConsoleCtrlHandler(
      { ctrlType in
        guard ctrlType == CTRL_BREAK_EVENT else {
          // Let the system handle it normally.
          return false
        }
        if let siginfoSource = siginfoSource as? any DispatchSourceUserDataAdd {
          siginfoSource.add(data: 1)
        }
        return true
      }, true)
    #else
    // This platform does not support SIGINFO or any equivalent. To keep this
    // code relatively simple, we still create a no-op dispatch source.
    let source = DispatchSource.makeUserDataAddSource(queue: siginfoQueue)
    #endif

    source.setEventHandler {
      // Invoke all registered handler objects.
      let handlers = allSIGINFOHandlers.withLock { $0 }
      for handler in handlers {
        handler.handler()
      }
    }
    source.activate()
    return source
  }()
  #endif

  /// The handler function this instance represents.
  private let handler: @Sendable () -> Void

  init(handlingWith handler: @escaping @Sendable () -> Void) {
    self.handler = handler
  }

  /// Register this handler and start using it to listen for signals.
  func register() {
    Self.allSIGINFOHandlers.withLock { all in
      all.append(self)
    }

    #if canImport(Dispatch)
    // Ensure we're listening for signals after adding this handler.
    _ = Self.siginfoSource
    #endif
  }

  /// Unregister this handler and stop using it to listen for signals.
  func unregister() {
    Self.allSIGINFOHandlers.withLock { all in
      all.removeAll { $0 === self }
    }
  }
}
