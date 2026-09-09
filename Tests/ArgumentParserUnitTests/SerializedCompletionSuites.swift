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

/// A parent suite for completion-related test suites.
///
/// This suite must serialize their execution against each other. Both
/// `CompletionScriptTests` and `DefaultAsFlagCompletionTests` invoke
/// `CompletionsGenerator`, which mutates the process-global
/// `CompletionShell._requesting` mutex during script generation. Swift
/// Testing's `.serialized` trait only prevents parallelism within a single
/// suite; nesting both suites under a `.serialized` parent extends the
/// guarantee across the two nested suites (and any tests they contain).
@Suite(
  .serialized
)
enum SerializedCompletionSuites {}
