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

fileprivate protocol ParsableArgumentsValidator {
  static func validate(_ type: ParsableArguments.Type) throws
}

extension ParsableArguments {
  static func _validate() throws {
    let validators: [ParsableArgumentsValidator.Type] = [
      ParsableArgumentsCodingKeyValidator.self
    ]
    for validator in validators {
      try validator.validate(self)
    }
  }
}

/// Ensure that all arguments have corresponding coding keys
struct ParsableArgumentsCodingKeyValidator: ParsableArgumentsValidator {
  
  private struct Validator: Decoder {
    let argumentKeys: [String]
    
    enum ValidationResult: Swift.Error {
      case success
      case missingCodingKeys([String])
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
      let missingKeys = argumentKeys.filter { Key(stringValue: $0) == nil }
      if missingKeys.isEmpty {
        throw ValidationResult.success
      } else {
        throw ValidationResult.missingCodingKeys(missingKeys)
      }
    }
  }
  
  /// This error indicates that an option, a flag, or an argument of
  /// a `ParsableArguments` is defined without a corresponding `CodingKey`.
  struct Error: Swift.Error, CustomStringConvertible {
    let parsableArgumentsType: ParsableArguments.Type
    let missingCodingKeys: [String]
    var description: String {
      if missingCodingKeys.count > 1 {
        return "Arguments \(missingCodingKeys.map({ "`\($0)`" }).joined(separator: ",")) of `\(parsableArgumentsType)` are defined without corresponding `CodingKey`s."
      } else {
        return "Argument `\(missingCodingKeys[0])` of `\(parsableArgumentsType)` is defined without a corresponding `CodingKey`."
      }
    }
  }
  
  static func validate(_ type: ParsableArguments.Type) throws {
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
    guard argumentKeys.count > 0 else {
      return
    }
    do {
      let _ = try type.init(from: Validator(argumentKeys: argumentKeys))
      fatalError("The validator should always throw.")
    } catch let result as Validator.ValidationResult {
      switch result {
      case .missingCodingKeys(let keys):
        throw Error(parsableArgumentsType: type, missingCodingKeys: keys)
      case .success:
        break
      }
    } catch {
      fatalError("Unexpected validation error: \(error)")
    }
  }
}
