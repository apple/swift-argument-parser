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

struct ParsableArgumentsCodingKeyValidator {
  
  private struct Validator: Decoder {
    let argumentKeys: [String]
    
    enum ValidationResult: Error {
      case success
      case codingKeyNotFound(String)
    }
    
    let codingPath: [CodingKey] = []
    let userInfo: [CodingUserInfoKey : Any] = [:]
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
      fatalError()
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
      fatalError()
    }
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
      for argument in argumentKeys {
        if Key(stringValue: argument) == nil {
          throw ValidationResult.codingKeyNotFound(argument)
        }
      }
      throw ValidationResult.success
    }
  }
  
  struct ValidationError: Error {
    let parsableArgumentsType: ParsableArguments.Type
    let missingKey: String
    var errorDescription: String {
      """
      
      ------------------------------------------------------------------
      Can't find the coding key for a parsable argument.
      
      This error indicates that an option, a flag, or an argument of a
      `ParsableArguments` is defined without a corresponding `CodingKey`.
      
      Type: \(parsableArgumentsType)
      Key: \(missingKey)
      ------------------------------------------------------------------
      
      """
    }
  }
  
  static func validate(_ type: ParsableArguments.Type) {
    var error: ValidationError?
    validate(type, error: &error)
    if let error = error {
      fatalError(error.errorDescription)
    }
  }
  
  static func validate(_ type: ParsableArguments.Type, error: inout ValidationError?) {
    let argumentKeys: [String] = Mirror(reflecting: type.init())
      .children
      .compactMap { child in
        guard
          let codingKey = child.label,
          let _ = child.value as? ArgumentSetProvider
          else { return nil }
        
        // Property wrappers have underscore-prefixed names
        return String(codingKey.first == "_" ? codingKey.dropFirst(1) : codingKey.dropFirst(0))
    }
    do {
      let _ = try type.init(from: Validator(argumentKeys: argumentKeys))
    } catch let result as Validator.ValidationResult {
      switch result {
      case .codingKeyNotFound(let key):
        error = ValidationError(parsableArgumentsType: type, missingKey: key)
      case .success:
        error = nil
      }
    } catch {
      fatalError("\(error)")
    }
  }
}
