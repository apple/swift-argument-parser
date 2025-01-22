//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import ArgumentParserToolInfo

struct DiscussionText: MDocComponent {
  var discussion: Discussion

  var body: MDocComponent {
    if case let .staticText(text) = discussion {
      text
    } else if case let .enumerated(preamble, values) = discussion {
      if let preamble {
        preamble
      }
      List {
        for value in values {
          MDocMacro.ListItem(title: value.value)
          value.description
        }
      }
    }
  }
}
