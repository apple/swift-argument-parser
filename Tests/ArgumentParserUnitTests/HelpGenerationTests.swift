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
@testable import ArgumentParser

final class HelpGenerationTests: XCTestCase {
}

extension URL: ExpressibleByArgument {
  public init?(argument: String) {
    guard let url = URL(string: argument) else {
      return nil
    }
    self = url
  }

  public var defaultValueDescription: String {
    self.absoluteString == FileManager.default.currentDirectoryPath
      ? "current directory"
      : String(describing: self)
  }
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

  enum OptionFlags: String, CaseIterable { case optional, required }
  enum Degree {
    case bachelor, master, doctor
    static func degreeTransform(_ string: String) throws -> Degree {
      switch string {
      case "bachelor":
        return .bachelor
      case "master":
        return .master
      case "doctor":
        return .doctor
      default:
        throw ValidationError("Not a valid string for 'Degree'")
      }
    }
  }


  struct D: ParsableCommand {
    @Argument(default: "--", help: "Your occupation.")
    var occupation: String

    @Option(default: "John", help: "Your name.")
    var name: String

    @Option(default: "Winston", help: "Your middle name.")
    var middleName: String?

    @Option(default: 20, help: "Your age.")
    var age: Int

    @Option(default: false, help: "Whether logging is enabled.")
    var logging: Bool

    @Flag(default: .optional, help: "Vegan diet.")
    var nda: OptionFlags

    @Option(default: .bachelor, help: "Your degree.", transform: Degree.degreeTransform)
    var degree: Degree

    @Option(default: URL(string: FileManager.default.currentDirectoryPath)!, help: "Directory.")
    var directory: URL
  }

  func testHelpWithDefaultValues() {
    AssertHelp(for: D.self, equals: """
            USAGE: d [<occupation>] [--name <name>] [--middle-name <middle-name>] [--age <age>] [--logging <logging>] [--optional] [--required] [--degree <degree>] [--directory <directory>]

            ARGUMENTS:
              <occupation>            Your occupation. (default: --)

            OPTIONS:
              --name <name>           Your name. (default: John)
              --middle-name <middle-name>
                                      Your middle name. (default: Winston)
              --age <age>             Your age. (default: 20)
              --logging <logging>     Whether logging is enabled. (default: false)
              --optional/--required   Vegan diet. (default: optional)
              --degree <degree>       Your degree. (default: bachelor)
              --directory <directory> Directory. (default: current directory)
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
                 -s/-c/-l                Change the program output (default: list)
                 -h, --help              Show help information.

               """)

    AssertHelp(for: G.self, equals: """
               USAGE: g [--flag] [--no-flag]

               OPTIONS:
                 --flag/--no-flag        Whether to flag (default: false)
                 -h, --help              Show help information.

               """)
  }
  
  struct H: ParsableCommand {
    struct CommandWithVeryLongName: ParsableCommand {}
    struct ShortCommand: ParsableCommand {
      static var configuration: CommandConfiguration = CommandConfiguration(abstract: "Test short command name.")
    }
    struct AnotherCommandWithVeryLongName: ParsableCommand {
      static var configuration: CommandConfiguration = CommandConfiguration(abstract: "Test long command name.")
    }
    struct AnotherCommand: ParsableCommand {
      @Option(default: nil)
      var someOptionWithVeryLongName: String?
      
      @Option(default: nil)
      var option: String?
      
      @Argument(default: "", help: "This is an argument with a long name.")
      var argumentWithVeryLongNameAndHelp: String
      
      @Argument(default: "")
      var argumentWithVeryLongName: String
      
      @Argument(default: "")
      var argument: String
    }
    static var configuration = CommandConfiguration(subcommands: [CommandWithVeryLongName.self,ShortCommand.self,AnotherCommandWithVeryLongName.self,AnotherCommand.self])
  }
  
  func testHelpWithSubcommands() {
    AssertHelp(for: H.self, equals: """
    USAGE: h <subcommand>

    OPTIONS:
      -h, --help              Show help information.

    SUBCOMMANDS:
      command-with-very-long-name
      short-command           Test short command name.
      another-command-with-very-long-name
                              Test long command name.
      another-command

    """)
    
    AssertHelp(for: H.AnotherCommand.self, equals: """
    USAGE: another-command [--some-option-with-very-long-name <some-option-with-very-long-name>] [--option <option>] [<argument-with-very-long-name-and-help>] [<argument-with-very-long-name>] [<argument>]

    ARGUMENTS:
      <argument-with-very-long-name-and-help>
                              This is an argument with a long name.
      <argument-with-very-long-name>
      <argument>

    OPTIONS:
      --some-option-with-very-long-name <some-option-with-very-long-name>
      --option <option>
      -h, --help              Show help information.

    """)
  }
}
