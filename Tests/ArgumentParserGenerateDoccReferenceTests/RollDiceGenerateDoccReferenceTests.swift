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

import XCTest
import ArgumentParserTestHelpers

final class RollDiceGenerateDoccReferenceTests: XCTestCase {
  func testRollDice() throws {
    try AssertGenerateDoccReference(command: "roll", expected: #"""
      <!-- Generated by swift-argument-parser -->
      
      # roll

      ```
      roll [--times=<n>] [--sides=<m>] [--seed=<seed>] [--verbose] [--help]
      ```

      **--times=\<n\>:**

      *Rolls the dice <n> times.*


      **--sides=\<m\>:**

      *Rolls an <m>-sided dice.*

      Use this option to override the default value of a six-sided die.


      **--seed=\<seed\>:**

      *A seed to use for repeatable random generation.*


      **--verbose:**

      *Show all roll results.*


      **--help:**

      *Show help information.*
      """#)
  }
}
