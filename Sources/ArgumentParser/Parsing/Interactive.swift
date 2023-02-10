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

#if canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#elseif canImport(CRT)
import CRT
#elseif canImport(WASILibc)
import WASILibc
#endif

extension CommandParser {
  /// Get input from the user's typing or from the parameters of the test.
  fileprivate mutating func getInput() -> String? {
    if lineStack != nil {
      // Extract the parameters used in the test.
      return lineStack!.removeLast()
    } else {
      // Get values from user input.
      return readLine()
    }
  }

  /// Try to fix parsing error by interacting with the user.
  /// - Parameters:
  ///   - error: A parsing error thrown by `lenientParse(_:subcommands:defaultCapturesAll:)`.
  ///   - split: A collection of parsed arguments which needs to be modified.
  /// - Returns: Whether the dialog resolve the error.
  mutating func canInteract(error: Error, split: inout SplitArguments) -> Bool {
    // Check if it's under test.
    if lineStack == nil {
      guard
        // Check if the command is executed in an interactive shell.
        isatty(STDOUT_FILENO) == 1, isatty(STDIN_FILENO) == 1
      else { return false }
    }
    guard rootCommand.configuration.shouldPromptForMissing else { return false }
    guard let error = error as? ParserError else { return false }
    guard case let .missingValueForOption(inputOrigin, name) = error else { return false }

    let input = ask("? Please enter value for '\(name.synopsisString)': ",
                    getInput: { getInput() })

    let inputIndex = inputOrigin.elements.first!.baseIndex! + 1
    split._elements.insert(.init(value: .value(input),
                                 index: .init(inputIndex: .init(rawValue: inputIndex))),
                           at: inputIndex)

    for index in (inputIndex + 1) ..< split.count {
      split._elements[index].index = .init(inputIndex: .init(rawValue: index))
    }

    split.originalInput.insert(input, at: inputIndex)

    return true
  }

  /// Try to fix decoding error by interacting with the user.
  /// - Parameters:
  ///   - error: A decoding error thrown by `ParsableCommand.init(from:)`.
  ///   - arguments: A nested tree of argument definitions which can provide modification method.
  ///   - values: The resulting values after parsing the arguments which needs to be modified.
  /// - Returns: Whether the dialog resolve the error.
  mutating func canInteract(error: Error, arguments: ArgumentSet, values: inout ParsedValues) -> Bool {
    // Check if it's under test.
    if lineStack == nil {
      guard
        // Check if the command is executed in an interactive shell.
        isatty(STDOUT_FILENO) == 1, isatty(STDIN_FILENO) == 1
      else { return false }
    }
    guard rootCommand.configuration.shouldPromptForMissing else { return false }
    guard let error = error as? ParserError else { return false }

    switch error {
    case let .noValue(forKey: key):
      let label = key.name
      guard label != "generateCompletionScript" else { break }

      // Retrieve the correct `ArgumentDefinition` for the required transformation
      // before storing the new value received from the user.
      let args = arguments.filter { $0.help.keys.contains(key) }
      let possibilities: [String] = args.compactMap {
        $0.help.visibility.base == .default
          ? $0.nonOptional.synopsis
          : nil
      }

      if possibilities.count == 1 {
        // Missing expected argument
        let definition = args.first!
        guard case let .unary(update) = definition.update else { break }
        let name = definition.names.first
        let updateBy: (String) throws -> Void = { string in
          try update(InputOrigin(elements: [.interactive]), name, string, &values)
        }

        // All possible strings that can be converted to value
        // of this CaseIterable enum type.
        let allValues = definition.help.allValues
        if allValues.isEmpty {
          storeNormalValues(label: label, updateBy: updateBy, arguments: arguments)
        } else {
          let selected = choose("? Please select '\(label)': ",
                                from: allValues, getInput: { self.getInput() })
          let strs = selected.map { allValues[$0] }
          for str in strs {
            try! update(InputOrigin(elements: [.interactive]), name, str, &values)
          }

          if values.elements[InputKey(name: label, parent: nil)]!.value is [Any] {
            print("You select '\(strs.joined(separator: "', '"))'.\n")
          } else {
            print("You select '\(strs.last!)'.\n")
          }
        }
      } else {
        // Enumerable Flag
        let selected = choose("? Please select '\(label)': ",
                              from: possibilities, getInput: { self.getInput() })
        let strs = selected.map { possibilities[$0] }
        for str in strs {
          let definition = args.first { str == "\($0)" }!
          guard case let .nullary(update) = definition.update else { continue }
          let name = definition.names.first
          do {
            try update(InputOrigin(elements: [.interactive]), name, &values)
          } catch {
            print("You select '\(strs[0])'.\n")
            return true
          }
        }

        print("You select '\(strs.joined(separator: "', '"))'.\n")
      }

      return true

    default: break
    }

    return false
  }

  fileprivate mutating func storeNormalValues(
    label: String,
    updateBy: (String) throws -> Void,
    arguments: ArgumentSet
  ) {
    let strs = ask("? Please enter '\(label)': ",
                   type: [String].self, getInput: { self.getInput() })
    for str in strs {
      do {
        try updateBy(str)
      } catch {
        // Handle ParserError
        guard
          let error = error as? ParserError,
          case let .unableToParseValue(_, _, original, _, _) = error
        else { return }
        let generator = ErrorMessageGenerator(arguments: arguments, error: error)
        let description = generator.makeErrorMessage() ?? error.localizedDescription
        print("Error: " + description + ".\n")
        replaceInvalidValue(original: original, updateBy: updateBy, arguments: arguments)
      }
    }
  }

  fileprivate mutating func replaceInvalidValue(
    original: String,
    updateBy: (String) throws -> Void,
    arguments: ArgumentSet
  ) {
    let input = ask("? Please replace '\(original)': ", getInput: { self.getInput() })
    do {
      try updateBy(input)
    } catch {
      // Handle ParserError
      guard
        let error = error as? ParserError,
        case let .unableToParseValue(_, _, original, _, _) = error
      else { return }
      let generator = ErrorMessageGenerator(arguments: arguments, error: error)
      let description = generator.makeErrorMessage() ?? error.localizedDescription
      print("Error: " + description + ".\n")
      replaceInvalidValue(original: original, updateBy: updateBy, arguments: arguments)
    }
  }
}
