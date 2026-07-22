//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

internal import Foundation

/// Expands response file arguments (@file) into their constituent arguments.
///
/// Response files allow users to specify command-line arguments in files,
/// which is useful for commands with many arguments or for reusable argument sets.
internal struct ResponseFileExpander {
  /// The prefix used to identify response file arguments.
  let prefix: Character

  /// Maximum nesting depth for response files.
  let maxNestingDepth: Int

  /// Tracks currently processing files to detect recursion.
  private var processingStack: [URL] = []

  /// Initializer.
  init(prefix: Character, maxNestingDepth: Int = 32) {
    self.prefix = prefix
    self.maxNestingDepth = maxNestingDepth
  }

  /// The result of expanding response file arguments.
  ///
  /// `arguments[i]` is a single expanded argument together with the
  /// include chain that produced it. The chain is ordered innermost-first:
  /// index 0 is the file/argv that the argument literally lives in; the
  /// last entry is always `.argv(_)`.
  ///
  /// `hasResponseFile` reflects whether the *original* input array
  /// contained at least one `@file` reference.
  typealias ExpansionResult = (
    arguments: [ExpandedArgument],
    hasResponseFile: Bool
  )

  /// One expanded argument together with the include chain that produced it.
  ///
  /// See `ExpansionResult` for chain ordering.
  ///
  /// `wasQuoted` is `true` when the argument came from a token that was
  /// wholly or partly enclosed in quotes inside a response file. The
  /// argument parser uses this to force such tokens to be treated as
  /// literal values, so that a response-file line like `"--not-a-flag"`
  /// lands as a positional value instead of being interpreted as an
  /// option — mirroring how a shell would pass a quoted argument through
  /// to a program.
  struct ExpandedArgument: Equatable {
    var value: String
    var chain: [InputOrigin.ResponseFileStep]
    var wasQuoted: Bool = false
  }

  /// Expands response file arguments in the input array.
  /// - Parameter arguments: The input arguments that may contain response file references
  /// - Returns: The expanded arguments (each paired with its include
  ///   chain), plus a flag indicating whether any `@file` reference was
  ///   present in the original input.
  /// - Throws: ResponseFileError if file operations fail or recursion is detected
  mutating func expandArguments(_ arguments: [String]) throws
    -> ExpansionResult
  {
    var result: [ExpandedArgument] = []
    var hasResponseFile = false

    for (argvIndex, argument) in arguments.enumerated() {
      if isResponseFileArgument(argument) {
        hasResponseFile = true
        guard let fileName = extractResponseFileName(argument) else {
          result.append(
            .init(value: argument, chain: [.argv(index: argvIndex)]))
          continue
        }

        // Check nesting depth
        if processingStack.count >= maxNestingDepth {
          throw ResponseFileError.maxNestingDepthExceeded(maxNestingDepth)
        }

        // Resolve relative paths relative to current working directory
        let resolvedURL = resolveFileURL(fileName)

        // Check for recursion
        if processingStack.contains(resolvedURL) {
          throw ResponseFileError.recursiveInclude(resolvedURL)
        }

        // Read and expand the file
        processingStack.append(resolvedURL)
        defer { processingStack.removeLast() }

        let expanded = try expandResponseFile(
          at: resolvedURL, parentChain: [.argv(index: argvIndex)])
        result.append(contentsOf: expanded)
      } else {
        result.append(
          .init(value: argument, chain: [.argv(index: argvIndex)]))
      }
    }

    return (result, hasResponseFile)
  }

  /// Determines if an argument is a response file reference.
  /// - Parameter argument: The argument to check
  /// - Returns: True if the argument starts with the response file prefix
  func isResponseFileArgument(_ argument: String) -> Bool {
    guard argument.count > prefix.utf8.count else { return false }
    guard argument.hasPrefix("\(prefix)") else { return false }

    // Check for literal escaping ('<prefix><prefix>file' becomes '<prefix>file' literal)
    if argument.hasPrefix("\(self.prefix)\(self.prefix)") {
      return false
    }

    // Must have a filename after the prefix
    let fileName = String(argument.dropFirst(prefix.utf8.count))
    return !fileName.isEmpty
  }

