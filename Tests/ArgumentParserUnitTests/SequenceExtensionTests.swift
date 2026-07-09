//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020-2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import Testing

@testable import ArgumentParser

@Suite struct SequenceExtensionTests {

  @Test func testUniquing() {
    #expect([] == (0..<0).uniquing())
    #expect([0, 1, 2, 3, 4] == (0..<5).uniquing())
    #expect([0, 1, 2, 3, 4] == [0, 1, 2, 3, 4, 0, 1, 2, 3, 4].uniquing())
    #expect([0, 1, 2, 3, 4] == [0, 1, 2, 3, 4, 4, 3, 2, 1, 0].uniquing())
  }

  @Test func testUniquingAdjacentElements() {
    #expect([] == (0..<0).uniquingAdjacentElements())
    #expect([0, 1, 2, 3, 4] == (0..<5).uniquingAdjacentElements())
    #expect(
      [0, 1, 2, 3, 4]
        == [0, 0, 1, 1, 1, 1, 2, 3, 3, 3, 4, 4].uniquingAdjacentElements())
    #expect(
      [0, 1, 2, 3, 4, 3, 2, 1, 0]
        == [0, 1, 2, 3, 4, 4, 3, 2, 1, 0].uniquingAdjacentElements())
  }
}
