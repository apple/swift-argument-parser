//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import Testing

@testable import ArgumentParser
@Suite
struct InputOriginTests{

  @Test(
    arguments: [
      (
        elements: [
          InputOrigin.Element.defaultValue,
        ],
        expectedValue: true
      ),
      (
        elements: [
        ],
        expectedValue: false
      ),
      (
        elements: [
          .argumentIndex(SplitArguments.Index(inputIndex: 1))
        ],
        expectedValue: false
      ),
      (
        elements: [
          .defaultValue,
          .argumentIndex(SplitArguments.Index(inputIndex: 1))
        ],
        expectedValue: false
      )
    ]
  ) func isDefaultValue(elements: [InputOrigin.Element], expectedValue: Bool) {
      let inputOrigin = InputOrigin(elements: elements)

      #expect(
        inputOrigin.isDefaultValue == expectedValue,
        "Actual is not as expected"
      )
  }
}
