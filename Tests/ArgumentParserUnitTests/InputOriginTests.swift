//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2021-2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import Testing

@testable import ArgumentParser

@Suite struct InputOriginTests {}

extension InputOriginTests {

  struct IsDefaultTestData: CustomTestStringConvertible, @unchecked Sendable {
    let id: String
    let elements: [InputOrigin.Element]
    let expectedIsDefaultValue: Bool
    var testDescription: String { id }
  }
  @Test(
    arguments: [
      IsDefaultTestData(
        id: "empty elements",
        elements: [],
        expectedIsDefaultValue: false),
      IsDefaultTestData(
        id: "single default value",
        elements: [
          .defaultValue
        ],
        expectedIsDefaultValue: true),
      IsDefaultTestData(
        id: "single argument index",
        elements: [
          .argumentIndex(SplitArguments.Index(inputIndex: 1))
        ],
        expectedIsDefaultValue: false
      ),
      IsDefaultTestData(
        id: "default value with argument index",
        elements: [
          .defaultValue,
          .argumentIndex(SplitArguments.Index(inputIndex: 1)),
        ],
        expectedIsDefaultValue: false
      ),
    ]
  )
  func isDefaultValue(tcData: IsDefaultTestData) {
    let inputOrigin = InputOrigin(elements: tcData.elements)
    #expect(inputOrigin.isDefaultValue == tcData.expectedIsDefaultValue)
  }
}
