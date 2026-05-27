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
  let prefix: String

  /// Maximum nesting depth for response files.
  let maxNestingDepth: Int

  /// Tracks currently processing files to detect recursion.
  private var processingStack: [String] = []

  /// Initializer.
  init(prefix: String = "@", maxNestingDepth: Int = 32) {
    self.prefix = prefix
    self.maxNestingDepth = maxNestingDepth
  }

  /// Expands response file arguments in the input array.
  /// - Parameter arguments: The input arguments that may contain response file references
  /// - Returns: The expanded arguments with response files replaced by their contents
  /// - Throws: ResponseFileError if file operations fail or recursion is detected
  mutating func expandArguments(_ arguments: [String]) throws -> [String] {
    var result: [String] = []

    for argument in arguments {
      if isResponseFileArgument(argument) {
        guard let fileName = extractResponseFileName(argument) else {
          result.append(argument)
          continue
        }

        // Check nesting depth
        if processingStack.count >= maxNestingDepth {
          throw ResponseFileError.maxNestingDepthExceeded(maxNestingDepth)
        }

        // Resolve relative paths relative to current working directory
        let resolvedPath = resolveFilePath(fileName)

        // Check for recursion
        if processingStack.contains(resolvedPath) {
          throw ResponseFileError.recursiveInclude(resolvedPath)
        }

        // Read and expand the file
        processingStack.append(resolvedPath)
        defer { processingStack.removeLast() }

        let expandedArgs = try expandResponseFile(at: resolvedPath)
        result.append(contentsOf: expandedArgs)
      } else {
        result.append(argument)
      }
    }

    return result
  }

  /// Determines if an argument is a response file reference.
  /// - Parameter argument: The argument to check
  /// - Returns: True if the argument starts with the response file prefix
  func isResponseFileArgument(_ argument: String) -> Bool {
    guard argument.count > prefix.count else { return false }
    guard argument.hasPrefix(prefix) else { return false }

    // Check for literal escaping (@@file becomes @file literal)
    if prefix == "@" && argument.hasPrefix("@@") {
      return false
    }

    // Must have a filename after the prefix
    let fileName = String(argument.dropFirst(prefix.count))
    return !fileName.isEmpty
  }

  /// Extracts the filename from a response file argument.
  /// - Parameter argument: The response file argument (e.g., "@file.txt")
  /// - Returns: The filename portion, or nil if not a valid response file argument
  func extractResponseFileName(_ argument: String) -> String? {
    guard isResponseFileArgument(argument) else { return nil }
    return String(argument.dropFirst(prefix.count))
  }

  /// Parses the contents of a response file.
  /// - Parameters:
  ///   - content: The file content to parse
  ///   - filePath: The file path (for error reporting)
  /// - Returns: Array of parsed arguments
  /// - Throws: ResponseFileError if parsing fails
  mutating func parseFileContent(_ content: String, filePath: String) throws
    -> [String]
  {
    var result: [String] = []
    let lines = content.components(separatedBy: .newlines)

    for (lineNumber, line) in lines.enumerated() {
      let trimmedLine = line.trimmingCharacters(in: .whitespaces)

      // Skip empty lines and comments
      if trimmedLine.isEmpty || trimmedLine.hasPrefix("#") {
        continue
      }

      // Strip end-of-line comments
      let lineWithoutComments = stripComment(trimmedLine)
      if lineWithoutComments.trimmingCharacters(in: .whitespaces).isEmpty {
        continue
      }

      // Parse arguments from the line
      do {
        let lineArgs = try parseArgumentsFromLine(lineWithoutComments)

        // Recursively expand any nested response files
        for arg in lineArgs {
          if arg.hasPrefix("@@") {
            // Handle literal @ escaping (@@file becomes @file)
            result.append(String(arg.dropFirst(1)))
          } else if isResponseFileArgument(arg) {
            // Recursive response file expansion
            guard let fileName = extractResponseFileName(arg) else {
              result.append(arg)
              continue
            }

            let resolvedPath = resolveFilePath(fileName, relativeTo: filePath)

            // Check for recursion
            if processingStack.contains(resolvedPath) {
              throw ResponseFileError.recursiveInclude(resolvedPath)
            }

            // Check nesting depth
            if processingStack.count >= maxNestingDepth {
              throw ResponseFileError.maxNestingDepthExceeded(maxNestingDepth)
            }

            processingStack.append(resolvedPath)
            defer { processingStack.removeLast() }

            let nestedArgs = try expandResponseFile(at: resolvedPath)
            result.append(contentsOf: nestedArgs)
          } else {
            result.append(arg)
          }
        }
      } catch let error as ResponseFileError {
        // Re-throw ResponseFileError types (recursion, nesting depth) as-is
        throw error
      } catch {
        // Only wrap other parsing errors as malformed content
        throw ResponseFileError.malformedContent(
          filePath, "Line \(lineNumber + 1): \(error.localizedDescription)")
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

  /// Parses a quoted argument, handling escape sequences.
  /// - Parameter argument: The argument to parse (may or may not be quoted)
  /// - Returns: The unquoted/unescaped argument
  /// - Throws: ResponseFileError if quotes are malformed
  func parseQuotedArgument(_ argument: String) throws -> String {
    let trimmed = argument.trimmingCharacters(in: .whitespaces)

    // Handle double quotes
    if trimmed.hasPrefix("\"") && trimmed.hasSuffix("\"") && trimmed.count >= 2
    {
      let inner = String(trimmed.dropFirst().dropLast())
      return try unescapeString(inner, quote: "\"")
    }

    // Handle single quotes
    if trimmed.hasPrefix("'") && trimmed.hasSuffix("'") && trimmed.count >= 2 {
      let inner = String(trimmed.dropFirst().dropLast())
      return inner  // Single quotes don't process escapes
    }

    // Check for unclosed quotes
    if (trimmed.hasPrefix("\"") || trimmed.hasPrefix("'")) && trimmed.count >= 1
    {
      let quote = String(trimmed.prefix(1))
      if !trimmed.hasSuffix(quote) || trimmed.count < 2 {
        throw ResponseFileError.malformedContent(
          "", "Unclosed quote in argument: \(argument)")
      }
    }

    // Not quoted, return as-is
    return trimmed
  }
}

// MARK: - Error Types

extension ResponseFileExpander {
  enum ResponseFileError: Error, CustomStringConvertible {
    case fileNotFound(String)
    case readError(String, Error)
    case malformedContent(String, String)
    case recursiveInclude(String)
    case maxNestingDepthExceeded(Int)

    var description: String {
      switch self {
      case .fileNotFound(let path):
        return "Response file not found: \(path)"
      case .readError(let path, let error):
        return
          "Failed to read response file '\(path)': \(error.localizedDescription)"
      case .malformedContent(let path, let message):
        return "Malformed content in response file '\(path)': \(message)"
      case .recursiveInclude(let path):
        return "Recursive response file inclusion detected: \(path)"
      case .maxNestingDepthExceeded(let depth):
        return "Maximum nesting depth (\(depth)) exceeded for response files"
      }
    }
  }
}

// MARK: - Private Implementation

extension ResponseFileExpander {

  /// Expands a response file by reading and parsing its contents.
  /// - Parameter filePath: The path to the response file
  /// - Returns: The expanded arguments from the file
  /// - Throws: ResponseFileError if file operations fail
  fileprivate mutating func expandResponseFile(at filePath: String) throws
    -> [String]
  {
    let fileURL = URL(fileURLWithPath: filePath)

    // Check if file exists
    guard FileManager.default.fileExists(atPath: filePath) else {
      throw ResponseFileError.fileNotFound(filePath)
    }

    // Read file content
    let content: String
    do {
      content = try String(contentsOf: fileURL, encoding: .utf8)
    } catch {
      throw ResponseFileError.readError(filePath, error)
    }

    // Parse and expand content
    return try parseFileContent(content, filePath: filePath)
  }

  // Resolves a file path, handling relative paths.
  // - Parameters:
  //   - fileName: The file name to resolve
  //   - relativeTo: String? parent file path for relative resolution
  // - Returns: The resolved absolute path
  fileprivate func resolveFilePath(
    _ fileName: String,
    relativeTo parentPath: String? = nil
  ) -> String {
    // If already absolute, use as-is
    if fileName.hasPrefix("/") {
      return fileName
    }

    // If we have a parent file, make relative to its directory
    if let parentPath = parentPath {
      let parentURL = URL(fileURLWithPath: parentPath)
      let parentDir = parentURL.deletingLastPathComponent()
      return parentDir.appendingPathComponent(fileName).path
    }

    // Otherwise, relative to current working directory
    return URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
      .appendingPathComponent(fileName).path
  }

  /// Parses arguments from a single line, handling quotes and spaces.
  /// - Parameter line: The line to parse
  /// - Returns: Array of parsed arguments
  /// - Throws: ResponseFileError if parsing fails
  fileprivate func parseArgumentsFromLine(_ line: String) throws -> [String] {
    var arguments: [String] = []
    var currentArg = ""
    var inDoubleQuotes = false
    var inSingleQuotes = false
    var escaped = false

    for char in line {
      if escaped {
        currentArg.append(char)
        escaped = false
        continue
      }

      switch char {
      case "\\":
        if inDoubleQuotes {
          escaped = true
        } else {
          currentArg.append(char)
        }
      case "\"":
        if inSingleQuotes {
          currentArg.append(char)
        } else {
          inDoubleQuotes.toggle()
          currentArg.append(char)
        }
      case "'":
        if inDoubleQuotes {
          currentArg.append(char)
        } else {
          inSingleQuotes.toggle()
          currentArg.append(char)
        }
      case " ", "\t":
        if inDoubleQuotes || inSingleQuotes {
          currentArg.append(char)
        } else if !currentArg.isEmpty {
          arguments.append(try parseQuotedArgument(currentArg))
          currentArg = ""
        }
      default:
        currentArg.append(char)
      }
    }

    // Add final argument if present
    if !currentArg.isEmpty {
      arguments.append(try parseQuotedArgument(currentArg))
    }

    return arguments
  }

  /// Unescapes a string, processing escape sequences within quotes.
  /// - Parameters:
  ///   - string: The string to unescape
  ///   - quote: The quote character being processed
  /// - Returns: The unescaped string
  /// - Throws: ResponseFileError if escape sequences are malformed
  fileprivate func unescapeString(_ string: String, quote: String) throws
    -> String
  {
    var result = ""
    var escaped = false

    for char in string {
      if escaped {
        switch char {
        case "n":
          result.append("\n")
        case "t":
          result.append("\t")
        case "r":
          result.append("\r")
        case "\\":
          result.append("\\")
        case "\"" where quote == "\"":
          result.append("\"")
        default:
          // Unknown escape sequence, keep as literal
          result.append("\\")
          result.append(char)
        }
        escaped = false
      } else if char == "\\" {
        escaped = true
      } else {
        result.append(char)
      }
    }

    return result
  }
}
