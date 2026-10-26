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

@testable import ArgumentParser

@Suite
struct StringTrimmedTests {
  @Test(
    arguments: [
      ("", ""),
      ("hello", "hello"),
      ("  hello", "hello"),
      ("hello  ", "hello"),
      ("  hello  ", "hello"),
      ("\thello\t", "hello"),
      ("\nhello\n", "hello"),
      ("\r\n hello \r\n", "hello"),
      (" \t\n hello \n\t ", "hello"),
      ("   ", ""),
      ("\t\n\r ", ""),
      ("  hello world  ", "hello world"),
      ("  a  b  ", "a  b"),
      ("hello world", "hello world"),
    ] as [(String, String)]
  )
  func trimmed(input: String, expected: String) {
    #expect(input.trimmed() == expected)
  }
}
