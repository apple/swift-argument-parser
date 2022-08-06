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
    guard rootCommand.configuration.isInteractable else { return false }
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
    guard rootCommand.configuration.isInteractable else { return false }
    guard lineStack == nil || !lineStack!.isEmpty else { return false }
    guard let error = error as? ParserError else { return false }

    switch error {
    case let .noValue(forKey: key):
      let label = key.rawValue
      guard label != "generateCompletionScript" else { break }

      // Retrieve the correct `ArgumentDefinition` for the required transformation
      // before storing the new value received from the user.
      guard let definition = arguments.content.first(where: { $0.valueName == label }) else { break }
      guard case let .unary(update) = definition.update else { break }
      let name = definition.names.first // (where: { $0.case == .long } )
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
        storeCaseIterableEnums(label: label, allValues: allValues, updateBy: updateBy)
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

  fileprivate mutating func storeCaseIterableEnums(
    label: String,
    allValues: [String],
    updateBy: (String) throws -> Void
  ) {
    print("? Please select '\(label)': ", terminator: "")
    let strs = getInput()?.components(separatedBy: " ") ?? [""]

    var nums: [String] = []
    let range = 1 ... allValues.count
    for num in strs {
      guard let index = Int(num) else {
        print("Error: '\(num)' is not a serial number.\n")
        storeCaseIterableEnums(label: label, allValues: allValues, updateBy: updateBy)
        return
      }

      guard range.contains(index) else {
        print("Error: '\(index)' is not in the range \(range.lowerBound) - \(range.upperBound).\n")
        storeCaseIterableEnums(label: label, allValues: allValues, updateBy: updateBy)
        return
      }

      nums.append(allValues[index - 1])
    }

    if nums.count == 1 {
      print("You select '\(nums[0])'.\n")
    } else {
      print("You select '\(nums.joined(separator: "', '"))'.\n")
    }

    nums.forEach { try! updateBy($0) }
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
