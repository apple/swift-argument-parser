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

/// Ask the user to confirm the prompt.
///
/// ```swift
/// guard
///   check("Are you sure you want to delete all?")
/// else { return }
/// print("---DELETE---")
/// ```
///
/// The above code will generate the following dialog:
///
/// ```
/// Are you sure you want to delete all?
/// ? Please enter [y]es or [n]o: y
/// ---DELETE---
/// ```
/// - Parameters:
///   - prompt: The message to display.
///   - getInput: Get input from the user's typing or other ways.
/// - Returns: The user decision.
internal func check<Target: TextOutputStream>(
  _ prompt: String,
  to output: inout Target,
  getInput: () -> String? = { readLine() }
) -> Bool {
  print(prompt, to: &output)

  while true {
    print("? Please enter [y]es or [n]o: ", terminator: "", to: &output)

    let input = getInput()?
      .trimmingCharacters(in: .whitespaces)
      .lowercased()
      ?? ""

    switch input {
    case "y", "yes": return true
    case "n", "no": return false
    default: continue
    }
  }
}
