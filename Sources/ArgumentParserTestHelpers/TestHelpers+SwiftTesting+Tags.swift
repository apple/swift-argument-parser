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

import Testing

/// A Swift Testing trait that disables a test on platforms where launching a
/// subprocess via `Foundation.Process` is not supported.
///
/// Apply with `@Test(.requiresProcessExecution)` to tests whose bodies
/// (transitively) call `requireExecuteCommand`, `expectDumpHelp(command:)`,
/// `expectGenerateManual`, or `expectGeneratedReference` *and* also compare
/// the output against a fixed expectation (e.g. via `expectSnapshot`). On
/// unsupported platforms these helpers return an empty string rather than
/// throwing, so a downstream snapshot comparison would fail spuriously; the
/// trait suppresses the test entirely instead.
extension Trait where Self == Testing.ConditionTrait {
  public static var requiresProcessExecution: Self {
    #if os(Windows) || (canImport(Darwin) && !os(macOS))
    return .disabled(
      "Process execution is not supported on this platform.")
    #else
    return .enabled(if: true)
    #endif
  }
}
