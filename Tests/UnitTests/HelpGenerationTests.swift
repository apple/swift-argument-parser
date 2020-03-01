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
import TestHelpers
@testable import ArgumentParser

final class HelpGenerationTests: XCTestCase {
}

// MARK: -

extension HelpGenerationTests {
  struct A: ParsableArguments {
    @Option(help: "Your name") var name: String
    @Option(help: "Your title") var title: String?
  }
  
  func testHelp() {
    AssertHelp(for: A.self, equals: """
            USAGE: a --name <name> [--title <title>]

            OPTIONS:
              --name <name>           Your name
              --title <title>         Your title
              -h, --help              Show help information.
            
            """)
  }
  
  struct B: ParsableArguments {
    @Option(help: "Your name") var name: String
    @Option(help: "Your title") var title: String?
    
    @Argument(help: .hidden) var hiddenName: String?
    @Option(help: .hidden) var hiddenTitle: String?
    @Flag(help: .hidden) var hiddenFlag: Bool
  }
  
  func testHelpWithHidden() {
    AssertHelp(for: B.self, equals: """
            USAGE: b --name <name> [--title <title>]

            OPTIONS:
              --name <name>           Your name
              --title <title>         Your title
              -h, --help              Show help information.
            
            """)
  }
  
  struct C: ParsableArguments {
    @Option(help: ArgumentHelp("Your name.",
                               discussion: "Your name is used to greet you and say hello."))
    var name: String
  }
  
  func testHelpWithDiscussion() {
    AssertHelp(for: C.self, equals: """
            USAGE: c --name <name>

            OPTIONS:
              --name <name>           Your name.
                    Your name is used to greet you and say hello.
              -h, --help              Show help information.

            """)
  }

  struct Issue27: ParsableArguments {
    @Option(default: "42")
    var two: String
    @Option(help: "The third option")
    var three: String
  }

  func testHelpWithDefaultValueButNoDiscussion() {
    AssertHelp(for: Issue27.self, equals: """
            USAGE: issue27 [--two <two>] --three <three>

            OPTIONS:
              --two <two>             (default: 42)
              --three <three>         The third option
              -h, --help              Show help information.

            """)
  }
}
