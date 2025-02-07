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

import Foundation

/// A synchronization primitive that protects shared mutable state via mutual
/// exclusion.
///
/// The `Mutex` type offers non-recursive exclusive access to the state it is
/// protecting by blocking threads attempting to acquire the lock. Only one
/// execution context at a time has access to the value stored within the
/// `Mutex` allowing for exclusive access.
class Mutex<T>: @unchecked Sendable {
  /// The lock used to synchronize access to the value.
  var lock: NSLock
  /// The value protected by the mutex.
  var value: T

  /// Initializes a new `Mutex` with the provided value.
  ///
  /// - Parameter value: The initial value to be protected by the mutex.
  init(_ value: T) {
    self.lock = .init()
    self.value = value
  }

  /// Calls the given closure after acquiring the lock and then releases
  /// ownership.
  ///
  /// - Warning: Recursive calls to `withLock` within the closure parameter has
  ///   behavior that is platform dependent. Some platforms may choose to panic
  ///   the process, deadlock, or leave this behavior unspecified. This will
  ///   never reacquire the lock however.
  ///
  /// - Parameter body: A closure with a parameter of `Value` that has exclusive
  ///   access to the value being stored within this mutex. This closure is
  ///   considered the critical section as it will only be executed once the
  ///   calling thread has acquired the lock.
  ///
  /// - Throws: Re-throws any error thrown by `body`.
  ///
  /// - Returns: The return value, if any, of the `body` closure parameter.
  func withLock<U>(
    _ body: (inout T) throws -> U
  ) rethrows -> U {
    self.lock.lock()
    defer { self.lock.unlock() }
    return try body(&self.value)
  }
}
