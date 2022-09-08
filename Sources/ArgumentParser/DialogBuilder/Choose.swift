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

/// Prompts the user to choose items from the supplied choices.
///
///
/// ```swift
/// let selected = choose("Please pick your favorite colors: ",
///                       from: ["pink", "purple", "silver"])
/// ```
///
/// The above code will generate the following dialog:
///
/// ```
/// 1. pink
/// 2. purple
/// 3. silver
/// Please pick your favorite colors: pink
/// Error: 'pink' is not a serial number.
///
/// Please pick your favorite colors: 0 1
/// Error: '0' is not in the range 1 - 3.
///
/// Please pick your favorite colors: 1 2
/// ```
///
/// - Parameters:
///   - prompt: Prompt to display to the user after listing choices.
///   - choices: Items to choose from.
///   - getInput: Get input from the user's typing or other ways.
/// - Returns: The user selected indices.
internal func choose(
  _ prompt: String,
  from choices: [String],
  getInput: () -> String? = { readLine() }
) -> [Int] {
  let range = 1 ... choices.count
  choices.enumerated().forEach { print("\($0 + 1). \($1)") }

  while true {
    var selected: [Int] = []
    print(prompt, terminator: "")

    let nums = getInput()?.components(separatedBy: " ") ?? [""]
    for num in nums {
      guard let index = Int(num) else {
        print("Error: '\(num)' is not a serial number.\n")
        selected.removeAll()
        break
      }

      guard range.contains(index) else {
        print("Error: '\(index)' is not in the range \(range.lowerBound) - \(range.upperBound).\n")
        selected.removeAll()
        break
      }

      selected.append(index - 1)
    }

    guard !selected.isEmpty else { continue }
    return selected
  }
}
