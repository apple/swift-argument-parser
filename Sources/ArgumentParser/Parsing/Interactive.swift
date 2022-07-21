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
  mutating func canInteract(error: Error, split: inout SplitArguments) throws -> Bool {
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
  mutating func canInteract(error: Error, arguments: ArgumentSet, values: inout ParsedValues) throws -> Bool {
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
      
      let input: [String]
      let allValues = definition.help.allValues
      if allValues.isEmpty {
        // Get normal value
        input = getNormalValue(label: label)
      } else {
        allValues.enumerated().forEach { print("\($0 + 1). \($1)") }
        // Get CaseIterable Enum
        input = getCaseIterableEnum(label: label, allValues: allValues)
      }
      
      // Split array input like "1 2 3".
      for element in input {
        try update(InputOrigin(elements: [.interactive]), name, element, &values)
      }
      
      return true
        
    default: break
    }
    
    return false
  }
  
  fileprivate mutating func getNormalValue(label: String) -> [String] {
    print("? Please enter '\(label)': ", terminator: "")
    return getInput()?.components(separatedBy: " ") ?? [""]
  }
  
  fileprivate mutating func getCaseIterableEnum(label: String, allValues: [String]) -> [String] {
    print("? Please select '\(label)': ", terminator: "")
    let strs = getInput()?.components(separatedBy: " ") ?? [""]
    
    var nums: [String] = []
    let range = 1 ... allValues.count
    for str in strs {
      guard let index = Int(str) else {
        print("Error: '\(str)' is not a serial number.\n")
        return getCaseIterableEnum(label: label, allValues: allValues)
      }

      guard range.contains(index) else {
        print("Error: '\(index)' is not in the range of \(range) \n")
        return getCaseIterableEnum(label: label, allValues: allValues)
      }
      
      nums.append(allValues[index - 1])
    }
    
    if nums.count == 1 {
      print("You select '\(nums[0])'.\n")
    } else {
      print("You select '\(nums.joined(separator: "', '"))'.\n")
    }
    
    return nums
  }
  
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
