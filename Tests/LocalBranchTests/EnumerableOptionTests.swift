//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import XCTest
import ArgumentParserTestHelpers
@testable import ArgumentParser

enum Color: String, EnumerableOption {
  typealias RawValue = String

  case blue
  case red
  case orange
  case yellow
  case pink
  case purple
  case green

  public var description: String {
    return rawValue
  }

  public init?(argument: String) {
    guard let packageType = Color(rawValue: argument) else {
      return nil
    }

    self = packageType
  }

  public var abstract: String {
    switch self {
    case .blue:
      return "The color of the sky!"
    case .red:
      return "The color of a rose!"
    case .orange:
      return "The color of a fruit!"
    case .yellow:
      return "The color of the sun!"
    case .pink:
      return "The color of bubble gum!"
    case .purple:
      return "The color of a plum!"
    case .green:
      return "The color of grass!"
    }
  }

  public var name: String {
    self.rawValue
  }

  public var help: ArgumentHelp? {
    .init(
      self.abstract,
      valueName: self.name,
      visibility: .default
    )
  }
}

final class EnumerableOptionTests: XCTestCase { }

extension EnumerableOptionTests {
  // Without default value
  struct A: ParsableArguments {
    @Option(name: .customLong("type"), abstract: "Package type:") var type: Color
  }

  // With default value
  struct B: ParsableArguments {
    @Option(name: .customLong("type"), abstract: "Package type:") var type: Color = .red
  }

  func testA() {
    AssertHelp(.default, for: A.self, equals: Self.aHelpText)
  }

  func testB() {
    AssertHelp(.default, for: B.self, equals: Self.bHelpText)
  }
}

extension EnumerableOptionTests {
  static let aHelpText = """
USAGE: a --type <type>

OPTIONS:
  --type <type>           Package type: (values: blue, red, orange, yellow,
                          pink, purple, green)
      blue                - The color of the sky!
      red                 - The color of a rose!
      orange              - The color of a fruit!
      yellow              - The color of the sun!
      pink                - The color of bubble gum!
      purple              - The color of a plum!
      green               - The color of grass!
  -h, --help              Show help information.

"""

  static let bHelpText = """
USAGE: b [--type <type>]

OPTIONS:
  --type <type>           Package type: (default: red)
      blue                - The color of the sky!
      red                 - The color of a rose!
      orange              - The color of a fruit!
      yellow              - The color of the sun!
      pink                - The color of bubble gum!
      purple              - The color of a plum!
      green               - The color of grass!
  -h, --help              Show help information.

"""
}
