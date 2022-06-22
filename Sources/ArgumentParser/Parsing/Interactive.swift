//
//  File.swift
//
//
//  Created by Keith  on 2022/6/21.
//

extension CommandParser {
  func canInteract(error: Error, split: inout SplitArguments) -> Bool {
    if let error = error as? ParserError {
      switch error {
      case let .missingValueForOption(inputOrigin, name):
        var input: String?
        while input?.isEmpty ?? true {
          print("Please enter value for '\(name.synopsisString)': ", terminator: "")
          input = readLine() ?? nil
        }
        
        let index = inputOrigin.elements.first!.baseIndex! + 1
        split._elements.append(.init(value: .value(input!),
                                     index: .init(inputIndex: .init(rawValue: index))))
        return true
        
      default:
        break
      }
    }
    
    return false
  }
  
  func canInteract(error: Error, values: inout ParsedValues) -> Bool {
    if let error = error as? ParserError {
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
    }
    
    return false
  }
}
