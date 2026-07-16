//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020-2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import Testing

@testable import ArgumentParser

@Suite struct StringEditDistanceTests {
  @Test func stringEditDistance() {
    #expect("".editDistance(to: "") == 0)
    #expect("".editDistance(to: "foo") == 3)
    #expect("foo".editDistance(to: "") == 3)
    #expect("foo".editDistance(to: "bar") == 3)
    #expect("bar".editDistance(to: "foo") == 3)
    #expect("bar".editDistance(to: "baz") == 1)
    #expect("baz".editDistance(to: "bar") == 1)
    #expect("friend".editDistance(to: "fresh") == 3)
    #expect("friend".editDistance(to: "friend") == 0)
    #expect("friend".editDistance(to: "fried") == 1)
    #expect("friend".editDistance(to: "friendly") == 2)
    #expect("friendly".editDistance(to: "friend") == 2)
  }
}
