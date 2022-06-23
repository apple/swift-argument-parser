//
//  File.swift
//
//
//  Created by Keith  on 2022/6/21.
//

extension CommandParser {
  func canInteract(error: Error, split: inout SplitArguments) -> Bool {
    guard let error = error as? ParserError else { return false }
    guard case let .missingValueForOption(inputOrigin, name) = error else { return false }
    
    var input: String?
    while input?.isEmpty ?? true {
      print("Please enter value for '\(name.synopsisString)': ", terminator: "")
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
  
  func canInteract(error: Error, values: inout ParsedValues) -> Bool {
    guard let error = error as? ParserError else { return false }
    
    switch error {
    case let .noValue(forKey: key):
      let label = key.rawValue
      guard label != "generateCompletionScript" else { break }
        
      var input: String?
      while input?.isEmpty ?? true {
        print("Please enter '\(label)': ", terminator: "")
        input = readLine() ?? nil
      }
        
      var element = values.elements[key]!
      element.value = (input as Any)
      element.inputOrigin = InputOrigin(elements: [.interactive])
      values.elements[key] = element
      return true
        
    default:
      break
    }
    
    return false
  }
}
