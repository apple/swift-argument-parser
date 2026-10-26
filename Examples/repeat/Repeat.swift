//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import ArgumentParser

@main
struct Repeat: ParsableCommand {
  @Option(help: "How many times to repeat 'phrase'.")
  var count: Int? = nil

  @Flag(help: "Include a counter with each repetition.")
  var includeCounter = false

  @Argument(help: "The phrase to repeat.")
  var phrase: String

  mutating func validate() throws {
    if let count, count < 0 {
      throw ValidationError("Count must be zero or greater.")
    }
  }

  mutating func run() throws {
    let repeatCount = count ?? 2

    for i in 0..<repeatCount {
      if includeCounter {
        print("\(i + 1): \(phrase)")
      } else {
        print(phrase)
      }
    }
  }
}
