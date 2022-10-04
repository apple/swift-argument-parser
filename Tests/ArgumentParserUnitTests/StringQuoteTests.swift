//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import XCTest
@testable import ArgumentParser

final class StringQuoteTests: XCTestCase {}

extension StringQuoteTests {
  func testStringQuoteWithCharacter() {
    let charactersToQuote = CharacterSet.whitespaces.union(.symbols)
    let quoteTests = [
      ("noSpace", "noSpace"),
      ("a space", "'a space'"),
      (" startingSpace", "' startingSpace'"),
      ("endingSpace ", "'endingSpace '"),
      ("   ", "'   '"),
      ("\t", "'\t'"),
      ("with'quote", "with'quote"), // no need to quote, so don't escape quote character either
      ("with'quote and space", "'with\\'quote and space'"), // quote the string and escape the quote character within
      ("'\\\\'' '''", "'\\\'\\\\\\\'\\\' \\\'\\\'\\\''"),
      ("\"\\\\\"\" \"\"\"", "'\"\\\\\"\" \"\"\"'"),
      ("word+symbol", "'word+symbol'"),
      ("@£$%'^*(", "'@£$%\\\'^*('")
    ]
    for test in quoteTests {
      XCTAssertEqual(test.0.quotedIfContains(charactersToQuote), test.1)
    }
  }
}
