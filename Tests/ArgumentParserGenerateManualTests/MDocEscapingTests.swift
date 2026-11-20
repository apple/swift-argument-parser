//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import Testing

@testable import generate_manual

@Suite struct MDocEscapingTests {
  @Test func textLineStartingWithDotOrApostrophe() {
    #expect(".swift files".serialized() == #"\&.swift files"#)
    #expect("'*' matches".serialized() == #"\&'*' matches"#)
    #expect("a.b 'c'".serialized() == "a.b 'c'")
  }

  @Test func multiLineTextStartingWithDotOrApostrophe() {
    // Each line of a multi-line string is a separate text input line, so a
    // leading dot or apostrophe on any line would be read as a macro line.
    #expect(
      "Inputs:\n.swift files\n'*' matches".serialized()
        == "Inputs:\n\\&.swift files\n\\&'*' matches")
    #expect(
      "Inputs:\n  .swift files\nend.".serialized()
        == "Inputs:\n  .swift files\nend.")
  }
}
