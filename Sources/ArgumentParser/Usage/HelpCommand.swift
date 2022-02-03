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

struct HelpCommand: ParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "help",
    abstract: "Show subcommand help information.",
    helpNames: [])
  
  /// Any subcommand names provided after the `help` subcommand.
  @Argument var subcommands: [String] = []

  /// Get the name specification to use for this command.
  ///
  /// - Parameters:
  ///   - forDisplay: Whether or not the set of names is intended for display to
  ///     the user.
  static func nameSpecification(forDisplay: Bool) -> NameSpecification {
    switch (ParsingConvention.current, forDisplay) {
    case (.posix, true):
      return [.short, .long]
    case (.posix, false):
      return [.short, .long, .customLong("help", withShortPrefix: true)]
    case (.dos, true):
      return [.customLong("?"), .customLong("h"), .customLong("Help")]
    case (.dos, false):
      return [.customLong("?"), .customLong("H"), .customLong("h"), .customLong("help"), .customLong("Help")]
    }
  }

  /// Capture and ignore any extra help flags given by the user.
  @Flag(name: Self.nameSpecification(forDisplay: false), help: .hidden)
  var help = false
  
  private(set) var commandStack: [ParsableCommand.Type] = []
  
  init() {}
  
  mutating func run() throws {
    throw CommandError(commandStack: commandStack, parserError: .helpRequested)
  }
  
  mutating func buildCommandStack(with parser: CommandParser) throws {
    commandStack = parser.commandStack(for: subcommands)
  }

  /// Used for testing.
  func generateHelp(screenWidth: Int) -> String {
    HelpGenerator(commandStack: commandStack).rendered(screenWidth: screenWidth)
  }
  
  enum CodingKeys: CodingKey {
    case subcommands
    case help
  }
  
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.subcommands = try container.decode([String].self, forKey: .subcommands)
    self.help = try container.decode(Bool.self, forKey: .help)
  }
  
  init(commandStack: [ParsableCommand.Type]) {
    self.commandStack = commandStack
    self.subcommands = commandStack.map { $0._commandName }
    self.help = false
  }
}
