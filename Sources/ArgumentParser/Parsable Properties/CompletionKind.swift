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

/// The type of completion to use for an argument or option.
public enum CompletionKind {
  /// Use the default completion kind for the value's type.
  case `default`

  /// Use the specified list of completion strings.
  case list([String])

  /// Complete file names that match the specified pattern.
  case file(pattern: String?)

  /// Complete directory names that match the specified pattern.
  case directory(pattern: String?)

  /// Call the given shell command to generate completions.
  case shellCommand(String)

  /// Generate completions using the given closure.
  case custom(([String]) -> [String])

  /// Complete file names.
  public static var file: CompletionKind { .file(pattern: nil) }

  /// Complete directory names.
  public static var directory: CompletionKind { .directory(pattern: nil) }
}
