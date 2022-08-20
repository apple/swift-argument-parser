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

extension CommandParser {
  /// Try to fix parsing error by interacting with the user.
  /// - Parameters:
  ///   - error: A parsing error thrown by `lenientParse(_:subcommands:defaultCapturesAll:)`.
  ///   - split: A collection of parsed arguments which needs to be modified.
  /// - Returns: Whether the dialog resolve the error.
  mutating func canInteract(error: Error, split: inout SplitArguments) -> Bool {
    guard rootCommand.configuration.shouldPromptForMissing else { return false }
    guard lineStack == nil || !lineStack!.isEmpty else { return false }
    guard let error = error as? ParserError else { return false }
    guard case let .missingValueForOption(inputOrigin, name) = error else { return false }

    print("? Please enter value for '\(name.synopsisString)': ", terminator: "")
    let input = getInput()

    let inputIndex = inputOrigin.elements.first!.baseIndex! + 1
    split._elements.insert(.init(value: .value(input!),
                                 index: .init(inputIndex: .init(rawValue: inputIndex))),
                           at: inputIndex)

    for index in (inputIndex + 1) ..< split.count {
      split._elements[index].index = .init(inputIndex: .init(rawValue: index))
    }

    split.originalInput.insert(input!, at: inputIndex)

    return true
  }

  /// Try to fix decoding error by interacting with the user.
  /// - Parameters:
  ///   - error: A decoding error thrown by `ParsableCommand.init(from:)`.
  ///   - arguments: A nested tree of argument definitions which can provide modification method.
  ///   - values: The resulting values after parsing the arguments which needs to be modified.
  /// - Returns: Whether the dialog resolve the error.
  mutating func canInteract(error: Error, arguments: ArgumentSet, values: inout ParsedValues) -> Bool {
    guard rootCommand.configuration.shouldPromptForMissing else { return false }
    guard lineStack == nil || !lineStack!.isEmpty else { return false }
    guard let error = error as? ParserError else { return false }

    switch error {
    case let .noValue(forKey: key):
      let label = key.rawValue
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
          allValues.enumerated().forEach { print("\($0 + 1). \($1)") }
          choose("? Please select '\(label)': ", choices: allValues)
            .forEach {
              try! update(InputOrigin(elements: [.interactive]), name, $0, &values)
            }
        }
      } else {
        // Enumerable Flag
        possibilities.enumerated().forEach { print("\($0 + 1). \($1)") }
        choose("? Please select '\(label)': ", choices: possibilities)
          .forEach { str in
            let definition = args.first { str == "\($0)" }!
            // TODO:
            guard case let .nullary(update) = definition.update else { return }
            let name = definition.names.first
            try! update(InputOrigin(elements: [.interactive]), name, &values)
          }
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
    print("? Please enter '\(label)': ", terminator: "")
    let strs = getInput()?.components(separatedBy: " ") ?? [""]

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
    print("? Please replace '\(original)': ", terminator: "")
    let input = getInput() ?? ""

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

  fileprivate mutating func choose(_ prompt: String, choices: [String]) -> [String] {
    print(prompt)
    let nums = getInput()?.components(separatedBy: " ") ?? [""]

    var strs: [String] = []
    let range = 1 ... choices.count
    for num in nums {
      guard let index = Int(num) else {
        print("Error: '\(num)' is not a serial number.\n")
        return choose(prompt, choices: choices)
      }

      guard range.contains(index) else {
        print("Error: '\(index)' is not in the range \(range.lowerBound) - \(range.upperBound).\n")
        return choose(prompt, choices: choices)
      }

      strs.append(choices[index - 1])
    }

    if strs.count == 1 {
      print("You select '\(strs[0])'.\n")
    } else {
      print("You select '\(strs.joined(separator: "', '"))'.\n")
    }

    return strs
  }

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
}
