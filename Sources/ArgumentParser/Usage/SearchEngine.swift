//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
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

/// ANSI terminal formatting codes.
enum ANSICode {
  /// Start bold text.
  static let bold = "\u{001B}[1m"
  /// Reset all formatting.
  static let reset = "\u{001B}[0m"

  /// Highlight all occurrences of a search term in text (case-insensitive).
  ///
  /// - Parameters:
  ///   - text: The text to search within.
  ///   - term: The term to highlight.
  ///   - enabled: Whether to actually apply formatting.
  /// - Returns: The text with all matches highlighted.
  static func highlightMatches(
    in text: String, matching term: String, enabled: Bool
  ) -> String {
    guard enabled && !term.isEmpty else { return text }

    let lowercasedText = text.lowercased()
    let lowercasedTerm = term.lowercased()

    var result = ""
    var searchStartIndex = text.startIndex

    while searchStartIndex < text.endIndex {
      let searchRange = searchStartIndex..<text.endIndex
      let lowercasedSearchRange = lowercasedText[searchRange]

      if let matchRange = lowercasedSearchRange.range(of: lowercasedTerm) {
        // Convert the match range from lowercased text to original text
        let matchStart = matchRange.lowerBound
        let matchEnd = matchRange.upperBound

        // Add text before the match
        result += text[searchStartIndex..<matchStart]

        // Add the matched text with highlighting
        let matchedText = text[matchStart..<matchEnd]
        result += "\(bold)\(matchedText)\(reset)"

        // Move past this match
        searchStartIndex = matchEnd
      } else {
        // No more matches, add the rest
        result += text[searchStartIndex...]
        break
      }
    }

    return result
  }
}

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
    traverseTree(
      node: rootNode, currentPath: commandStack.map { $0._commandName },
      term: lowercasedTerm, results: &results)

    // Sort results: command matches first, then argument matches
    return results.sorted { lhs, rhs in
      if lhs.isCommandMatch != rhs.isCommandMatch {
        return lhs.isCommandMatch
      }
      return lhs.commandPath.joined(separator: " ")
        < rhs.commandPath.joined(separator: " ")
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

    // Track if we've found any match for this command
    var matchFound = false
    var bestMatchType: SearchResult.MatchType?
    var bestSnippet = ""

    // Check 1: Search command name (highest priority)
    let commandName = command._commandName
    if commandName.lowercased().contains(term) {
      bestMatchType = .commandName(matchedText: commandName)
      bestSnippet =
        configuration.abstract.isEmpty ? commandName : configuration.abstract
      matchFound = true
    }

    // Check 2: Search command aliases (if name didn't match)
    if !matchFound {
      for alias in configuration.aliases {
        if alias.lowercased().contains(term) {
          bestMatchType = .commandName(matchedText: alias)
          bestSnippet =
            configuration.abstract.isEmpty ? alias : configuration.abstract
          matchFound = true
          break
        }
      }
    }

    // Check 3: Search command abstract (if name/aliases didn't match)
    if !matchFound && !configuration.abstract.isEmpty
      && configuration.abstract.lowercased().contains(term)
    {
      let snippet = extractSnippet(from: configuration.abstract, around: term)
      bestMatchType = .commandDescription(matchedText: snippet)
      bestSnippet = snippet
      matchFound = true
    }

    // Check 4: Search command discussion (if nothing else matched)
    if !matchFound && !configuration.discussion.isEmpty
      && configuration.discussion.lowercased().contains(term)
    {
      let snippet = extractSnippet(from: configuration.discussion, around: term)
      bestMatchType = .commandDescription(matchedText: snippet)
      bestSnippet = snippet
      matchFound = true
    }

    // Add result if we found a match
    if matchFound, let matchType = bestMatchType {
      results.append(
        SearchResult(
          commandPath: currentPath,
          matchType: matchType,
          contextSnippet: bestSnippet
        ))
    }

    // Search arguments
    searchArguments(
      command: command, commandPath: currentPath, term: term, results: &results)

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
      guard arg.help.visibility.isAtLeastAsVisible(as: visibility) else {
        continue
      }

      let names = arg.names
      let displayNames: String
      if names.isEmpty {
        // Positional argument - use computed value name
        displayNames = "<\(arg.valueName)>"
      } else {
        displayNames = names.map { $0.synopsisString }.joined(separator: ", ")
      }

      // Track if we've found any match for this argument
      var matchFound = false
      var bestMatchType: SearchResult.MatchType?
      var bestSnippet = ""

      // Check 1: Search argument names (highest priority)
      if names.isEmpty {
        // Positional argument - check if term matches value name
        if arg.valueName.lowercased().contains(term) {
          bestMatchType = .argumentName(
            name: displayNames, matchedText: arg.valueName)
          bestSnippet = arg.help.abstract
          matchFound = true
        }
      } else {
        // Named arguments - check all names
        for name in names {
          let nameString = name.synopsisString
          if nameString.lowercased().contains(term) {
            bestMatchType = .argumentName(
              name: displayNames, matchedText: nameString)
            bestSnippet = arg.help.abstract
            matchFound = true
            break
          }
        }
      }

      // Check 2: Search argument abstract (if name didn't match)
      if !matchFound && !arg.help.abstract.isEmpty
        && arg.help.abstract.lowercased().contains(term)
      {
        let snippet = extractSnippet(from: arg.help.abstract, around: term)
        bestMatchType = .argumentDescription(
          name: displayNames, matchedText: snippet)
        bestSnippet = snippet
        matchFound = true
      }

      // Check 3: Search argument discussion (if nothing else matched)
      if !matchFound,
        case .staticText(let discussionText) = arg.help.discussion,
        !discussionText.isEmpty && discussionText.lowercased().contains(term)
      {
        let snippet = extractSnippet(from: discussionText, around: term)
        bestMatchType = .argumentDescription(
          name: displayNames, matchedText: snippet)
        bestSnippet = snippet
        matchFound = true
      }

      // Check 4: Search possible values (if nothing else matched)
      if !matchFound {
        for value in arg.help.allValueStrings where !value.isEmpty {
          if value.lowercased().contains(term) {
            bestMatchType = .argumentValue(
              name: displayNames, matchedText: value)
            bestSnippet = "possible value: \(value)"
            matchFound = true
            break
          }
        }
      }

      // Check 5: Search default value (if nothing else matched)
      if !matchFound,
        let defaultValue = arg.help.defaultValue,
        !defaultValue.isEmpty && defaultValue.lowercased().contains(term)
      {
        bestMatchType = .argumentValue(
          name: displayNames, matchedText: defaultValue)
        bestSnippet = "default: \(defaultValue)"
        matchFound = true
      }

      // Add result if we found a match
      if matchFound, let matchType = bestMatchType {
        results.append(
          SearchResult(
            commandPath: commandPath,
            matchType: matchType,
            contextSnippet: bestSnippet
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
  private func extractSnippet(from text: String, around term: String) -> String
  {
    let maxSnippetLength = 80
    let lowercasedText = text.lowercased()

    guard let matchRange = lowercasedText.range(of: term) else {
      // Shouldn't happen, but fall back to truncated text
      return String(text.prefix(maxSnippetLength))
    }

    let matchIndex = lowercasedText.distance(
      from: lowercasedText.startIndex, to: matchRange.lowerBound)
    let matchLength = term.count

    // Calculate context window
    let contextBefore = 20
    let contextAfter = maxSnippetLength - contextBefore - matchLength

    let startIndex =
      text.index(
        text.startIndex, offsetBy: max(0, matchIndex - contextBefore),
        limitedBy: text.endIndex) ?? text.startIndex
    let endIndex =
      text.index(
        matchRange.upperBound, offsetBy: contextAfter, limitedBy: text.endIndex)
      ?? text.endIndex

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
  ///   - useHighlighting: Use ANSI codes to highlight results. If not set the results will be highlighted if the output is a terminal.
  /// - Returns: A formatted string ready for display.
  static func formatResults(
    _ results: [SearchResult],
    term: String,
    toolName: String,
    screenWidth: Int,
    useHighlighting: Bool = Platform.isStdoutTerminal
  ) -> String {
    guard !results.isEmpty else {
      return
        "No matches found for '\(term)'.\nTry '\(toolName) --help' for all options."
    }

    //let useHighlighting = useHighlighting ?? Platform.isStdoutTerminal

    var output =
      "Found \(results.count) match\(results.count == 1 ? "" : "es") for '\(term)':\n"

    // Group by command vs argument matches
    let commandResults = results.filter { $0.isCommandMatch }
    let argumentResults = results.filter { !$0.isCommandMatch }

    // Display command matches
    if !commandResults.isEmpty {
      output += "\nCOMMANDS:\n"
      output += formatCommandResults(
        commandResults, term: term, screenWidth: screenWidth,
        useHighlighting: useHighlighting)
    }

    // Display argument matches
    if !argumentResults.isEmpty {
      output += "\nOPTIONS:\n"
      output += formatArgumentResults(
        argumentResults, term: term, screenWidth: screenWidth,
        useHighlighting: useHighlighting)
    }

    output += "\nUse '\(toolName) <command> --help' for detailed information."

    return output
  }

  /// Format command search results.
  private static func formatCommandResults(
    _ results: [SearchResult],
    term: String,
    screenWidth: Int,
    useHighlighting: Bool
  ) -> String {
    var output = ""

    for result in results {
      let pathString = result.commandPath.joined(separator: " ")

      switch result.matchType {
      case .commandName(let matched):
        // For command name matches, show path with highlighted name and description
        let highlightedPath = ANSICode.highlightMatches(
          in: pathString, matching: term, enabled: useHighlighting)
        output += "  \(highlightedPath)\n"

        if !result.contextSnippet.isEmpty && result.contextSnippet != matched {
          let highlightedSnippet = ANSICode.highlightMatches(
            in: result.contextSnippet, matching: term, enabled: useHighlighting)
          let wrapped = highlightedSnippet.wrapped(
            to: screenWidth, wrappingIndent: 6)
          output += "    \(wrapped.dropFirst(6))\n"
        }

      case .commandDescription:
        // For description matches, show path and the matching snippet with highlights
        output += "  \(pathString)\n"
        let highlightedSnippet = ANSICode.highlightMatches(
          in: result.contextSnippet, matching: term, enabled: useHighlighting)
        let wrapped = highlightedSnippet.wrapped(
          to: screenWidth, wrappingIndent: 6)
        output += "    \(wrapped.dropFirst(6))\n"

      default:
        break
      }

      output += "\n"
    }

    return output
  }

  /// Format argument search results.
  private static func formatArgumentResults(
    _ results: [SearchResult],
    term: String,
    screenWidth: Int,
    useHighlighting: Bool
  ) -> String {
    var output = ""
    var lastPath = ""

    for result in results {
      let pathString = result.commandPath.joined(separator: " ")

      // Print command path header if changed
      if pathString != lastPath {
        output += "  \(pathString)\n"
        lastPath = pathString
      }

      // Format the match with highlighting
      switch result.matchType {
      case .argumentName(let name, _):
        let highlightedName = ANSICode.highlightMatches(
          in: name, matching: term, enabled: useHighlighting)
        let highlightedSnippet = ANSICode.highlightMatches(
          in: result.contextSnippet, matching: term, enabled: useHighlighting)
        let wrapped = highlightedSnippet.wrapped(
          to: screenWidth, wrappingIndent: 6)
        output += "    \(highlightedName): \(wrapped.dropFirst(6))\n"

      case .argumentDescription(let name, _):
        let highlightedSnippet = ANSICode.highlightMatches(
          in: result.contextSnippet, matching: term, enabled: useHighlighting)
        let wrapped = highlightedSnippet.wrapped(
          to: screenWidth, wrappingIndent: 6)
        output += "    \(name): \(wrapped.dropFirst(6))\n"

      case .argumentValue(let name, _):
        let highlightedSnippet = ANSICode.highlightMatches(
          in: result.contextSnippet, matching: term, enabled: useHighlighting)
        output += "    \(name) (\(highlightedSnippet))\n"

      default:
        break
      }
    }

    return output
  }
}
