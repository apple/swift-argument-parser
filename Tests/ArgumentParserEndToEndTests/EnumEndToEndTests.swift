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

@Suite struct EnumEndToEndTests {}

// MARK: -

private struct Bar: ParsableArguments {
  enum Index: String, Equatable, ExpressibleByArgument {
    case hello
    case goodbye
  }

  @Option()
  var index: Index
}

// swift-format-ignore: AlwaysUseLowerCamelCase
// https://github.com/apple/swift-argument-parser/issues/710
extension EnumEndToEndTests {
  @Test func parsing_SingleOption() throws {
    expectParse(Bar.self, ["--index", "hello"]) { bar in
      #expect(bar.index == Bar.Index.hello)
    }
    expectParse(Bar.self, ["--index", "goodbye"]) { bar in
      #expect(bar.index == Bar.Index.goodbye)
    }
  }

  @Test func parsing_SingleOptionMultipleTimes() throws {
    expectParse(Bar.self, ["--index", "hello", "--index", "goodbye"]) { bar in
      #expect(bar.index == Bar.Index.goodbye)
    }
  }

  @Test func parsing_SingleOption_Fails() throws {
    #expect(throws: (any Error).self) { try Bar.parse([]) }
    #expect(throws: (any Error).self) { try Bar.parse(["--index"]) }
    #expect(throws: (any Error).self) { try Bar.parse(["--index", "hell"]) }
    #expect(throws: (any Error).self) { try Bar.parse(["--index", "helloo"]) }
  }
}

// MARK: -

private struct Baz: ParsableArguments {
  enum Mode: String, CaseIterable, ExpressibleByArgument {
    case generateBashScript = "generate-bash-script"
    case generateZshScript
  }

  @Option(name: .customLong("mode")) var modeOption: Mode?
  @Argument() var modeArg: Mode?
}

// swift-format-ignore: AlwaysUseLowerCamelCase
// https://github.com/apple/swift-argument-parser/issues/710
extension EnumEndToEndTests {
  @Test func parsingRawValue_Option() throws {
    expectParse(Baz.self, ["--mode", "generate-bash-script"]) { baz in
      #expect(baz.modeOption == .generateBashScript)
      #expect(baz.modeArg == nil)
    }
    expectParse(Baz.self, ["--mode", "generateZshScript"]) { baz in
      #expect(baz.modeOption == .generateZshScript)
      #expect(baz.modeArg == nil)
    }
  }

  @Test func parsingRawValue_Argument() throws {
    expectParse(Baz.self, ["generate-bash-script"]) { baz in
      #expect(baz.modeArg == .generateBashScript)
      #expect(baz.modeOption == nil)
    }
    expectParse(Baz.self, ["generateZshScript"]) { baz in
      #expect(baz.modeArg == .generateZshScript)
      #expect(baz.modeOption == nil)
    }
  }

  @Test func parsingRawValue_Fails() throws {
    #expect(throws: (any Error).self) {
      try Baz.parse(["generateBashScript"])
    }
    #expect(throws: (any Error).self) {
      try Baz.parse(["--mode generateBashScript"])
    }
    #expect(throws: (any Error).self) {
      try Baz.parse(["generate-zsh-script"])
    }
    #expect(throws: (any Error).self) {
      try Baz.parse(["--mode generate-zsh-script"])
    }
  }
}
