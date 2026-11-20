//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import ArgumentParser

@main
struct NameVarieties: ParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "A utility exercising every supported argument name variety."
  )

  @Flag(name: .short, help: "A flag with only a short name.")
  var verbose = false

  @Flag(name: .shortAndLong, help: "A flag with both short and long names.")
  var quiet = false

  @Option(name: .short, help: "An option with only a short name.")
  var count: Int = 1

  @Option(
    name: .customLong("level", withSingleDash: true),
    help: "An option with only a single-dash long name.")
  var level: Int = 0

  @Option(name: .long, help: "An option with only a long name.")
  var format: String = "text"

  func run() {
    print("verbose: \(verbose)")
    print("quiet: \(quiet)")
    print("count: \(count)")
    print("level: \(level)")
    print("format: \(format)")
  }
}
