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

/// Asks single string from the user after displaying a prompt.
///
/// ```swift
/// let name: String = ask("? Please enter your name: ")
/// ```
/// By default ask captures a string entered by the user:
///
/// ```
/// ? Please enter your name: keith
/// ```
///
/// - Parameters:
///   - prompt: The message to display.
/// - Returns: String from user input.
public func ask(_ prompt: String) -> String {
  ask(prompt, type: String.self)
}

/// Ask single value from the user after displaying a prompt.
///
/// ```swift
/// let age = ask("? Please enter your age: ", type: Int.self)
/// ```
///
/// Ask with a `type` parameter will automatically validate the input:
///
/// ```
/// ? Please enter your age: keith
/// Error: The type of 'keith' is not Int.
///
/// ? Please enter your age: 18
/// ```
///
/// - Parameters:
///   - prompt: The message to display.
///   - type: The value type expected the user enters.
/// - Returns: The string casted to the type requested.
public func ask<T: ExpressibleByArgument>(_ prompt: String, type: T.Type) -> T {
  print(prompt, terminator: "")

  let input = readLine() ?? ""
  guard let value = T(argument: input) else {
    print("Error: The type of '\(input)' is not \(type).\n")
    return ask(prompt, type: type)
  }

  return value
}

/// Ask single string from the user after displaying a prompt.
///
/// ```swift
/// let name = ask("? Please enter your name: ") { name in
///   if name.allSatisfy({ $0 == " " }) {
///     return .failure(.init("Error: Name cannot be empty.\n"))
///   } else {
///     return .success(())
///   }
/// }
/// ```
/// `validate` method can validate user input after parsing:
///
/// ```
/// ? Please enter your name:
/// Error: Name cannot be empty.
///
/// ? Please enter your name: keith
/// ```
///
/// - Parameters:
///   - prompt: The message to display.
///   - validate: Custom validation for user input.
/// - Returns: The string casted to the type requested.
public func ask(
  _ prompt: String,
  validate: ((String) -> Result<Void, ValidationError>)? = nil
) -> String {
  print(prompt, terminator: "")

  let input = readLine() ?? ""
  guard let validate = validate else { return input }

  switch validate(input) {
  case .success:
    return input
  case let .failure(e):
    print(e)
    return ask(prompt, validate: validate)
  }
}

/// Ask single value from the user after displaying a prompt.
///
/// ```swift
/// let age = ask("? Please enter your age: ", type: Int.self) { age in
///   if age < 0 {
///     return .failure(.init("Error: Age cannot be negative.\n"))
///   } else {
///     return .success(())
///   }
/// }
/// ```
///
/// `type` parameter and `validate` method can work together:
///
/// ```
/// ? Please enter your age: keith
/// Error: The type of 'keith' is not Int.
///
/// ? Please enter your age: -1
/// Error: Age cannot be negative.
///
/// ? Please enter your age: 18
/// ```
///
/// - Parameters:
///   - prompt: The message to display.
///   - type: The value type expected the user enters.
///   - validate: Custom validation for user input.
/// - Returns: The string casted to the type requested.
public func ask<T: ExpressibleByArgument>(
  _ prompt: String,
  type: T.Type,
  validate: ((T) -> Result<Void, ValidationError>)? = nil
) -> T {
  print(prompt, terminator: "")

  let input = readLine() ?? ""
  guard let value = T(argument: input) else {
    print("Error: The type of '\(input)' is not \(type).\n")
    return ask(prompt, type: type, validate: validate)
  }

  guard let validate = validate else { return value }

  switch validate(value) {
  case .success:
    return value
  case let .failure(e):
    print(e)
    return ask(prompt, type: type, validate: validate)
  }
}

/// Ask array from the user after displaying a prompt.
///
/// ```swift
/// let integers = ask(
///   "? Please enter your favorite integers: ",
///   type: [Int].self)
/// ```
///
/// Each element in the input array will be converted to the specified type:
///
/// ```
/// ? Please enter your favorite integers: 1 2 c
/// Error: The type of 'c' is not Int.
///
/// ? Please enter your favorite integers: 1 2 3
/// ```
///
/// - Parameters:
///   - prompt: The message to display.
///   - type: The type of array you expected the user enters.
/// - Returns: The string casted to the type requested.
public func ask<E: ExpressibleByArgument>(_ prompt: String, type: [E].Type) -> [E] {
  print(prompt, terminator: "")

  var result: [E] = []
  let input = readLine() ?? ""
  for str in input.components(separatedBy: " ") {
    guard let val = E(argument: str) else {
      print("Error: The type of '\(str)' is not \(E.self).\n")
      return ask(prompt, type: type)
    }
    result.append(val)
  }

  return result
}

/// Ask array from the user after displaying a prompt.
///
/// ```swift
/// let nums = ask(
///   "? Please enter your favorite positive numbers: ",
///   type: [Double].self) { nums in
///     if let num = nums.first(where: { $0 <= 0 }) {
///       return .failure(.init("Error: '\(num)' is not a positive number.\n"))
///     } else {
///       return .success(())
///     }
///   }
/// ```
///
/// `type` parameter and `validate` method can work together:
///
/// ```
/// ? Please enter your favorite positive numbers: 0 1 b
/// Error: The type of 'b' is not Double.
///
/// ? Please enter your favorite positive numbers: 0 1 2
/// Error: '0.0' is not a positive number.
///
/// ? Please enter your favorite positive numbers: 1 2 3
/// ```
///
/// - Parameters:
///   - prompt: The message to display.
///   - type: The type of array you expected the user enters.
///   - validate: Custom validation for user input.
/// - Returns: The string casted to the type requested.
public func ask<E: ExpressibleByArgument>(
  _ prompt: String,
  type: [E].Type,
  validate: ([E]) -> Result<Void, ValidationError>
) -> [E] {
  print(prompt, terminator: "")

  var result: [E] = []
  let input = readLine() ?? ""
  for str in input.components(separatedBy: " ") {
    guard let val = E(argument: str) else {
      print("Error: The type of '\(str)' is not \(E.self).\n")
      return ask(prompt, type: type, validate: validate)
    }
    result.append(val)
  }

  switch validate(result) {
  case .success:
    return result
  case let .failure(e):
    print(e)
    return ask(prompt, type: type, validate: validate)
  }
}
