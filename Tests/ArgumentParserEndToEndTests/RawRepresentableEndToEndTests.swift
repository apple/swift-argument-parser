//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020-2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import ArgumentParser
import ArgumentParserTestHelpers
import Testing

@Suite struct RawRepresentableEndToEndTests {}

// MARK: -

private struct Bar: ParsableArguments {
  struct Identifier: RawRepresentable, Equatable, ExpressibleByArgument {
    var rawValue: Int
  }

  @Option() var identifier: Identifier
}

// swift-format-ignore: AlwaysUseLowerCamelCase
// https://github.com/apple/swift-argument-parser/issues/710
extension RawRepresentableEndToEndTests {
  @Test func parsing_SingleOption() throws {
    expectParse(Bar.self, ["--identifier", "123"]) { bar in
      #expect(bar.identifier == Bar.Identifier(rawValue: 123))
    }
  }

  @Test func parsing_SingleOptionMultipleTimes() throws {
    expectParse(Bar.self, ["--identifier", "123", "--identifier", "456"]) {
      bar in
      #expect(bar.identifier == Bar.Identifier(rawValue: 456))
    }
  }

  @Test func parsing_SingleOption_Fails() throws {
    #expect(throws: (any Error).self) { try Bar.parse([]) }
    #expect(throws: (any Error).self) { try Bar.parse(["--identifier"]) }
    #expect(throws: (any Error).self) {
      try Bar.parse(["--identifier", "not a number"])
    }
    #expect(throws: (any Error).self) {
      try Bar.parse(["--identifier", "123.456"])
    }
  }
}

struct LogLevel: RawRepresentable, CustomStringConvertible {
  var rawValue: String
  var description: String { rawValue }
}

extension LogLevel: LosslessStringConvertible {
  init(_ description: String) {
    self.rawValue = description
  }
}

extension LogLevel: ExpressibleByArgument {}
