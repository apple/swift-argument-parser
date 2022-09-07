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
///   - getInput: Get input from the user's typing or other ways.
///   - validate: Custom validation for user input.
/// - Returns: The string casted to the type requested.
internal func ask(
  _ prompt: String,
  getInput: () -> String? = { readLine() },
  validate: ((String) -> Result<Void, ValidationError>)? = nil
) -> String {
  print(prompt, terminator: "")

  let input = getInput() ?? ""

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
///   - getInput: Get input from the user's typing or other ways.
///   - validate: Custom validation for user input.
/// - Returns: The string casted to the type requested.
internal func ask<T: ExpressibleByArgument>(
  _ prompt: String,
  type: T.Type,
  getInput: () -> String? = { readLine() },
  validate: ((T) -> Result<Void, ValidationError>)? = nil
) -> T {
  print(prompt, terminator: "")

  let input = getInput() ?? ""
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
///   - getInput: Get input from the user's typing or other ways.
///   - validate: Custom validation for user input.
/// - Returns: The string casted to the type requested.
internal func ask<E: ExpressibleByArgument>(
  _ prompt: String,
  type: [E].Type,
  getInput: () -> String? = { readLine() },
  validate: (([E]) -> Result<Void, ValidationError>)? = nil
) -> [E] {
  print(prompt, terminator: "")

  var result: [E] = []
  let input = getInput() ?? ""
  for str in input.components(separatedBy: " ") {
    guard let val = E(argument: str) else {
      print("Error: The type of '\(str)' is not \(E.self).\n")
      return ask(prompt, type: type, validate: validate)
    }
    result.append(val)
  }

  guard let validate = validate else { return result }
  switch validate(result) {
  case .success:
    return result
  case let .failure(e):
    print(e)
    return ask(prompt, type: type, validate: validate)
  }
}
