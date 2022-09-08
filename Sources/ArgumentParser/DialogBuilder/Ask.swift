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
/// let name = ask("? Please enter your name: ")
/// ```
///
/// The above code will generate the following dialog:
///
/// ```
/// ? Please enter your name: keith
/// ```
///
/// - Parameters:
///   - prompt: The message to display.
///   - getInput: Get input from the user's typing or other ways.
/// - Returns: The string casted to the type requested.
internal func ask(
  _ prompt: String,
  getInput: () -> String? = { readLine() }
) -> String {
  print(prompt, terminator: "")

  return getInput() ?? ""
}

/// Ask single value from the user after displaying a prompt.
///
/// ```swift
/// let age = ask("? Please enter your age: ", type: Int.self)
/// ```
///
/// The above code will generate the following dialog:
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
///   - getInput: Get input from the user's typing or other ways.
/// - Returns: The string casted to the type requested.
internal func ask<T: ExpressibleByArgument>(
  _ prompt: String,
  type: T.Type,
  getInput: () -> String? = { readLine() }
) -> T {
  print(prompt, terminator: "")

  let input = getInput() ?? ""
  guard let value = T(argument: input) else {
    print("Error: The type of '\(input)' is not \(type).\n")
    return ask(prompt, type: type)
  }

  return value
}

/// Ask array from the user after displaying a prompt.
///
/// ```swift
/// let nums = ask(
///   "? Please enter your favorite positive numbers: ",
///   type: [Double].self)
/// ```
///
/// The above code will generate the following dialog:
///
/// ```
/// ? Please enter your favorite positive numbers: 0 1 b
/// Error: The type of 'b' is not Double.
///
/// ? Please enter your favorite positive numbers: 1 2 3
/// ```
///
/// - Parameters:
///   - prompt: The message to display.
///   - type: The type of array you expected the user enters.
///   - getInput: Get input from the user's typing or other ways.
/// - Returns: The string casted to the type requested.
internal func ask<E: ExpressibleByArgument>(
  _ prompt: String,
  type: [E].Type,
  getInput: () -> String? = { readLine() }
) -> [E] {
  print(prompt, terminator: "")

  var result: [E] = []
  let input = getInput() ?? ""
  for str in input.components(separatedBy: " ") {
    guard let val = E(argument: str) else {
      print("Error: The type of '\(str)' is not \(E.self).\n")
      return ask(prompt, type: type)
    }
    result.append(val)
  }

  return result
}
