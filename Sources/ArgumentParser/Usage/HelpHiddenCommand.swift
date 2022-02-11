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

struct HelpHiddenCommand: ParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "experimental-help-hidden",
    abstract: "Show help information, including hidden options",
    helpNames: [])

  /// Any subcommand names provided after the `help` subcommand.
  @Argument var subcommands: [String] = []

  /// Capture and ignore any extra help flags given by the user.
  @Flag(name: [.customLong("experimental-help-hidden", withSingleDash: false)], help: .hidden)
  var helpHidden = false

  private(set) var commandStack: [ParsableCommand.Type] = []

  init() {}

  mutating func run() throws {
    throw CommandError(commandStack: commandStack, parserError: .helpHiddenRequested)
  }

  mutating func buildCommandStack(with parser: CommandParser) throws {
    commandStack = parser.commandStack(for: subcommands)
  }

  func generateHelp() -> String {
    return HelpGenerator(commandStack: commandStack, includeHidden: true).rendered()
  }

  enum CodingKeys: CodingKey {
    case subcommands
    case helpHidden
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.subcommands = try container.decode([String].self, forKey: .subcommands)
    self.helpHidden = try container.decode(Bool.self, forKey: .helpHidden)
  }

  init(commandStack: [ParsableCommand.Type]) {
    self.commandStack = commandStack
    self.subcommands = commandStack.map { $0._commandName }
    self.helpHidden = false
  }
}
