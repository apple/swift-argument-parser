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

struct HelpCommand: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "help",
    abstract: "Show subcommand help information.",
    helpNames: [])

  /// Any subcommand names provided after the `help` subcommand.
  @Argument var subcommands: [String] = []

  /// Capture and ignore any extra help flags given by the user.
  @Flag(
    name: [.short, .long, .customLong("help", withSingleDash: true)],
    help: .private)
  var help = false

  /// Search term for finding commands and options.
  @Option(
    name: [.short, .long],
    help: "Search for commands and options matching the term.")
  var search: String?

  private(set) var commandStack: [ParsableCommand.Type] = []
  private(set) var visibility: ArgumentVisibility = .default
  private(set) var commandTree: Tree<ParsableCommand.Type>?

  init() {}

  mutating func run() throws {
    // If search term is provided, perform search instead of showing help
    if let searchTerm = search {
      performSearch(term: searchTerm)
      return
    }

    throw CommandError(
      commandStack: commandStack,
      parserError: .helpRequested(visibility: visibility))
  }

  mutating func buildCommandStack(with parser: CommandParser) throws {
    commandStack = parser.commandStack(for: subcommands)
    commandTree = parser.commandTree

    // If subcommands were specified, find the corresponding node in the tree
    if !subcommands.isEmpty {
      var currentNode = parser.commandTree
      for subcommand in subcommands {
        if let child = currentNode.firstChild(withName: subcommand) {
          currentNode = child
          commandTree = currentNode
        }
      }
    }
  }

  private func performSearch(term: String) {
    guard let tree = commandTree else {
      print("Error: Command tree not initialized.")
      return
    }

    // Get the tool name for display
    var toolName = commandStack.map { $0._commandName }.joined(separator: " ")
    if toolName.isEmpty {
      toolName = tree.element._commandName
    }
    if let root = commandStack.first, let superName = root.configuration._superCommandName {
      toolName = "\(superName) \(toolName)"
    }

    // Create search engine and perform search
    let searchEngine = SearchEngine(
      rootNode: tree,
      commandStack: commandStack.isEmpty ? [tree.element] : commandStack,
      visibility: visibility
    )

    let results = searchEngine.search(for: term)

    // Format and print results
    let output = SearchEngine.formatResults(
      results,
      term: term,
      toolName: toolName,
      screenWidth: HelpGenerator.systemScreenWidth
    )

    print(output)
  }

  /// Used for testing.
  func generateHelp(screenWidth: Int) -> String {
    HelpGenerator(
      commandStack: commandStack,
      visibility: visibility
    )
    .rendered(screenWidth: screenWidth)
  }

  enum CodingKeys: CodingKey {
    case subcommands
    case help
    case search
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.subcommands = try container.decode([String].self, forKey: .subcommands)
    self.help = try container.decode(Bool.self, forKey: .help)
    self.search = try container.decodeIfPresent(String.self, forKey: .search)
  }

  init(commandStack: [ParsableCommand.Type], visibility: ArgumentVisibility) {
    self.commandStack = commandStack
    self.visibility = visibility
    self.subcommands = commandStack.map { $0._commandName }
    self.help = false
    self.search = nil
  }
}
