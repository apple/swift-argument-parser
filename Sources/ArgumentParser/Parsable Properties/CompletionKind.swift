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

public enum CompletionKind {
  case `default`
  case file(pattern: String?)
  case directory(pattern: String?)
  case list([String])
  case custom((String) -> [String])
  
  public static var file: CompletionKind { .file(pattern: nil) }
  public static var directory: CompletionKind { .directory(pattern: nil) }
}