  /// Extracts the filename from a response file argument.
  /// - Parameter argument: The response file argument (e.g., "@file.txt")
  /// - Returns: The filename portion, or nil if not a valid response file argument
  func extractResponseFileName(_ argument: String) -> String? {
    guard isResponseFileArgument(argument) else { return nil }
    return String(argument.dropFirst(prefix.utf8.count))
  }

  /// Parses the contents of a response file.
  /// - Parameters:
  ///   - content: The file content to parse
  ///   - fileURL: The file URL (for error reporting and relative-path
  ///     resolution of nested `@file` references)
  ///   - parentChain: The chain of includes that led to this file, ordered
  ///     innermost (caller's file/line) first. For top-level parsing this
  ///     is typically `[.argv(index:)]`.
  /// - Returns: The parsed arguments, each paired with its include chain.
  /// - Throws: ResponseFileError if parsing fails
  mutating func parseFileContent(
    _ content: String,
    fileURL: URL,
    parentChain: [InputOrigin.ResponseFileStep] = []
  ) throws -> [ExpandedArgument] {
    let filePath = fileURL.path

    // Whole-file tokenization: quote state carries across newlines, so
    // a token that opens on one line and closes on a later line lands
    // as a single value with the intervening newlines preserved.
    let tokens = tokenizeContent(content)

    var result: [ExpandedArgument] = []
    for token in tokens {
      let tokenChain: [InputOrigin.ResponseFileStep] =
        [.file(path: filePath, line: token.line)] + parentChain
      let arg = token.value

      if token.wasQuoted {
        // Quoted tokens are always literal — quoting is the escape
        // mechanism for values that happen to start with the response
        // file prefix.
        result.append(
          .init(value: arg, chain: tokenChain, wasQuoted: true))
      } else if arg.hasPrefix("\(self.prefix)\(self.prefix)") {
        // Literal prefix escape: `@@file` -> `@file`, `++file` -> `+file`.
        result.append(
          .init(value: String(arg.dropFirst(1)), chain: tokenChain))
      } else if isResponseFileArgument(arg) {
        guard let fileName = extractResponseFileName(arg) else {
          result.append(.init(value: arg, chain: tokenChain))
          continue
        }

        let resolvedURL = resolveFileURL(fileName, relativeTo: fileURL)

        if processingStack.contains(resolvedURL) {
          throw ResponseFileError.recursiveInclude(resolvedURL)
        }

        if processingStack.count >= maxNestingDepth {
          throw ResponseFileError.maxNestingDepthExceeded(maxNestingDepth)
        }

        processingStack.append(resolvedURL)
        defer { processingStack.removeLast() }

        let nested = try expandResponseFile(
          at: resolvedURL, parentChain: tokenChain)
        result.append(contentsOf: nested)
      } else {
        result.append(.init(value: arg, chain: tokenChain))
      }
    }

    return result
  }

  /// Strips comments from a line, respecting quoted strings.
  /// - Parameter line: The line to process
  /// - Returns: The line with comments removed
  func stripComment(_ line: String) -> String {
    var result = ""
    var inDoubleQuotes = false
    var inSingleQuotes = false
    var escaped = false

    for char in line {
      if escaped {
        result.append(char)
        escaped = false
        continue
      }

      switch char {
      case "\\":
        if inDoubleQuotes {
          escaped = true
        }
        result.append(char)
      case "\"":
        if !inSingleQuotes {
          inDoubleQuotes.toggle()
        }
        result.append(char)
      case "'":
        if !inDoubleQuotes {
          inSingleQuotes.toggle()
        }
        result.append(char)
      case "#":
        if !inDoubleQuotes && !inSingleQuotes {
          // Found unquoted comment, stop processing
          return result.trimmingCharacters(in: .whitespaces)
        }
        result.append(char)
      default:
        result.append(char)
      }
    }

    return result.trimmingCharacters(in: .whitespaces)
  }
}

// MARK: - Error Types

extension ResponseFileExpander {
  enum ResponseFileError: Error, CustomStringConvertible {
    case fileNotFound(URL)
    case readError(URL, Error)
    case malformedContent(URL, String)
    case recursiveInclude(URL)
    case maxNestingDepthExceeded(Int)

    var description: String {
      switch self {
      case .fileNotFound(let url):
        return "Response file not found: \(url.path)"
      case .readError(let url, let error):
        return
          "Failed to read response file '\(url.path)': \(error.localizedDescription)"
      case .malformedContent(let url, let message):
        return "Malformed content in response file '\(url.path)': \(message)"
      case .recursiveInclude(let url):
        return "Recursive response file inclusion detected: \(url.path)"
      case .maxNestingDepthExceeded(let depth):
        return "Maximum nesting depth (\(depth)) exceeded for response files"
      }
    }
  }
}

