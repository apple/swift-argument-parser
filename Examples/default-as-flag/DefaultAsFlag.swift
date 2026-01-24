//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import ArgumentParser

@main
struct DefaultAsFlag: ParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "A utility demonstrating defaultAsFlag options.",
    discussion: """
      This command shows how defaultAsFlag options can work both as flags
      and as options with values.
      """
  )

  @Option(defaultAsFlag: "default", help: "A string option with defaultAsFlag.")
  var stringFlag: String?

  @Option(defaultAsFlag: 42, help: "An integer option with defaultAsFlag.")
  var numberFlag: Int?

  @Option(defaultAsFlag: true, help: "A boolean option with defaultAsFlag.")
  var boolFlag: Bool?

  @Option(
    defaultAsFlag: "transformed",
    help: "A string option with transform and defaultAsFlag.",
    transform: { $0.uppercased() }
  )
  var transformFlag: String?

  @Option(name: .shortAndLong, help: "A regular option for comparison.")
  var regular: String?

  @Argument
  var additionalArgs: [String] = []

  func run() {
    print("String flag: \(stringFlag?.description ?? "nil")")
    print("Number flag: \(numberFlag?.description ?? "nil")")
    print("Bool flag: \(boolFlag?.description ?? "nil")")
    print("Transform flag: \(transformFlag?.description ?? "nil")")
    print("Regular option: \(regular?.description ?? "nil")")
    print("Additional args: \(additionalArgs)")
  }
}
