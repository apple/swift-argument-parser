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

struct ParsableArgumentsValidationError: Error, CustomStringConvertible {
  let parsableArgumentsType: ParsableArguments.Type
  let underlayingErrors: [Error]
  var description: String {
    """
    Validation failed for `\(parsableArgumentsType)`:
    \(underlayingErrors.map({"- \($0)"}).joined(separator: "\n"))
    
    """
  }
}

extension ParsableArguments {
  static func _validate() throws {
    let validators: [ParsableArgumentsValidator.Type] = [
      PositionalArgumentsValidator.self,
      ParsableArgumentsCodingKeyValidator.self,
      ParsableArgumentsUniqueNamesValidator.self,
    ]
    let errors: [Error] = validators.compactMap { validator in
      do {
        try validator.validate(self)
        return nil
      } catch {
        return error
      }
    }
    if errors.count > 0 {
      throw ParsableArgumentsValidationError(parsableArgumentsType: self, underlayingErrors: errors)
    }
  }
}

fileprivate extension ArgumentSet {
  var firstPositionalArgument: ArgumentDefinition? {
    switch content {
    case .arguments(let arguments):
      return arguments.first(where: { $0.isPositional })
    case .sets(let sets):
      return sets.first(where: { $0.firstPositionalArgument != nil })?.firstPositionalArgument
    }
  }
  
  var firstRepeatedPositionalArgument: ArgumentDefinition? {
    switch content {
    case .arguments(let arguments):
      return arguments.first(where: { $0.isRepeatingPositional })
    case .sets(let sets):
      return sets.first(where: { $0.firstRepeatedPositionalArgument != nil })?.firstRepeatedPositionalArgument
    }
  }
}

/// For positional arguments to be valid, there must be at most one
/// positional array argument, and it must be the last positional argument
/// in the argument list. Any other configuration leads to ambiguity in
/// parsing the arguments.
struct PositionalArgumentsValidator: ParsableArgumentsValidator {
  
  struct Error: Swift.Error, CustomStringConvertible {
    let repeatedPositionalArgument: String
    let positionalArgumentFollowingRepeated: String
    var description: String {
      "Can't have a positional argument `\(positionalArgumentFollowingRepeated)` following an array of positional arguments `\(repeatedPositionalArgument)`."
    }
  }
  
  static func validate(_ type: ParsableArguments.Type) throws {
    let sets: [ArgumentSet] = Mirror(reflecting: type.init())
      .children
      .compactMap { child in
        guard
          var codingKey = child.label,
          let parsed = child.value as? ArgumentSetProvider
          else { return nil }
        
        // Property wrappers have underscore-prefixed names
        codingKey = String(codingKey.first == "_" ? codingKey.dropFirst(1) : codingKey.dropFirst(0))
        
        let key = InputKey(rawValue: codingKey)
        return parsed.argumentSet(for: key)
    }
    
    guard let repeatedPositional = sets.firstIndex(where: { $0.firstRepeatedPositionalArgument != nil })
      else { return }
    let positionalFollowingRepeated = sets[repeatedPositional...]
      .dropFirst()
      .first(where: { $0.firstPositionalArgument != nil })
    
    if let positionalFollowingRepeated = positionalFollowingRepeated {
      let firstRepeatedPositionalArgument: ArgumentDefinition = sets[repeatedPositional].firstRepeatedPositionalArgument!
      let positionalFollowingRepeatedArgument: ArgumentDefinition = positionalFollowingRepeated.firstPositionalArgument!
      throw Error(repeatedPositionalArgument: firstRepeatedPositionalArgument.help.keys.first!.rawValue,
                  positionalArgumentFollowingRepeated: positionalFollowingRepeatedArgument.help.keys.first!.rawValue)
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
    let missingCodingKeys: [String]
    var description: String {
      if missingCodingKeys.count > 1 {
        return "Arguments \(missingCodingKeys.map({ "`\($0)`" }).joined(separator: ",")) are defined without corresponding `CodingKey`s."
      } else {
        return "Argument `\(missingCodingKeys[0])` is defined without a corresponding `CodingKey`."
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
        throw Error(missingCodingKeys: keys)
      case .success:
        break
      }
    } catch {
      fatalError("Unexpected validation error: \(error)")
    }
  }
}

/// Ensure argument names are unique within a `ParsableArguments` or `ParsableCommand`.
struct ParsableArgumentsUniqueNamesValidator: ParsableArgumentsValidator {
  struct Error: Swift.Error, CustomStringConvertible {
    var duplicateNames: [String: Int] = [:]

    var occurred: Bool {
      !duplicateNames.isEmpty
    }

    var description: String {
      duplicateNames.map { entry in
        "Multiple (\(entry.value)) `Option` or `Flag` arguments are named \"\(entry.key)\"."
      }.joined(separator: "\n")
    }
  }

  static func validate(_ type: ParsableArguments.Type) throws {
    let argSets: [ArgumentSet] = Mirror(reflecting: type.init())
      .children
      .compactMap { child in
        guard
          var codingKey = child.label,
          let parsed = child.value as? ArgumentSetProvider
          else { return nil }

        // Property wrappers have underscore-prefixed names
        codingKey = String(codingKey.first == "_" ? codingKey.dropFirst(1) : codingKey.dropFirst(0))

        let key = InputKey(rawValue: codingKey)
        return parsed.argumentSet(for: key)
    }

    let countedNames: [String: Int] = argSets.reduce(into: [:]) { countedNames, args in
      switch args.content {
      case .arguments(let defs):
        for name in defs.flatMap({ $0.names }) {
          countedNames[name.valueString, default: 0] += 1
        }
      default:
        break
      }
    }

    var error = Error()

    let duplicateNames = countedNames.filter { $0.value > 1 }
    if !duplicateNames.isEmpty {
      error.duplicateNames = duplicateNames
    }

    if error.occurred {
      throw error
    }
  }
}