// MARK: - Private Implementation

extension ResponseFileExpander {

  /// Expands a response file by reading and parsing its contents.
  /// - Parameters:
  ///   - fileURL: The URL of the response file
  ///   - parentChain: The chain of includes that led to this file, ordered
  ///     innermost (caller's file/line) first.
  /// - Returns: The expanded arguments, each paired with its include chain.
  /// - Throws: ResponseFileError if file operations fail
  fileprivate mutating func expandResponseFile(
    at fileURL: URL,
    parentChain: [InputOrigin.ResponseFileStep]
  ) throws -> [ExpandedArgument] {
    // Check if file exists
    guard FileManager.default.fileExists(atPath: fileURL.path) else {
      throw ResponseFileError.fileNotFound(fileURL)
    }

    // Read file content
    let content: String
    do {
      content = try String(contentsOf: fileURL, encoding: .utf8)
    } catch {
      throw ResponseFileError.readError(fileURL, error)
    }

    // Parse and expand content
    return try parseFileContent(
      content, fileURL: fileURL, parentChain: parentChain)
  }

  /// Resolves a file name to an absolute `URL`, handling relative paths.
  ///
  /// - Parameters:
  ///   - fileName: The file name to resolve
  ///   - parentURL: Optional parent file `URL` for relative resolution
  /// - Returns: The resolved absolute URL
  fileprivate func resolveFileURL(
    _ fileName: String,
    relativeTo parentURL: URL? = nil
  ) -> URL {
    // If already absolute, use as-is
    if Self.isAbsolutePath(fileName) {
      return URL(fileURLWithPath: fileName)
    }

    // If we have a parent file, make relative to its directory
    if let parentURL = parentURL {
      return
        parentURL
        .deletingLastPathComponent()
        .appendingPathComponent(fileName)
    }

    // Otherwise, relative to current working directory
    return URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
      .appendingPathComponent(fileName)
  }

  /// Returns `true` if `path` is an absolute filesystem path.
  ///
  /// On POSIX, that means it starts with `/`. On Windows, that includes
  /// drive-rooted paths (`C:\...` / `C:/...`), UNC paths (`\\server\...`),
  /// and drive-relative-absolute paths (starting with `\` or `/`).
  fileprivate static func isAbsolutePath(_ path: String) -> Bool {
    #if os(Windows)
    if path.hasPrefix("/") || path.hasPrefix("\\") {
      return true
    }
    // Drive-rooted: "C:\" or "C:/".
    let chars = Array(path)
    if chars.count >= 3,
      chars[0].isLetter,
      chars[1] == ":",
      chars[2] == "\\" || chars[2] == "/"
    {
      return true
    }
    return false
    #else
    return path.hasPrefix("/")
    #endif
  }

  /// One token produced by `tokenizeContent`.
  ///
  /// `wasQuoted` records whether the raw token contained any quoted
  /// portion. Quoted tokens are passed through verbatim as literal
  /// values — the response-file prefix (`@`) is not interpreted for
  /// them, so `"@name"` and `'@name'` do NOT trigger a nested lookup.
  ///
  /// `line` is the 1-indexed line number where the token started, used
  /// for building the include chain and for error messages.
  fileprivate struct TokenizedArgument {
    var value: String
    var wasQuoted: Bool
    var line: Int
  }

