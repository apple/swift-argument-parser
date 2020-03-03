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
    @Option(default: nil, help: "A fourth option")
    var four: String?
    @Option(default: "", help: "A fifth option")
    var five: String
  }

  func testHelpWithDefaultValueButNoDiscussion() {
    AssertHelp(for: Issue27.self, equals: """
            USAGE: issue27 [--two <two>] --three <three> [--four <four>] [--five <five>]

            OPTIONS:
              --two <two>             (default: 42)
              --three <three>         The third option
              --four <four>           A fourth option
              --five <five>           A fifth option
              -h, --help              Show help information.

            """)
  }

  struct D: ParsableCommand {

    @Option(default: "John", help: "Your name.")
    var name: String

    @Option(default: 20, help: "Your age.")
    var age: Int

    @Option(default: false, help: "Whether logging is enabled.")
    var logging: Bool
  }

  func testHelpWithDefaultValues() {
    AssertHelp(for: D.self, equals: """
            USAGE: d [--name <name>] [--age <age>] [--logging <logging>]

            OPTIONS:
              --name <name>           Your name. (default: John)
              --age <age>             Your age. (default: 20)
              --logging <logging>     Whether logging is enabled. (default: false)
              -h, --help              Show help information.

            """)
  }

  enum OutputBehaviour: String, CaseIterable { case stats, count, list }
  struct E: ParsableCommand {
    @Flag(name: .shortAndLong, help: "Change the program output")
    var behaviour: OutputBehaviour
  }
  struct F: ParsableCommand {
    @Flag(name: .short, default: .list, help: "Change the program output")
    var behaviour: OutputBehaviour
  }
  struct G: ParsableCommand {
    @Flag(inversion: .prefixedNo, help: "Whether to flag")
    var flag: Bool
  }

  func testHelpWithMutuallyExclusiveFlags() {
    AssertHelp(for: E.self, equals: """
               USAGE: e --stats --count --list

               OPTIONS:
                 -s, --stats/-c, --count/-l, --list
                                         Change the program output
                 -h, --help              Show help information.

               """)

    AssertHelp(for: F.self, equals: """
               USAGE: f [-s] [-c] [-l]

               OPTIONS:
                 -s/-c/-l                Change the program output
                 -h, --help              Show help information.

               """)

    AssertHelp(for: G.self, equals: """
               USAGE: g [--flag] [--no-flag]

               OPTIONS:
                 --flag/--no-flag        Whether to flag (default: false)
                 -h, --help              Show help information.

               """)
  }
}
