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
    self.path == FileManager.default.currentDirectoryPath && self.isFileURL
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
    AssertHelp(.default, for: A.self, equals: """
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
    @Flag(help: .hidden) var hiddenFlag: Bool = false
    @Flag(inversion: .prefixedNo, help: .hidden) var hiddenInvertedFlag: Bool = true
  }

  func testHelpWithHidden() {
    AssertHelp(.default, for: B.self, equals: """
            USAGE: b --name <name> [--title <title>]

            OPTIONS:
              --name <name>           Your name
              --title <title>         Your title
              -h, --help              Show help information.

            """)

    AssertHelp(.hidden, for: B.self, equals: """
            USAGE: b --name <name> [--title <title>] [<hidden-name>] [--hidden-title <hidden-title>] [--hidden-flag] [--hidden-inverted-flag] [--no-hidden-inverted-flag]

            ARGUMENTS:
              <hidden-name>

            OPTIONS:
              --name <name>           Your name
              --title <title>         Your title
              --hidden-title <hidden-title>
              --hidden-flag
              --hidden-inverted-flag/--no-hidden-inverted-flag
                                      (default: --hidden-inverted-flag)
              -h, --help              Show help information.

            """)
  }

  struct C: ParsableArguments {
    @Option(help: ArgumentHelp("Your name.",
                               discussion: "Your name is used to greet you and say hello."))
    var name: String
  }

  func testHelpWithDiscussion() {
    AssertHelp(.default, for: C.self, equals: """
            USAGE: c --name <name>

            OPTIONS:
              --name <name>           Your name.
                    Your name is used to greet you and say hello.
              -h, --help              Show help information.

            """)
  }

  struct Issue27: ParsableArguments {
    @Option
    var two: String = "42"
    @Option(help: "The third option")
    var three: String
    @Option(help: "A fourth option")
    var four: String?
    @Option(help: "A fifth option")
    var five: String = ""
  }

  func testHelpWithDefaultValueButNoDiscussion() {
    AssertHelp(.default, for: Issue27.self, equals: """
            USAGE: issue27 [--two <two>] --three <three> [--four <four>] [--five <five>]

            OPTIONS:
              --two <two>             (default: 42)
              --three <three>         The third option
              --four <four>           A fourth option
              --five <five>           A fifth option
              -h, --help              Show help information.

            """)
  }

  enum OptionFlags: String, EnumerableFlag { case optional, required }
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
    @Argument(help: "Your occupation.")
    var occupation: String = "--"

    @Option(help: "Your name.")
    var name: String = "John"

    @Option(help: "Your age.")
    var age: Int = 20

    @Option(help: "Whether logging is enabled.")
    var logging: Bool = false

    @Option(parsing: .upToNextOption, help: ArgumentHelp("Your lucky numbers.", valueName: "numbers"))
    var lucky: [Int] = [7, 14]

    @Flag(help: "Vegan diet.")
    var nda: OptionFlags = .optional

    @Option(help: "Your degree.", transform: Degree.degreeTransform)
    var degree: Degree = .bachelor

    @Option(help: "Directory.")
    var directory: URL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

    enum Manual: Int, ExpressibleByArgument {
      case foo
      var defaultValueDescription: String { "default-value" }
    }
    @Option(help: "Manual Option.")
    var manual: Manual = .foo

    enum UnspecializedSynthesized: Int, CaseIterable, ExpressibleByArgument {
      case one, two
    }
    @Option(help: "Unspecialized Synthesized")
    var unspecial: UnspecializedSynthesized = .one

    enum SpecializedSynthesized: String, CaseIterable, ExpressibleByArgument {
      case apple = "Apple", banana = "Banana"
    }
    @Option(help: "Specialized Synthesized")
    var special: SpecializedSynthesized = .apple
  }

  func testHelpWithDefaultValues() {
    AssertHelp(.default, for: D.self, equals: """
      USAGE: d [<occupation>] [--name <name>] [--age <age>] [--logging <logging>] [--lucky <numbers> ...] [--optional] [--required] [--degree <degree>] [--directory <directory>] [--manual <manual>] [--unspecial <unspecial>] [--special <special>]

      ARGUMENTS:
        <occupation>            Your occupation. (default: --)

      OPTIONS:
        --name <name>           Your name. (default: John)
        --age <age>             Your age. (default: 20)
        --logging <logging>     Whether logging is enabled. (default: false)
        --lucky <numbers>       Your lucky numbers. (default: 7, 14)
        --optional/--required   Vegan diet. (default: --optional)
        --degree <degree>       Your degree.
        --directory <directory> Directory. (default: current directory)
        --manual <manual>       Manual Option. (default: default-value)
        --unspecial <unspecial> Unspecialized Synthesized (default: 0)
        --special <special>     Specialized Synthesized (default: Apple)
        -h, --help              Show help information.

      """)
  }

  struct E: ParsableCommand {
    enum OutputBehaviour: String, EnumerableFlag {
      case stats, count, list

      static func name(for value: OutputBehaviour) -> NameSpecification {
        .shortAndLong
      }
    }

    @Flag(help: "Change the program output")
    var behaviour: OutputBehaviour
  }

  struct F: ParsableCommand {
    enum OutputBehaviour: String, EnumerableFlag {
      case stats, count, list

      static func name(for value: OutputBehaviour) -> NameSpecification {
        .short
      }
    }

    @Flag(help: "Change the program output")
    var behaviour: OutputBehaviour = .list
  }

  struct G: ParsableCommand {
    @Flag(inversion: .prefixedNo, help: "Whether to flag")
    var flag: Bool = false
  }

  func testHelpWithMutuallyExclusiveFlags() {
    AssertHelp(.default, for: E.self, equals: """
               USAGE: e --stats --count --list

               OPTIONS:
                 -s, --stats/-c, --count/-l, --list
                                         Change the program output
                 -h, --help              Show help information.

               """)

    AssertHelp(.default, for: F.self, equals: """
               USAGE: f [-s] [-c] [-l]

               OPTIONS:
                 -s/-c/-l                Change the program output (default: -l)
                 -h, --help              Show help information.

               """)

    AssertHelp(.default, for: G.self, equals: """
               USAGE: g [--flag] [--no-flag]

               OPTIONS:
                 --flag/--no-flag        Whether to flag (default: --no-flag)
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
      @Option()
      var someOptionWithVeryLongName: String?

      @Option()
      var option: String?

      @Argument(help: "This is an argument with a long name.")
      var argumentWithVeryLongNameAndHelp: String = ""

      @Argument
      var argumentWithVeryLongName: String = ""

      @Argument
      var argument: String = ""
    }
    static var configuration = CommandConfiguration(subcommands: [CommandWithVeryLongName.self,ShortCommand.self,AnotherCommandWithVeryLongName.self,AnotherCommand.self])
  }

  func testHelpWithSubcommands() {
    AssertHelp(.default, for: H.self, equals: """
    USAGE: h <subcommand>

    OPTIONS:
      -h, --help              Show help information.

    SUBCOMMANDS:
      command-with-very-long-name
      short-command           Test short command name.
      another-command-with-very-long-name
                              Test long command name.
      another-command

      See 'h help <subcommand>' for detailed help.
    """)

    AssertHelp(.default, for: H.AnotherCommand.self, root: H.self, equals: """
    USAGE: h another-command [--some-option-with-very-long-name <some-option-with-very-long-name>] [--option <option>] [<argument-with-very-long-name-and-help>] [<argument-with-very-long-name>] [<argument>]

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

  struct I: ParsableCommand {
    static var configuration = CommandConfiguration(version: "1.0.0")
  }

  func testHelpWithVersion() {
    AssertHelp(.default, for: I.self, equals: """
    USAGE: i

    OPTIONS:
      --version               Show the version.
      -h, --help              Show help information.

    """)

  }

  struct J: ParsableCommand {
    static var configuration = CommandConfiguration(discussion: "test")
  }

  func testOverviewButNoAbstractSpacing() {
    let renderedHelp = HelpGenerator(J.self, visibility: .default)
      .rendered()
    AssertEqualStringsIgnoringTrailingWhitespace(renderedHelp, """
    OVERVIEW:
    test

    USAGE: j

    OPTIONS:
      -h, --help              Show help information.

    """)
  }

  struct K: ParsableCommand {
    @Argument(help: "A list of paths.")
    var paths: [String] = []

    func validate() throws {
      if paths.isEmpty {
        throw ValidationError("At least one path must be specified.")
      }
    }
  }

  func testHelpWithNoValueForArray() {
    AssertHelp(.default, for: K.self, equals: """
    USAGE: k [<paths> ...]

    ARGUMENTS:
      <paths>                 A list of paths.

    OPTIONS:
      -h, --help              Show help information.

    """)
  }

  struct L: ParsableArguments {
    @Option(
      name: [.short, .customLong("remote"), .customLong("remote"), .short, .customLong("when"), .long, .customLong("other", withSingleDash: true), .customLong("there"), .customShort("x"), .customShort("y")],
      help: "Help Message")
    var time: String?
  }

  func testHelpWithMultipleCustomNames() {
    AssertHelp(.default, for: L.self, equals: """
    USAGE: l [--remote <remote>]

    OPTIONS:
      -t, -x, -y, --remote, --when, --time, -other, --there <remote>
                              Help Message
      -h, --help              Show help information.

    """)
  }

  struct M: ParsableCommand {
  }
  struct N: ParsableCommand {
    static var configuration = CommandConfiguration(subcommands: [M.self], defaultSubcommand: M.self)
  }

  func testHelpWithDefaultCommand() {
    AssertHelp(.default, for: N.self, equals: """
    USAGE: n <subcommand>

    OPTIONS:
      -h, --help              Show help information.

    SUBCOMMANDS:
      m (default)

      See 'n help <subcommand>' for detailed help.
    """)
  }

  enum O: String, ExpressibleByArgument {
    case small
    case medium
    case large

    init?(argument: String) {
      guard let result = Self(rawValue: argument) else {
        return nil
      }
      self = result
    }
  }
  struct P: ParsableArguments {
    @Option(name: [.short], help: "Help Message")
    var o: [O] = [.small, .medium]

    @Argument(help: "Help Message")
    var remainder: [O] = [.large]
  }

  func testHelpWithDefaultValueForArray() {
    AssertHelp(.default, for: P.self, equals: """
    USAGE: p [-o <o> ...] [<remainder> ...]

    ARGUMENTS:
      <remainder>             Help Message (default: large)

    OPTIONS:
      -o <o>                  Help Message (default: small, medium)
      -h, --help              Show help information.

    """)
  }
    
  struct Foo: ParsableCommand {
    public static var configuration = CommandConfiguration(
      commandName: "foo",
      abstract: "Perform some foo",
      subcommands: [
        Bar.self
      ],
      helpNames: [.short, .long, .customLong("help", withSingleDash: true)])
        
    @Option(help: "Name for foo")
    var fooName: String?
        
    public init() {}
  }

  struct Bar: ParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "bar",
      _superCommandName: "foo",
      abstract: "Perform bar operations",
      helpNames: [.short, .long, .customLong("help", withSingleDash: true)])
            
    @Option(help: "Bar Strength")
    var barStrength: String?
        
    public init() {}
  }

  func testHelpExcludingSuperCommand() throws {
    AssertHelp(.default, for: Bar.self, root: Foo.self, equals: """
    OVERVIEW: Perform bar operations

    USAGE: foo bar [--bar-strength <bar-strength>]

    OPTIONS:
      --bar-strength <bar-strength>
                              Bar Strength
      -h, -help, --help       Show help information.
    
    """)
  }
}

extension HelpGenerationTests {
  private struct optionsToHide: ParsableArguments {
    @Flag(help: "Verbose")
    var verbose: Bool = false
    
    @Option(help: "Custom Name")
    var customName: String?
    
    @Option(help: .hidden)
    var hiddenOption: String?
    
    @Argument(help: .private)
    var privateArg: String?
  }

  @available(*, deprecated)
  private struct HideOptionGroupLegacyDriver: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "driver", abstract: "Demo hiding option groups")
    
    @OptionGroup(_hiddenFromHelp: true)
    var hideMe: optionsToHide
    
    @Option(help: "Time to wait before timeout (in seconds)")
    var timeout: Int?
  }

  private struct HideOptionGroupDriver: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "driver", abstract: "Demo hiding option groups")

    @OptionGroup(visibility: .hidden)
    var hideMe: optionsToHide

    @Option(help: "Time to wait before timeout (in seconds)")
    var timeout: Int?
  }

  private struct PrivateOptionGroupDriver: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "driver", abstract: "Demo hiding option groups")

    @OptionGroup(visibility: .private)
    var hideMe: optionsToHide

    @Option(help: "Time to wait before timeout (in seconds)")
    var timeout: Int?
  }

  private var helpMessage: String { """
    OVERVIEW: Demo hiding option groups

    USAGE: driver [--timeout <timeout>]

    OPTIONS:
      --timeout <timeout>     Time to wait before timeout (in seconds)
      -h, --help              Show help information.

    """
  }

  private var helpHiddenMessage: String { """
    OVERVIEW: Demo hiding option groups

    USAGE: driver [--verbose] [--custom-name <custom-name>] [--hidden-option <hidden-option>] [--timeout <timeout>]

    OPTIONS:
      --verbose               Verbose
      --custom-name <custom-name>
                              Custom Name
      --hidden-option <hidden-option>
      --timeout <timeout>     Time to wait before timeout (in seconds)
      -h, --help              Show help information.

    """
  }

  @available(*, deprecated)
  func testHidingOptionGroup() throws {
    AssertHelp(.default, for: HideOptionGroupLegacyDriver.self, equals: helpMessage)
    AssertHelp(.default, for: HideOptionGroupDriver.self, equals: helpMessage)
    AssertHelp(.default, for: PrivateOptionGroupDriver.self, equals: helpMessage)
  }

  @available(*, deprecated)
  func testHelpHiddenShowsDefaultAndHidden() throws {
    AssertHelp(.hidden, for: HideOptionGroupLegacyDriver.self, equals: helpHiddenMessage)
    AssertHelp(.hidden, for: HideOptionGroupDriver.self, equals: helpHiddenMessage)
    
    // Note: Private option groups are not visible at `.hidden` help level.
    AssertHelp(.hidden, for: PrivateOptionGroupDriver.self, equals: helpMessage)
  }
}

extension HelpGenerationTests {
  struct AllValues: ParsableCommand {
    enum Manual: Int, ExpressibleByArgument {
      case foo
      static var allValueStrings = ["bar"]
    }

    enum UnspecializedSynthesized: Int, CaseIterable, ExpressibleByArgument {
      case one, two
    }

    enum SpecializedSynthesized: String, CaseIterable, ExpressibleByArgument {
      case apple = "Apple", banana = "Banana"
    }

    @Argument var manualArgument: Manual
    @Option var manualOption: Manual

    @Argument var unspecializedSynthesizedArgument: UnspecializedSynthesized
    @Option var unspecializedSynthesizedOption: UnspecializedSynthesized

    @Argument var specializedSynthesizedArgument: SpecializedSynthesized
    @Option var specializedSynthesizedOption: SpecializedSynthesized
  }

  func testAllValueStrings() throws {
    XCTAssertEqual(AllValues.Manual.allValueStrings, ["bar"])
    XCTAssertEqual(AllValues.UnspecializedSynthesized.allValueStrings, ["0", "1"])
    XCTAssertEqual(AllValues.SpecializedSynthesized.allValueStrings, ["Apple", "Banana"])
  }

  func testAllValues() {
    let opts = ArgumentSet(AllValues.self, visibility: .private, parent: .root)
    XCTAssertEqual(AllValues.Manual.allValueStrings, opts[0].help.allValues)
    XCTAssertEqual(AllValues.Manual.allValueStrings, opts[1].help.allValues)

    XCTAssertEqual(AllValues.UnspecializedSynthesized.allValueStrings, opts[2].help.allValues)
    XCTAssertEqual(AllValues.UnspecializedSynthesized.allValueStrings, opts[3].help.allValues)

    XCTAssertEqual(AllValues.SpecializedSynthesized.allValueStrings, opts[4].help.allValues)
    XCTAssertEqual(AllValues.SpecializedSynthesized.allValueStrings, opts[5].help.allValues)
  }

  struct Q: ParsableArguments {
    @Option(help: "Your name") var name: String
    @Option(help: "Your title") var title: String?

    @Argument(help: .private) var privateName: String?
    @Option(help: .private) var privateTitle: String?
    @Flag(help: .private) var privateFlag: Bool = false
    @Flag(inversion: .prefixedNo, help: .private) var privateInvertedFlag: Bool = true
  }

  func testHelpWithPrivate() {
    AssertHelp(.default, for: Q.self, equals: """
            USAGE: q --name <name> [--title <title>]

            OPTIONS:
              --name <name>           Your name
              --title <title>         Your title
              -h, --help              Show help information.

            """)
  }
}

// MARK: - Issue #278 https://github.com/apple/swift-argument-parser/issues/278

extension HelpGenerationTests {
  private struct ParserBug: ParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "parserBug",
      subcommands: [Sub.self])
    
    struct CommonOptions: ParsableCommand {
      @Flag(help: "example flag")
      var example: Bool = false
    }

    struct Sub: ParsableCommand {
      @OptionGroup()
      var commonOptions: CommonOptions
      
      @Argument(help: "Non-mandatory argument")
      var argument: String?
    }
  }
  
  func testIssue278() {
    AssertHelp(.default, for: ParserBug.Sub.self, root: ParserBug.self, equals: """
      USAGE: parserBug sub [--example] [<argument>]

      ARGUMENTS:
        <argument>              Non-mandatory argument

      OPTIONS:
        --example               example flag
        -h, --help              Show help information.

      """)
  }

  struct CustomUsageShort: ParsableCommand {
    static var configuration: CommandConfiguration {
      CommandConfiguration(usage: """
        example [--verbose] <file-name>
        """)
    }
    
    @Argument var file: String
    @Flag var verboseMode = false
  }
  
  struct CustomUsageLong: ParsableCommand {
    static var configuration: CommandConfiguration {
      CommandConfiguration(usage: """
        example <file-name>
        example --verbose <file-name>
        example --help
        """)
    }
    
    @Argument var file: String
    @Flag var verboseMode = false
  }

  struct CustomUsageHidden: ParsableCommand {
    static var configuration: CommandConfiguration {
      CommandConfiguration(usage: "")
    }
    
    @Argument var file: String
    @Flag var verboseMode = false
  }

  func testCustomUsageHelp() {
    XCTAssertEqual(CustomUsageShort.helpMessage(columns: 80), """
      USAGE: example [--verbose] <file-name>

      ARGUMENTS:
        <file>

      OPTIONS:
        --verbose-mode
        -h, --help              Show help information.
      
      """)
    
    XCTAssertEqual(CustomUsageLong.helpMessage(columns: 80), """
      USAGE: example <file-name>
             example --verbose <file-name>
             example --help

      ARGUMENTS:
        <file>

      OPTIONS:
        --verbose-mode
        -h, --help              Show help information.
      
      """)
    
    XCTAssertEqual(CustomUsageHidden.helpMessage(columns: 80), """
      ARGUMENTS:
        <file>

      OPTIONS:
        --verbose-mode
        -h, --help              Show help information.
      
      """)
  }
  
  func testCustomUsageError() {
    XCTAssertEqual(CustomUsageShort.fullMessage(for: ValidationError("Test")), """
      Error: Test
      Usage: example [--verbose] <file-name>
        See 'custom-usage-short --help' for more information.
      """)
    XCTAssertEqual(CustomUsageLong.fullMessage(for: ValidationError("Test")), """
      Error: Test
      Usage: example <file-name>
             example --verbose <file-name>
             example --help
        See 'custom-usage-long --help' for more information.
      """)
    XCTAssertEqual(CustomUsageHidden.fullMessage(for: ValidationError("Test")), """
      Error: Test
        See 'custom-usage-hidden --help' for more information.
      """)
  }
}
