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

@Suite struct LongNameWithSingleDashEndToEndTests {}

// MARK: -

private struct Bar: ParsableArguments {
  @Flag(name: .customLong("file", withSingleDash: true))
  var file: Bool = false

  @Flag(name: .short)
  var force: Bool = false

  @Flag(name: .short)
  var input: Bool = false
}

// swift-format-ignore: AlwaysUseLowerCamelCase
// https://github.com/apple/swift-argument-parser/issues/710
extension LongNameWithSingleDashEndToEndTests {
  @Test func parsing_empty() throws {
    expectParse(Bar.self, []) { options in
      #expect(options.file == false)
      #expect(options.force == false)
      #expect(options.input == false)
    }
  }

  @Test func parsing_singleOption_1() {
    expectParse(Bar.self, ["-file"]) { options in
      #expect(options.file == true)
      #expect(options.force == false)
      #expect(options.input == false)
    }
  }

  @Test func parsing_singleOption_2() {
    expectParse(Bar.self, ["-f"]) { options in
      #expect(options.file == false)
      #expect(options.force == true)
      #expect(options.input == false)
    }
  }

  @Test func parsing_singleOption_3() {
    expectParse(Bar.self, ["-i"]) { options in
      #expect(options.file == false)
      #expect(options.force == false)
      #expect(options.input == true)
    }
  }

  @Test func parsing_combined_1() {
    expectParse(Bar.self, ["-f", "-i"]) { options in
      #expect(options.file == false)
      #expect(options.force == true)
      #expect(options.input == true)
    }
  }

  @Test func parsing_combined_2() {
    expectParse(Bar.self, ["-fi"]) { options in
      #expect(options.file == false)
      #expect(options.force == true)
      #expect(options.input == true)
    }
  }

  @Test func parsing_combined_3() {
    expectParse(Bar.self, ["-file", "-f"]) { options in
      #expect(options.file == true)
      #expect(options.force == true)
      #expect(options.input == false)
    }
  }

  @Test func parsing_combined_4() {
    expectParse(Bar.self, ["-file", "-i"]) { options in
      #expect(options.file == true)
      #expect(options.force == false)
      #expect(options.input == true)
    }
  }

  @Test func parsing_combined_5() {
    expectParse(Bar.self, ["-file", "-fi"]) { options in
      #expect(options.file == true)
      #expect(options.force == true)
      #expect(options.input == true)
    }
  }

  @Test func parsing_invalid() throws {
    #expect(throws: (any Error).self) { try Bar.parse(["--file"]) }
  }
}

// swift-format-ignore: AlwaysUseLowerCamelCase
// https://github.com/apple/swift-argument-parser/issues/710
extension LongNameWithSingleDashEndToEndTests {
  private struct Issue327: ParsableCommand {
    @Option(
      name: .customLong("argWithAnH", withSingleDash: true),
      parsing: .upToNextOption)
    var args: [String]
  }

  @Test func issue327() {
    expectParse(
      Issue327.self, ["-argWithAnH", "03ade86c0", "8f2058e3ade86c84ec5b"]
    ) { issue327 in
      #expect(issue327.args == ["03ade86c0", "8f2058e3ade86c84ec5b"])
    }
  }

  private struct JoinedItem: ParsableCommand {
    @Option(name: .customLong("argWithAnH", withSingleDash: true))
    var arg: String
  }

  @Test func joinedItem_Issue327() {
    expectParse(JoinedItem.self, ["-argWithAnH=foo"]) { joinedItem in
      #expect(joinedItem.arg == "foo")
    }
  }
}
