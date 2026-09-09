//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import Testing

@testable import ArgumentParser

let shortSample = """
  Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Lectus proin nibh nisl condimentum id. Semper feugiat nibh sed pulvinar proin gravida hendrerit. Massa id neque aliquam vestibulum morbi blandit cursus risus at. Iaculis urna id volutpat lacus laoreet. Netus et malesuada fames ac turpis egestas sed tempus urna.
  """

let longSample = """
  Pretium vulputate sapien nec sagittis aliquam malesuada bibendum. Ut diam quam nulla porttitor.

  Egestas egestas fringilla phasellus faucibus. Amet dictum sit amet justo donec enim diam. Consectetur adipiscing elit duis tristique.

  Enim lobortis scelerisque fermentum dui.

  Et leo duis ut diam quam.

  Integer eget aliquet nibh praesent tristique magna sit. Faucibus turpis in eu mi bibendum neque egestas congue quisque.       Risus nec feugiat in fermentum posuere urna nec tincidunt.
  """

let jsonSample = """
  {
    "level1": {
      "level2": {
        "level3": true
      }
    }
  }
  """

// MARK: -

@Suite struct StringWrappingTests {
  @Test func short() {
    #expect(
      shortSample.wrapped(to: 40) == """
        Lorem ipsum dolor sit amet, consectetur
        adipiscing elit, sed do eiusmod tempor
        incididunt ut labore et dolore magna
        aliqua. Lectus proin nibh nisl
        condimentum id. Semper feugiat nibh sed
        pulvinar proin gravida hendrerit. Massa
        id neque aliquam vestibulum morbi
        blandit cursus risus at. Iaculis urna
        id volutpat lacus laoreet. Netus et
        malesuada fames ac turpis egestas sed
        tempus urna.
        """)

    #expect(
      shortSample.wrapped(to: 80) == """
        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor
        incididunt ut labore et dolore magna aliqua. Lectus proin nibh nisl condimentum
        id. Semper feugiat nibh sed pulvinar proin gravida hendrerit. Massa id neque
        aliquam vestibulum morbi blandit cursus risus at. Iaculis urna id volutpat
        lacus laoreet. Netus et malesuada fames ac turpis egestas sed tempus urna.
        """)
  }

  @Test func shortWithIndent() {
    #expect(
      shortSample.wrapped(to: 60, wrappingIndent: 10) == """
                  Lorem ipsum dolor sit amet, consectetur
                  adipiscing elit, sed do eiusmod tempor incididunt
                  ut labore et dolore magna aliqua. Lectus proin
                  nibh nisl condimentum id. Semper feugiat nibh sed
                  pulvinar proin gravida hendrerit. Massa id neque
                  aliquam vestibulum morbi blandit cursus risus at.
                  Iaculis urna id volutpat lacus laoreet. Netus et
                  malesuada fames ac turpis egestas sed tempus urna.
        """)
  }

  @Test func long() {
    #expect(
      longSample.wrapped(to: 40) == """
        Pretium vulputate sapien nec sagittis
        aliquam malesuada bibendum. Ut diam
        quam nulla porttitor.

        Egestas egestas fringilla phasellus
        faucibus. Amet dictum sit amet justo
        donec enim diam. Consectetur adipiscing
        elit duis tristique.

        Enim lobortis scelerisque fermentum
        dui.

        Et leo duis ut diam quam.

        Integer eget aliquet nibh praesent
        tristique magna sit. Faucibus turpis in
        eu mi bibendum neque egestas congue
        quisque.       Risus nec feugiat in
        fermentum posuere urna nec tincidunt.
        """)

    #expect(
      longSample.wrapped(to: 80) == """
        Pretium vulputate sapien nec sagittis aliquam malesuada bibendum. Ut diam quam
        nulla porttitor.

        Egestas egestas fringilla phasellus faucibus. Amet dictum sit amet justo donec
        enim diam. Consectetur adipiscing elit duis tristique.

        Enim lobortis scelerisque fermentum dui.

        Et leo duis ut diam quam.

        Integer eget aliquet nibh praesent tristique magna sit. Faucibus turpis in eu
        mi bibendum neque egestas congue quisque.       Risus nec feugiat in fermentum
        posuere urna nec tincidunt.
        """)
  }

  @Test func longWithIndent() {
    #expect(
      longSample.wrapped(to: 60, wrappingIndent: 10) == """
                  Pretium vulputate sapien nec sagittis aliquam
                  malesuada bibendum. Ut diam quam nulla porttitor.

                  Egestas egestas fringilla phasellus faucibus.
                  Amet dictum sit amet justo donec enim diam.
                  Consectetur adipiscing elit duis tristique.

                  Enim lobortis scelerisque fermentum dui.

                  Et leo duis ut diam quam.

                  Integer eget aliquet nibh praesent tristique
                  magna sit. Faucibus turpis in eu mi bibendum
                  neque egestas congue quisque.       Risus nec
                  feugiat in fermentum posuere urna nec tincidunt.
        """)
  }

  @Test func json() {
    #expect(
      jsonSample.wrapped(to: 80) == """
        {
          "level1": {
            "level2": {
              "level3": true
            }
          }
        }
        """)
  }

  @Test func jsonWithIndent() {
    #expect(
      jsonSample.wrapped(to: 80, wrappingIndent: 10) == """
                  {
                    "level1": {
                      "level2": {
                        "level3": true
                      }
                    }
                  }
        """)
  }

  @Test func indent() {
    #expect(
      shortSample.wrapped(to: 40).indentingEachLine(by: 10)
        == shortSample.wrapped(to: 50, wrappingIndent: 10))
    #expect(
      longSample.wrapped(to: 40).indentingEachLine(by: 10)
        == longSample.wrapped(to: 50, wrappingIndent: 10))

    #expect("".indentingEachLine(by: 10) == "")
    #expect("\n".indentingEachLine(by: 10) == "\n")
    #expect("a\n".indentingEachLine(by: 10) == "          a\n")
    #expect("\na\n".indentingEachLine(by: 10) == "\n          a\n")
    #expect(
      "a\n\nb\n".indentingEachLine(by: 10)
        == "          a\n\n          b\n")
    #expect(
      "\na\n\nb\n".indentingEachLine(by: 10)
        == "\n          a\n\n          b\n")
  }

  @Test func hangingIndent() {
    #expect(
      shortSample.wrapped(to: 40).hangingIndentingEachLine(by: 10)
        == String(shortSample.wrapped(to: 50, wrappingIndent: 10).dropFirst(10))
    )
    #expect(
      longSample.wrapped(to: 40).hangingIndentingEachLine(by: 10)
        == String(longSample.wrapped(to: 50, wrappingIndent: 10).dropFirst(10)))

    #expect("".hangingIndentingEachLine(by: 10) == "")
    #expect("\n".hangingIndentingEachLine(by: 10) == "\n")
    #expect("a\n".hangingIndentingEachLine(by: 10) == "a\n")
    #expect("\na\n".hangingIndentingEachLine(by: 10) == "\n          a\n")
    #expect(
      "a\n\nb\n".hangingIndentingEachLine(by: 10)
        == "a\n\n          b\n")
    #expect(
      "\na\n\nb\n".hangingIndentingEachLine(by: 10)
        == "\n          a\n\n          b\n")
  }
}
