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
  func canInteract(error: Error, split: inout SplitArguments, lineStack: inout [String]?) -> Bool {
    guard lineStack == nil || !lineStack!.isEmpty else { return false }
    guard let error = error as? ParserError else { return false }
    guard case let .missingValueForOption(inputOrigin, name) = error else { return false }
    
    var input = lineStack?.removeLast()
    while input?.isEmpty ?? true {
      print("? Please enter value for '\(name.synopsisString)': ", terminator: "")
      input = readLine() ?? nil
    }
    
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
  func canInteract(error: Error, arguments: ArgumentSet, values: inout ParsedValues, lineStack: inout [String]?) -> Bool {
    guard lineStack == nil || !lineStack!.isEmpty else { return false }
    guard let error = error as? ParserError else { return false }
    
    switch error {
    case let .noValue(forKey: key):
      let label = key.rawValue
      guard label != "generateCompletionScript" else { break }
      
      // Extract the parameters used in the test.
      var input = lineStack?.removeLast()
      while input?.isEmpty ?? true {
        print("? Please enter '\(label)': ", terminator: "")
        input = readLine() ?? nil
      }
      
      // Retrieve the correct `ArgumentDefinition` for the required transformation
      // before storing the new value received from the user.
      guard let definition = arguments.content.first(where: { $0.valueName == label }) else { break }
      let name = definition.names.first // (where: { $0.case == .long } )
      guard case let .unary(update) = definition.update else { break }
      
      // Split array input like "1 2 3".
      for input in input!.components(separatedBy: " ") {
        try! update(InputOrigin(elements: [.interactive]), name, input, &values)
      }
      
      return true
        
    default: break
    }
    
    return false
  }
}
