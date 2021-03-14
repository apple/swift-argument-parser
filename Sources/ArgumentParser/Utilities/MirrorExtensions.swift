//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

extension Mirror {
  /// Returns the "real" value of a `Mirror.Child` as `Any?`.
  ///
  /// The `value` of `Mirror.Child` is defined as `Any` but this is confusing because the value
  /// could be `Optional<Any>` which is not equal to `nil` even when the `Optional` case is `.none`.
  ///
  /// The purpose of this function is to disambiguate when the `value` of a `Mirror.Child` is actaully nil.
  static func realValue(for child: Mirror.Child) -> Any? {
    if case Optional<Any>.none = child.value {
      return nil
    } else {
      return child.value
    }
  }
}
