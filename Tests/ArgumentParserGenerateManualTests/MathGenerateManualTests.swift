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
import ArgumentParser
import ArgumentParserTestHelpers

final class MathGenerateManualTests: XCTestCase {
  func testMath_SinglePageManual() throws {
    try AssertGenerateManual(multiPage: false, command: "math", expected: #"""
      .\" "Generated by swift-argument-parser"
      .Dd May 12, 1996
      .Dt MATH 9
      .Os
      .Sh NAME
      .Nm math
      .Nd "A utility for performing maths."
      .Sh SYNOPSIS
      .Nm
      .Ar subcommand
      .Op Fl -version
      .Op Fl -help
      .Sh DESCRIPTION
      .Bl -tag -width 6n
      .It Fl -version
      Show the version.
      .It Fl h , -help
      Show help information.
      .It Em add
      .Bl -tag -width 6n
      .It Fl x , -hex-output
      Use hexadecimal notation for the result.
      .It Ar values...
      A group of integers to operate on.
      .It Fl -version
      Show the version.
      .It Fl h , -help
      Show help information.
      .El
      .It Em multiply
      .Bl -tag -width 6n
      .It Fl x , -hex-output
      Use hexadecimal notation for the result.
      .It Ar values...
      A group of integers to operate on.
      .It Fl -version
      Show the version.
      .It Fl h , -help
      Show help information.
      .El
      .It Em stats
      .Bl -tag -width 6n
      .It Fl -version
      Show the version.
      .It Fl h , -help
      Show help information.
      .It Em average
      .Bl -tag -width 6n
      .It Fl -kind Ar kind
      The kind of average to provide.
      .It Ar values...
      A group of floating-point values to operate on.
      .It Fl -version
      Show the version.
      .It Fl h , -help
      Show help information.
      .El
      .It Em stdev
      .Bl -tag -width 6n
      .It Ar values...
      A group of floating-point values to operate on.
      .It Fl -version
      Show the version.
      .It Fl h , -help
      Show help information.
      .El
      .It Em quantiles
      .Bl -tag -width 6n
      .It Ar one-of-four
      .It Ar custom-arg
      .It Ar values...
      A group of floating-point values to operate on.
      .It Fl -test-success-exit-code
      .It Fl -test-failure-exit-code
      .It Fl -test-validation-exit-code
      .It Fl -test-custom-exit-code Ar test-custom-exit-code
      .It Fl -file Ar file
      .It Fl -directory Ar directory
      .It Fl -shell Ar shell
      .It Fl -custom Ar custom
      .It Fl -version
      Show the version.
      .It Fl h , -help
      Show help information.
      .El
      .El
      .El
      .Sh AUTHORS
      The
      .Nm
      reference was written by
      .An -nosplit
      .An "Jane Appleseed" ,
      .Mt johnappleseed@apple.com ,
      and
      .An -nosplit
      .An "The Appleseeds"
      .Ao
      .Mt appleseeds@apple.com
      .Ac .
      """#)
  }

  func testMath_MultiPageManual() throws {
    try AssertGenerateManual(multiPage: true, command: "math", expected: #"""
      .\" "Generated by swift-argument-parser"
      .Dd May 12, 1996
      .Dt MATH 9
      .Os
      .Sh NAME
      .Nm math
      .Nd "A utility for performing maths."
      .Sh SYNOPSIS
      .Nm
      .Ar subcommand
      .Op Fl -version
      .Op Fl -help
      .Sh DESCRIPTION
      .Bl -tag -width 6n
      .It Fl -version
      Show the version.
      .It Fl h , -help
      Show help information.
      .El
      .Sh "SEE ALSO"
      .Xr math.add 9 ,
      .Xr math.multiply 9 ,
      .Xr math.stats 9
      .Sh AUTHORS
      The
      .Nm
      reference was written by
      .An -nosplit
      .An "Jane Appleseed" ,
      .Mt johnappleseed@apple.com ,
      and
      .An -nosplit
      .An "The Appleseeds"
      .Ao
      .Mt appleseeds@apple.com
      .Ac .
      .\" "Generated by swift-argument-parser"
      .Dd May 12, 1996
      .Dt MATH.ADD 9
      .Os
      .Sh NAME
      .Nm "math add"
      .Nd "Print the sum of the values."
      .Sh SYNOPSIS
      .Nm
      .Op Fl -hex-output
      .Op Ar values...
      .Op Fl -version
      .Op Fl -help
      .Sh DESCRIPTION
      .Bl -tag -width 6n
      .It Fl x , -hex-output
      Use hexadecimal notation for the result.
      .It Ar values...
      A group of integers to operate on.
      .It Fl -version
      Show the version.
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
      and
      .An -nosplit
      .An "The Appleseeds"
      .Ao
      .Mt appleseeds@apple.com
      .Ac .
      .\" "Generated by swift-argument-parser"
      .Dd May 12, 1996
      .Dt MATH.MULTIPLY 9
      .Os
      .Sh NAME
      .Nm "math multiply"
      .Nd "Print the product of the values."
      .Sh SYNOPSIS
      .Nm
      .Op Fl -hex-output
      .Op Ar values...
      .Op Fl -version
      .Op Fl -help
      .Sh DESCRIPTION
      .Bl -tag -width 6n
      .It Fl x , -hex-output
      Use hexadecimal notation for the result.
      .It Ar values...
      A group of integers to operate on.
      .It Fl -version
      Show the version.
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
      and
      .An -nosplit
      .An "The Appleseeds"
      .Ao
      .Mt appleseeds@apple.com
      .Ac .
      .\" "Generated by swift-argument-parser"
      .Dd May 12, 1996
      .Dt MATH.STATS 9
      .Os
      .Sh NAME
      .Nm "math stats"
      .Nd "Calculate descriptive statistics."
      .Sh SYNOPSIS
      .Nm
      .Ar subcommand
      .Op Fl -version
      .Op Fl -help
      .Sh DESCRIPTION
      .Bl -tag -width 6n
      .It Fl -version
      Show the version.
      .It Fl h , -help
      Show help information.
      .El
      .Sh "SEE ALSO"
      .Xr math.stats.average 9 ,
      .Xr math.stats.quantiles 9 ,
      .Xr math.stats.stdev 9
      .Sh AUTHORS
      The
      .Nm
      reference was written by
      .An -nosplit
      .An "Jane Appleseed" ,
      .Mt johnappleseed@apple.com ,
      and
      .An -nosplit
      .An "The Appleseeds"
      .Ao
      .Mt appleseeds@apple.com
      .Ac .
      .\" "Generated by swift-argument-parser"
      .Dd May 12, 1996
      .Dt MATH.STATS.AVERAGE 9
      .Os
      .Sh NAME
      .Nm "math stats average"
      .Nd "Print the average of the values."
      .Sh SYNOPSIS
      .Nm
      .Op Fl -kind Ar kind
      .Op Ar values...
      .Op Fl -version
      .Op Fl -help
      .Sh DESCRIPTION
      .Bl -tag -width 6n
      .It Fl -kind Ar kind
      The kind of average to provide.
      .It Ar values...
      A group of floating-point values to operate on.
      .It Fl -version
      Show the version.
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
      and
      .An -nosplit
      .An "The Appleseeds"
      .Ao
      .Mt appleseeds@apple.com
      .Ac .
      .\" "Generated by swift-argument-parser"
      .Dd May 12, 1996
      .Dt MATH.STATS.STDEV 9
      .Os
      .Sh NAME
      .Nm "math stats stdev"
      .Nd "Print the standard deviation of the values."
      .Sh SYNOPSIS
      .Nm
      .Op Ar values...
      .Op Fl -version
      .Op Fl -help
      .Sh DESCRIPTION
      .Bl -tag -width 6n
      .It Ar values...
      A group of floating-point values to operate on.
      .It Fl -version
      Show the version.
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
      and
      .An -nosplit
      .An "The Appleseeds"
      .Ao
      .Mt appleseeds@apple.com
      .Ac .
      .\" "Generated by swift-argument-parser"
      .Dd May 12, 1996
      .Dt MATH.STATS.QUANTILES 9
      .Os
      .Sh NAME
      .Nm "math stats quantiles"
      .Nd "Print the quantiles of the values (TBD)."
      .Sh SYNOPSIS
      .Nm
      .Op Ar one-of-four
      .Op Ar custom-arg
      .Op Ar values...
      .Op Fl -test-success-exit-code
      .Op Fl -test-failure-exit-code
      .Op Fl -test-validation-exit-code
      .Op Fl -test-custom-exit-code Ar test-custom-exit-code
      .Op Fl -file Ar file
      .Op Fl -directory Ar directory
      .Op Fl -shell Ar shell
      .Op Fl -custom Ar custom
      .Op Fl -version
      .Op Fl -help
      .Sh DESCRIPTION
      .Bl -tag -width 6n
      .It Ar one-of-four
      .It Ar custom-arg
      .It Ar values...
      A group of floating-point values to operate on.
      .It Fl -test-success-exit-code
      .It Fl -test-failure-exit-code
      .It Fl -test-validation-exit-code
      .It Fl -test-custom-exit-code Ar test-custom-exit-code
      .It Fl -file Ar file
      .It Fl -directory Ar directory
      .It Fl -shell Ar shell
      .It Fl -custom Ar custom
      .It Fl -version
      Show the version.
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
      and
      .An -nosplit
      .An "The Appleseeds"
      .Ao
      .Mt appleseeds@apple.com
      .Ac .
      """#)
  }
}