  /// Tokenizes the entire content of a response file in a single pass.
  ///
  /// Behaviors implemented:
  ///
  /// - Double-quoted segments allow C-style backslash escapes
  ///   (`\n`, `\t`, `\r`, `\\`, `\"`); any other escape sequence is
  ///   preserved verbatim (backslash + character).
  /// - Single-quoted segments are literal — nothing inside them is
  ///   interpreted, including backslashes.
  /// - Adjacent quoted or unquoted segments with no whitespace between
  ///   them concatenate into a single token, so `"foo""bar"`, `a""a`,
  ///   and `''''` all form a single token.
  /// - An empty quoted segment (`""` or `''`) still produces an empty
  ///   token, which lets callers pass an empty string through a
  ///   response file.
  /// - An unterminated quote is implicitly closed at end-of-file; the
  ///   accumulated content becomes the final token.
  /// - A `#` outside of any quoted segment starts a comment that runs
  ///   to the next newline.
  /// - A newline **outside** a quoted segment separates tokens; a
  ///   newline **inside** a quoted segment is preserved as a literal
  ///   part of the token's value.
  fileprivate func tokenizeContent(_ content: String) -> [TokenizedArgument] {
    var result: [TokenizedArgument] = []
    var currentArg = ""
    var currentWasQuoted = false
    var hasContent = false
    var currentTokenLine = 1
    var lineNumber = 1
    var inDoubleQuotes = false
    var inSingleQuotes = false
    var escaped = false
    var inLineComment = false

    for char in content {
      if inLineComment {
        if char == "\n" {
          inLineComment = false
          lineNumber += 1
        }
        continue
      }

      if escaped {
        // Only reachable inside double quotes. Process a C-style escape
        // sequence and consume both the backslash and this character.
        switch char {
        case "n":
          currentArg.append("\n")
        case "t":
          currentArg.append("\t")
        case "r":
          currentArg.append("\r")
        case "\\":
          currentArg.append("\\")
        case "\"":
          currentArg.append("\"")
        default:
          // Unknown escape — preserve both characters verbatim so
          // callers see the same bytes the file contained.
          currentArg.append("\\")
          currentArg.append(char)
        }
        if !hasContent {
          currentTokenLine = lineNumber
          hasContent = true
        }
        escaped = false
        continue
      }

      let inQuotes = inDoubleQuotes || inSingleQuotes

      switch char {
      case "\\":
        if inDoubleQuotes {
          escaped = true
        } else {
          // Outside double quotes (including inside single quotes),
          // backslash is a literal character.
          if !hasContent {
            currentTokenLine = lineNumber
            hasContent = true
          }
          currentArg.append(char)
        }
      case "\"":
        if inSingleQuotes {
          if !hasContent {
            currentTokenLine = lineNumber
            hasContent = true
          }
          currentArg.append(char)
        } else {
          if !hasContent {
            currentTokenLine = lineNumber
            hasContent = true
          }
          inDoubleQuotes.toggle()
          currentWasQuoted = true
        }
      case "'":
        if inDoubleQuotes {
          if !hasContent {
            currentTokenLine = lineNumber
            hasContent = true
          }
          currentArg.append(char)
        } else {
          if !hasContent {
            currentTokenLine = lineNumber
            hasContent = true
          }
          inSingleQuotes.toggle()
          currentWasQuoted = true
        }
      case "#":
        if inQuotes {
          if !hasContent {
            currentTokenLine = lineNumber
            hasContent = true
          }
          currentArg.append(char)
        } else {
          if hasContent {
            result.append(
              .init(
                value: currentArg,
                wasQuoted: currentWasQuoted,
                line: currentTokenLine))
            currentArg = ""
            currentWasQuoted = false
            hasContent = false
          }
          inLineComment = true
        }
      case "\n":
        if inQuotes {
          if !hasContent {
            currentTokenLine = lineNumber
            hasContent = true
          }
          currentArg.append(char)
        } else if hasContent {
          result.append(
            .init(
              value: currentArg,
              wasQuoted: currentWasQuoted,
              line: currentTokenLine))
          currentArg = ""
          currentWasQuoted = false
          hasContent = false
        }
        lineNumber += 1
      case " ", "\t":
        if inQuotes {
          if !hasContent {
            currentTokenLine = lineNumber
            hasContent = true
          }
          currentArg.append(char)
        } else if hasContent {
          result.append(
            .init(
              value: currentArg,
              wasQuoted: currentWasQuoted,
              line: currentTokenLine))
          currentArg = ""
          currentWasQuoted = false
          hasContent = false
        }
      default:
        if !hasContent {
          currentTokenLine = lineNumber
          hasContent = true
        }
        currentArg.append(char)
      }
    }

    // An unterminated quote is implicitly closed at end-of-file.
    // Whatever was accumulated becomes the final token — including the
    // case where nothing was accumulated (a bare `'` or `"` at EOF
    // still produces one empty argument).
    if hasContent {
      result.append(
        .init(
          value: currentArg,
          wasQuoted: currentWasQuoted,
          line: currentTokenLine))
    }

    return result
  }
}
