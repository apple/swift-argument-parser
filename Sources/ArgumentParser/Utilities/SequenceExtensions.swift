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

extension Sequence where Element: Hashable {
  /// Returns an array with only the unique elements of this sequence, in the
  /// order of the first occurence of each unique element.
  func uniquified() -> [Element] {
    var seen: Set<Element> = []
    var result: [Element] = []
    for element in self {
      if seen.insert(element).inserted {
        result.append(element)
      }
    }
    return result
  }
}
