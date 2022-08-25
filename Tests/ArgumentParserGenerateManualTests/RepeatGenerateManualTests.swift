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

final class RepeatGenerateManualTests: XCTestCase {
  func testMath_SinglePageManual() throws {
    try AssertGenerateManual(singlePage: true, command: "repeat", expected: #"""
      .\" "Generated by swift-argument-parser"
      .Dd May 12, 1996
      .Dt REPEAT 9
      .Os
      .Sh NAME
      .Nm repeat
      .Sh SYNOPSIS
      .Nm
      .Op Fl -count Ar count
      .Op Fl -include-counter
      .Ar phrase
      .Op Fl -help
      .Sh DESCRIPTION
      .Bl -tag -width 6n
      .It Fl -count Ar count
      The number of times to repeat 'phrase'.
      .It Fl -include-counter
      Include a counter with each repetition.
      .It Ar phrase
      The phrase to repeat.
      .It Fl h , -help
      Show help information.
      .El
      .Sh AUTHORS
      The
      .Nm
      reference was written by
      .An -nosplit
      .An "Jane Appleseed" ,
      .Mt johnappleseed@apple.com ,
      .An -nosplit
      .An "The Appleseeds"
      .Ao
      .Mt appleseeds@apple.com
      .Ac .
      """#)
  }

  func testMath_MultiPageManual() throws {
    try AssertGenerateManual(singlePage: false, command: "repeat", expected: #"""
      .\" "Generated by swift-argument-parser"
      .Dd May 12, 1996
      .Dt REPEAT 9
      .Os
      .Sh NAME
      .Nm repeat
      .Sh SYNOPSIS
      .Nm
      .Op Fl -count Ar count
      .Op Fl -include-counter
      .Ar phrase
      .Op Fl -help
      .Sh DESCRIPTION
      .Bl -tag -width 6n
      .It Fl -count Ar count
      The number of times to repeat 'phrase'.
      .It Fl -include-counter
      Include a counter with each repetition.
      .It Ar phrase
      The phrase to repeat.
      .It Fl h , -help
      Show help information.
      .El
      .Sh AUTHORS
      The
      .Nm
      reference was written by
      .An -nosplit
      .An "Jane Appleseed" ,
      .Mt johnappleseed@apple.com ,
      .An -nosplit
      .An "The Appleseeds"
      .Ao
      .Mt appleseeds@apple.com
      .Ac .
      """#)
  }
}
