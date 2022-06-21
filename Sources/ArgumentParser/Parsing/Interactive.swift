//
//  File.swift
//
//
//  Created by Keith  on 2022/6/21.
//

extension CommandParser {
  func canInteract(error: Error, values: inout ParsedValues) -> Bool {
    if let error = error as? ParserError {
      switch error {
      case .noValue(forKey: let key):
        guard key.rawValue != "generateCompletionScript" else { break }
        
        var input = ""
        while input.isEmpty {
          print("Please enter '\(key.rawValue)': ", terminator: "")
          guard let line = readLine() else { continue }
          input = line
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
