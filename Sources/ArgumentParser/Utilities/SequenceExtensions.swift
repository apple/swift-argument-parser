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

extension Sequence where Iterator.Element: Hashable {
  func uniquified() -> [Iterator.Element] {
    var seen: [Iterator.Element: Bool] = [:]
    return self.filter { seen.updateValue(true, forKey: $0) == nil }
  }
}
