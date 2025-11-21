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

#if compiler(>=6.0)
#if canImport(FoundationEssentials)
internal import FoundationEssentials
#else
internal import Foundation
#endif
#else
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
#endif

/// A search result representing a match found in the command tree.
struct SearchResult {
  /// The type of match found.
  enum MatchType: Equatable {
    /// Matched a command name or alias.
    case commandName(matchedText: String)
    /// Matched text in a command's abstract or discussion.
    case commandDescription(matchedText: String)
    /// Matched an argument name (e.g., --verbose, -v).
    case argumentName(name: String, matchedText: String)
    /// Matched text in an argument's help text.
    case argumentDescription(name: String, matchedText: String)
    /// Matched text in an argument's possible values or default value.
    case argumentValue(name: String, matchedText: String)
  }

  /// The full path to the command containing this match (e.g., ["mytool", "sub", "command"]).
  var commandPath: [String]

  /// The type of match and associated data.
  var matchType: MatchType

  /// A snippet of text showing the match in context.
  var contextSnippet: String

  /// Returns true if this is a command match (name or description).
  var isCommandMatch: Bool {
    switch matchType {
    case .commandName, .commandDescription:
      return true
    case .argumentName, .argumentDescription, .argumentValue:
      return false
    }
  }

  /// Returns the display label for this result.
  var displayLabel: String {
    switch matchType {
    case .commandName(let matched):
      return "name: \(matched)"
    case .commandDescription:
      return "description"
    case .argumentName(let name, _):
      return name
    case .argumentDescription(let name, _):
      return "\(name): description"
    case .argumentValue(let name, _):
      return "\(name): value"
    }
  }
}

/// Engine for searching through command trees.
struct SearchEngine {
  /// The starting point for the search (root or subcommand).
  var rootNode: Tree<ParsableCommand.Type>

  /// The command stack leading to the root node.
  var commandStack: [ParsableCommand.Type]

  /// The visibility level for arguments.
  var visibility: ArgumentVisibility

  /// Search for the given term and return all matches.
  ///
  /// - Parameter term: The search term (case-insensitive substring match).
  /// - Returns: An array of search results, ordered by relevance.
  func search(for term: String) -> [SearchResult] {
    guard !term.isEmpty else { return [] }

    let lowercasedTerm = term.lowercased()
    var results: [SearchResult] = []

    // Traverse the tree starting from rootNode
    traverseTree(node: rootNode, currentPath: commandStack.map { $0._commandName }, term: lowercasedTerm, results: &results)

    // Sort results: command matches first, then argument matches
    return results.sorted { lhs, rhs in
      if lhs.isCommandMatch != rhs.isCommandMatch {
        return lhs.isCommandMatch
      }
      return lhs.commandPath.joined(separator: " ") < rhs.commandPath.joined(separator: " ")
    }
  }

  /// Recursively traverse the command tree and collect matches.
  private func traverseTree(
    node: Tree<ParsableCommand.Type>,
    currentPath: [String],
    term: String,
    results: inout [SearchResult]
  ) {
    let command = node.element
    let configuration = command.configuration

    // Don't search commands that shouldn't be displayed
    guard configuration.shouldDisplay else { return }

    // Search command name
    let commandName = command._commandName
    if commandName.lowercased().contains(term) {
      results.append(SearchResult(
        commandPath: currentPath,
        matchType: .commandName(matchedText: commandName),
        contextSnippet: commandName
      ))
    }

    // Search command aliases
    for alias in configuration.aliases {
      if alias.lowercased().contains(term) {
        results.append(SearchResult(
          commandPath: currentPath,
          matchType: .commandName(matchedText: alias),
          contextSnippet: alias
        ))
      }
    }

    // Search command abstract
    if !configuration.abstract.isEmpty && configuration.abstract.lowercased().contains(term) {
      let snippet = extractSnippet(from: configuration.abstract, around: term)
      results.append(SearchResult(
        commandPath: currentPath,
        matchType: .commandDescription(matchedText: snippet),
        contextSnippet: snippet
      ))
    }

    // Search command discussion
    if !configuration.discussion.isEmpty && configuration.discussion.lowercased().contains(term) {
      let snippet = extractSnippet(from: configuration.discussion, around: term)
      results.append(SearchResult(
        commandPath: currentPath,
        matchType: .commandDescription(matchedText: snippet),
        contextSnippet: snippet
      ))
    }

    // Search arguments
    searchArguments(command: command, commandPath: currentPath, term: term, results: &results)

    // Recursively search children
    for child in node.children {
      let childName = child.element._commandName
      traverseTree(
        node: child,
        currentPath: currentPath + [childName],
        term: term,
        results: &results
      )
    }
  }

