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

import ArgumentParser

enum Color: EnumerableFlag {
  case red
  case blue
  case green
}

struct Shipping: OptionSet, EnumerableFlag {
  var rawValue: Int
  
  static let standard: Shipping = []
  static let express: Shipping = Self(rawValue: 1 << 1)
  static let nextDay: Shipping = Self(rawValue: 1 << 2)
  static let twoDay: Shipping = Self(rawValue: 1 << 3)
  
  static var allCases: [Shipping] {
    [
      .standard,
      .express,
      .nextDay,
      .twoDay,
    ]
  }
  
  static func name(for value: Self) -> NameSpecification {
    switch value {
    case .standard: .customLong("standard")
    case .express: .customLong("express")
    case .nextDay: .customLong("next-day")
    case .twoDay: .customLong("two-day")
    default: .short
    }
  }
}

@main
struct Repeat: ParsableCommand {
  @Option(help: "The number of times to repeat 'phrase'.")
  var count: Int? = nil

  @Flag(help: "Include a counter with each repetition.")
  var includeCounter = false

  @Argument(help: "The phrase to repeat.")
  var phrase: String

  @Flag 
  var color: Set<Color> = []

  @Flag 
  var shipping: Shipping = []

  mutating func run() throws {
    let repeatCount = count ?? 2
    
    print(color)
    print(shipping, shipping.contains(.nextDay))

    for i in 1...repeatCount {
      if includeCounter {
        print("\(i): \(phrase)")
      } else {
        print(phrase)
      }
    }
  }
}
