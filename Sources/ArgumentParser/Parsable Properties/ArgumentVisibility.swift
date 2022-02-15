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

/// Visibility level of an argument's help.
public enum ArgumentVisibility {
    /// Show help for this argument whenever appropriate.
    case `default`

    /// Only show help for this argument in the extended help screen.
    case hidden

    /// Never show help for this argument.
    case `private`
}

extension ArgumentVisibility {
  /// A raw Integer value that represents each visibility level.
  ///
  /// `_comparableLevel` can be used to test if a Visibility case is more or
  /// less visible than another, without committing this behavior to API.
  /// A lower `_comparableLevel` indicates that the case is less visible (more
  /// secret).
  private var _comparableLevel: Int {
    switch self {
    case .default:
      return 2
    case .hidden:
      return 1
    case .private:
      return 0
    }
  }

  /// - Returns: true if `self` is at least as visible as the supplied argument.
  func isAtLeastAsVisible(as other: Self) -> Bool {
    self._comparableLevel >= other._comparableLevel
  }
}
