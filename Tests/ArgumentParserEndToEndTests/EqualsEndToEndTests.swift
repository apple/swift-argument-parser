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

@Suite struct EqualsEndToEndTests {}

// MARK: .short name

private struct Foo: ParsableArguments {
  @Flag(name: .short) var toggle: Bool = false
  @Option(name: .short) var name: String?
  @Option(name: .short) var format: String
}

// swift-format-ignore: AlwaysUseLowerCamelCase
extension EqualsEndToEndTests {
  @Test func equals_withShortName() throws {
    expectParse(Foo.self, ["-n=Name", "-f=Format"]) { foo in
      #expect(foo.toggle == false)
      #expect(foo.name == "Name")
      #expect(foo.format == "Format")
    }
  }

  @Test func equals_withCombinedShortName_1() throws {
    expectParse(Foo.self, ["-tf", "Format"]) { foo in
      #expect(foo.toggle == true)
      #expect(foo.name == nil)
      #expect(foo.format == "Format")
    }
  }

  @Test func equals_withCombinedShortName_2() throws {
    #expect(throws: (any Error).self) { try Foo.parse(["-tf=Format"]) }
  }
}

// MARK: .shortAndLong name

private struct Bar: ParsableArguments {
  @Option(name: .shortAndLong) var name: String
  @Option(name: .shortAndLong) var format: String
}

// swift-format-ignore: AlwaysUseLowerCamelCase
extension EqualsEndToEndTests {
  @Test func equals_withShortAndLongName() throws {
    expectParse(Bar.self, ["-n=Name", "-f=Format"]) { bar in
      #expect(bar.name == "Name")
      #expect(bar.format == "Format")
    }
  }
}

// MARK: .customShort name

private struct Baz: ParsableArguments {
  @Option(name: .customShort("i")) var name: String
  @Option(name: .customShort("t")) var format: String
}

// swift-format-ignore: AlwaysUseLowerCamelCase
extension EqualsEndToEndTests {
  @Test func equals_withCustomShortName() throws {
    expectParse(Baz.self, ["-i=Name", "-t=Format"]) { baz in
      #expect(baz.name == "Name")
      #expect(baz.format == "Format")
    }
  }
}

// MARK: Long option with empty value (issue #958)

private struct LongOptionWithFile: ParsableArguments {
  @Option(name: .long) var out: String
  @Argument var file: String
}

private struct LongOptionWithOptionalString: ParsableArguments {
  @Option(name: [.short, .long]) var name: String?
  @Argument var file: String
}

// https://github.com/apple/swift-argument-parser/issues/958
extension EqualsEndToEndTests {
  /// `--out=` must accept an explicit empty-string value.
  ///
  /// The following positional `file.txt` must remain a positional argument.
  func testLongOptionEmptyValueDoesNotConsumePositional() throws {
    AssertParse(LongOptionWithFile.self, ["--out=", "file.txt"]) { parsed in
      XCTAssertEqual(parsed.out, "")
      XCTAssertEqual(parsed.file, "file.txt")
    }
  }

  /// `--out=value` (non-empty) must behave as before.
  func testLongOptionNonEmptyValueUnchanged() throws {
    AssertParse(LongOptionWithFile.self, ["--out=output.txt", "file.txt"]) { parsed in
      XCTAssertEqual(parsed.out, "output.txt")
      XCTAssertEqual(parsed.file, "file.txt")
    }
  }

  /// `--out` (no `=`) followed by value token must still work.
  func testLongOptionSeparateValueUnchanged() throws {
    AssertParse(LongOptionWithFile.self, ["--out", "output.txt", "file.txt"]) { parsed in
      XCTAssertEqual(parsed.out, "output.txt")
      XCTAssertEqual(parsed.file, "file.txt")
    }
  }

  /// Short option `-o=` must similarly keep its existing empty-value behaviour.
  func testShortOptionEmptyValueConsistent() throws {
    AssertParse(LongOptionWithOptionalString.self, ["-n=", "file.txt"]) { parsed in
      XCTAssertEqual(parsed.name, "")
      XCTAssertEqual(parsed.file, "file.txt")
    }
  }
}