  /// Search through all arguments of a command.
  private func searchArguments(
    command: ParsableCommand.Type,
    commandPath: [String],
    term: String,
    results: inout [SearchResult]
  ) {
    let argSet = ArgumentSet(command, visibility: visibility, parent: nil)

    for arg in argSet {
      // Skip if not visible enough
      guard arg.help.visibility.isAtLeastAsVisible(as: visibility) else { continue }

      let names = arg.names

      // Search argument names
      for name in names {
        let nameString = name.synopsisString
        if nameString.lowercased().contains(term) {
          // Get a display name for this argument
          let displayNames = names.map { $0.synopsisString }.joined(separator: ", ")
          results.append(SearchResult(
            commandPath: commandPath,
            matchType: .argumentName(name: displayNames, matchedText: nameString),
            contextSnippet: arg.help.abstract
          ))
          break // Only add once per argument even if multiple names match
        }
      }

      // Get display name for this argument
      let displayNames = names.map { $0.synopsisString }.joined(separator: ", ")

      // Search argument abstract
      if !arg.help.abstract.isEmpty && arg.help.abstract.lowercased().contains(term) {
        let snippet = extractSnippet(from: arg.help.abstract, around: term)
        results.append(SearchResult(
          commandPath: commandPath,
          matchType: .argumentDescription(name: displayNames, matchedText: snippet),
          contextSnippet: snippet
        ))
      }

      // Search argument discussion
      if case .staticText(let discussionText) = arg.help.discussion,
         !discussionText.isEmpty && discussionText.lowercased().contains(term) {
        let snippet = extractSnippet(from: discussionText, around: term)
        results.append(SearchResult(
          commandPath: commandPath,
          matchType: .argumentDescription(name: displayNames, matchedText: snippet),
          contextSnippet: snippet
        ))
      }

      // Search possible values
      for value in arg.help.allValueStrings where !value.isEmpty {
        if value.lowercased().contains(term) {
          results.append(SearchResult(
            commandPath: commandPath,
            matchType: .argumentValue(name: displayNames, matchedText: value),
            contextSnippet: "possible value: \(value)"
          ))
        }
      }

      // Search default value
      if let defaultValue = arg.help.defaultValue,
         !defaultValue.isEmpty && defaultValue.lowercased().contains(term) {
        results.append(SearchResult(
          commandPath: commandPath,
          matchType: .argumentValue(name: displayNames, matchedText: defaultValue),
          contextSnippet: "default: \(defaultValue)"
        ))
      }
    }
  }

  /// Extract a snippet of text around the matched term.
  ///
  /// - Parameters:
  ///   - text: The full text containing the match.
  ///   - term: The search term (lowercased).
  /// - Returns: A snippet showing the match in context (max ~80 chars).
  private func extractSnippet(from text: String, around term: String) -> String {
    let maxSnippetLength = 80
    let lowercasedText = text.lowercased()

    guard let matchRange = lowercasedText.range(of: term) else {
      // Shouldn't happen, but fall back to truncated text
      return String(text.prefix(maxSnippetLength))
    }

    let matchIndex = lowercasedText.distance(from: lowercasedText.startIndex, to: matchRange.lowerBound)
    let matchLength = term.count

    // Calculate context window
    let contextBefore = 20
    let contextAfter = maxSnippetLength - contextBefore - matchLength

    let startIndex = text.index(text.startIndex, offsetBy: max(0, matchIndex - contextBefore), limitedBy: text.endIndex) ?? text.startIndex
    let endIndex = text.index(matchRange.upperBound, offsetBy: contextAfter, limitedBy: text.endIndex) ?? text.endIndex

    var snippet = String(text[startIndex..<endIndex])

    // Add ellipsis if truncated
    if startIndex != text.startIndex {
      snippet = "..." + snippet
    }
    if endIndex != text.endIndex {
      snippet = snippet + "..."
    }

    // Replace newlines with spaces for display
    snippet = snippet.replacingOccurrences(of: "\n", with: " ")
      .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

    return snippet
  }

  /// Format search results for display.
  ///
  /// - Parameters:
  ///   - results: The search results to format.
  ///   - term: The search term (for display in header).
  ///   - toolName: The name of the root tool.
  ///   - screenWidth: The screen width for formatting.
  /// - Returns: A formatted string ready for display.
  static func formatResults(
    _ results: [SearchResult],
    term: String,
    toolName: String,
    screenWidth: Int
  ) -> String {
    guard !results.isEmpty else {
      return "No matches found for '\(term)'.\nTry '\(toolName) --help' for all options."
    }

    var output = "Found \(results.count) match\(results.count == 1 ? "" : "es") for '\(term)':\n"

    // Group by command vs argument matches
    let commandResults = results.filter { $0.isCommandMatch }
    let argumentResults = results.filter { !$0.isCommandMatch }

    // Display command matches
    if !commandResults.isEmpty {
      output += "\nCOMMANDS:\n"
      output += formatCommandResults(commandResults, screenWidth: screenWidth)
    }

    // Display argument matches
    if !argumentResults.isEmpty {
      output += "\nOPTIONS:\n"
      output += formatArgumentResults(argumentResults, screenWidth: screenWidth)
    }

    output += "\nUse '\(toolName) <command> --help' for detailed information."

    return output
  }

  /// Format command search results.
  private static func formatCommandResults(_ results: [SearchResult], screenWidth: Int) -> String {
    var output = ""

    for result in results {
      let pathString = result.commandPath.joined(separator: " ")
      output += "  \(pathString)\n"
      output += "    \(result.displayLabel)\n"
      if !result.contextSnippet.isEmpty {
        let wrapped = result.contextSnippet.wrapped(to: screenWidth, wrappingIndent: 6)
        output += "    \(wrapped.dropFirst(4))\n"
      }
      output += "\n"
    }

    return output
  }

  /// Format argument search results.
  private static func formatArgumentResults(_ results: [SearchResult], screenWidth: Int) -> String {
    var output = ""
    var lastPath = ""

    for result in results {
      let pathString = result.commandPath.joined(separator: " ")

      // Print command path header if changed
      if pathString != lastPath {
        output += "  \(pathString)\n"
        lastPath = pathString
      }

      // Format the match
      switch result.matchType {
      case .argumentName(let name, _):
        let wrapped = result.contextSnippet.wrapped(to: screenWidth, wrappingIndent: 6)
        output += "    \(name): \(wrapped.dropFirst(6))\n"
      case .argumentDescription(let name, _):
        let wrapped = result.contextSnippet.wrapped(to: screenWidth, wrappingIndent: 6)
        output += "    \(name): \(wrapped.dropFirst(6))\n"
      case .argumentValue(let name, _):
        output += "    \(name) (\(result.contextSnippet))\n"
      default:
        break
      }
    }

    return output
  }
}
