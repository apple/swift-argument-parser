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

struct OriginalInput {
  var arguments: [String]
  var environment: [EnvironmentName: String]
}

extension OriginalInput {
  init(arguments: [String]?, environment: [String: String]?) {
    self.arguments = arguments ?? Array(CommandLine.arguments.dropFirst())
    let env = environment ?? ProcessInfo.processInfo.environment
    self.environment = Dictionary(uniqueKeysWithValues: env.map {
      (EnvironmentName(rawValue: $0), $1)
    })
  }
}

extension OriginalInput {
  subscript(_ origin: InputOrigin) -> String {
    return origin.elements.map { self[$0] }.joined(separator: " ")
  }

  subscript(_ origin: InputOrigin.Element) -> String {
    switch origin {
    case .argumentIndex(let index):
      return self[index]
    case .environment(let name):
      return environment[name] ?? "<empty>"
    }
  }

  /// Returns the original input string at the given origin, or `nil` if
  /// `origin` is a sub-index.
  subscript(completeIndex origin: InputOrigin.Element) -> String? {
    switch origin {
    case .argumentIndex(let index):
      guard case .complete = index.subIndex else { return nil }
      return self[index]
    case .environment(let name):
      return environment[name] ?? "<empty>"
    }
  }

  subscript(_ index: SplitArguments.Index) -> String {
    return arguments[index.inputIndex.rawValue]
  }
}
