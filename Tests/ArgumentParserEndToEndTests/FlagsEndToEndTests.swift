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

@Suite struct FlagsEndToEndTests {}

// MARK: -

private struct Bar: ParsableArguments {
  @Flag
  var verbose: Bool = false

  @Flag(inversion: .prefixedNo)
  var extattr: Bool = false

  @Flag(inversion: .prefixedNo, exclusivity: .exclusive)
  var extattr2: Bool?

  @Flag(inversion: .prefixedEnableDisable, exclusivity: .chooseFirst)
  var logging: Bool = false
}

// swift-format-ignore: AlwaysUseLowerCamelCase
extension FlagsEndToEndTests {
  @Test func parsing_defaultValue() throws {
    expectParse(Bar.self, []) { options in
      #expect(options.verbose == false)
      #expect(options.extattr == false)
      #expect(options.extattr2 == nil)
    }
  }

  @Test func parsing_settingValue() throws {
    expectParse(Bar.self, ["--verbose"]) { options in
      #expect(options.verbose == true)
      #expect(options.extattr == false)
      #expect(options.extattr2 == nil)
    }

    expectParse(Bar.self, ["--extattr"]) { options in
      #expect(options.verbose == false)
      #expect(options.extattr == true)
      #expect(options.extattr2 == nil)
    }

    expectParse(Bar.self, ["--extattr2"]) { options in
      #expect(options.verbose == false)
      #expect(options.extattr == false)
      #expect(options.extattr2 == .some(true))
    }
  }

  @Test func parsing_invert() throws {
    expectParse(Bar.self, ["--no-extattr"]) { options in
      #expect(options.extattr == false)
    }
    expectParse(Bar.self, ["--extattr", "--no-extattr"]) { options in
      #expect(options.extattr == false)
    }
    expectParse(Bar.self, ["--extattr", "--no-extattr", "--no-extattr"]) {
      options in
      #expect(options.extattr == false)
    }
    expectParse(Bar.self, ["--no-extattr", "--no-extattr", "--extattr"]) {
      options in
      #expect(options.extattr == true)
    }
    expectParse(Bar.self, ["--extattr", "--no-extattr", "--extattr"]) {
      options in
      #expect(options.extattr == true)
    }
    expectParse(Bar.self, ["--enable-logging"]) { options in
      #expect(options.logging == true)
    }
    expectParse(Bar.self, ["--no-extattr2", "--no-extattr2"]) { options in
      #expect(options.extattr2 == false)
    }
    expectParse(Bar.self, ["--disable-logging", "--enable-logging"]) {
      options in
      #expect(options.logging == false)
    }
  }
}

private struct Foo: ParsableArguments {
  @Flag(inversion: .prefixedEnableDisable)
  var index: Bool = false
  @Flag(inversion: .prefixedEnableDisable)
  var sandbox: Bool = true
  @Flag(inversion: .prefixedEnableDisable)
  var requiredElement: Bool
  @Flag(inversion: .prefixedEnableDisable)
  var optional: Bool? = nil
}

// swift-format-ignore: AlwaysUseLowerCamelCase
extension FlagsEndToEndTests {
  @Test func parsingEnableDisable_defaultValue() throws {
    expectParse(Foo.self, ["--enable-required-element"]) { options in
      #expect(options.index == false)
      #expect(options.sandbox == true)
      #expect(options.requiredElement == true)
      #expect(options.optional == nil)
    }
  }

  @Test func parsingEnableDisable_disableAll() throws {
    expectParse(
      Foo.self,
      [
        "--disable-index", "--disable-sandbox", "--disable-required-element",
        "--disable-optional",
      ]
    ) { options in
      #expect(options.index == false)
      #expect(options.sandbox == false)
      #expect(options.requiredElement == false)
      #expect(options.optional == false)
    }
  }

  @Test func parsingEnableDisable_enableAll() throws {
    expectParse(
      Foo.self,
      [
        "--enable-index", "--enable-sandbox", "--enable-required-element",
        "--enable-optional",
      ]
    ) { options in
      #expect(options.index == true)
      #expect(options.sandbox == true)
      #expect(options.requiredElement == true)
      #expect(options.optional == true)
    }
  }

  @Test func parsingEnableDisable_Fails() throws {
    #expect(throws: (any Error).self) { try Foo.parse([]) }
    #expect(throws: (any Error).self) { try Foo.parse(["--disable-index"]) }
    #expect(throws: (any Error).self) { try Foo.parse(["--disable-sandbox"]) }
  }
}

enum Color: String, EnumerableFlag {
  case pink
  case purple
  case silver
}

enum Size: String, EnumerableFlag {
  case small
  case medium
  case large
  case extraLarge
  case humongous

  static func name(for value: Size) -> NameSpecification {
    switch value {
    case .small, .medium, .large:
      return .shortAndLong
    case .humongous:
      return [.long, .customLong("huge")]
    default:
      return .long
    }
  }

  static func help(for value: Size) -> ArgumentHelp? {
    switch value {
    case .small:
      return "A smallish size."
    case .medium:
      return "Not too big, not too small."
    case .humongous:
      return "Roughly the size of a barge."
    case .large, .extraLarge:
      return nil
    }
  }
}

enum Shape: String, EnumerableFlag {
  case round
  case square
  case oblong
}

private struct Baz: ParsableArguments {
  @Flag()
  var color: Color

  @Flag(help: "The size to use.")
  var size: Size = .small

  @Flag()
  var shape: Shape?
}

// swift-format-ignore: AlwaysUseLowerCamelCase
extension FlagsEndToEndTests {
  @Test func parsingCaseIterable_defaultValues() throws {
    expectParse(Baz.self, ["--pink"]) { options in
      #expect(options.color == .pink)
      #expect(options.size == .small)
      #expect(options.shape == nil)
    }

    expectParse(Baz.self, ["--pink", "--medium"]) { options in
      #expect(options.color == .pink)
      #expect(options.size == .medium)
      #expect(options.shape == nil)
    }

    expectParse(Baz.self, ["--pink", "--round"]) { options in
      #expect(options.color == .pink)
      #expect(options.size == .small)
      #expect(options.shape == .round)
    }
  }

  @Test func parsingCaseIterable_AllValues() throws {
    expectParse(Baz.self, ["--pink", "--small", "--round"]) { options in
      #expect(options.color == .pink)
      #expect(options.size == .small)
      #expect(options.shape == .round)
    }

    expectParse(Baz.self, ["--purple", "--medium", "--square"]) { options in
      #expect(options.color == .purple)
      #expect(options.size == .medium)
      #expect(options.shape == .square)
    }

    expectParse(Baz.self, ["--silver", "--large", "--oblong"]) { options in
      #expect(options.color == .silver)
      #expect(options.size == .large)
      #expect(options.shape == .oblong)
    }
  }

  @Test func parsingCaseIterable_CustomName() throws {
    expectParse(Baz.self, ["--pink", "--extra-large"]) { options in
      #expect(options.color == .pink)
      #expect(options.size == .extraLarge)
      #expect(options.shape == nil)
    }

    expectParse(Baz.self, ["--pink", "--huge"]) { options in
      #expect(options.color == .pink)
      #expect(options.size == .humongous)
      #expect(options.shape == nil)
    }

    expectParse(Baz.self, ["--pink", "--humongous"]) { options in
      #expect(options.color == .pink)
      #expect(options.size == .humongous)
      #expect(options.shape == nil)
    }

    expectParse(Baz.self, ["--pink", "--huge", "--humongous"]) { options in
      #expect(options.color == .pink)
      #expect(options.size == .humongous)
      #expect(options.shape == nil)
    }
  }

  @Test func parsingCaseIterable_Help() async throws {
    try requireHelp(
      .default, for: Baz.self,
      equals: """
        USAGE: baz --pink --purple --silver [--small] [--medium] [--large] [--extra-large] [--humongous] [--round] [--square] [--oblong]

        OPTIONS:
          --pink/--purple/--silver
          -s, --small             A smallish size. (default: --small)
          -m, --medium            Not too big, not too small.
          -l, --large             The size to use.
          --extra-large           The size to use.
          --humongous, --huge     Roughly the size of a barge.
          --round/--square/--oblong
          -h, --help              Show help information.

        """)
  }

  @Test func parsingCaseIterable_Fails() throws {
    // Missing color
    #expect(throws: (any Error).self) { try Baz.parse([]) }
    #expect(throws: (any Error).self) {
      try Baz.parse(["--large", "--square"])
    }
    // Repeating flags
    #expect(throws: (any Error).self) {
      try Baz.parse(["--pink", "--purple"])
    }
    #expect(throws: (any Error).self) {
      try Baz.parse(["--pink", "--small", "--large"])
    }
    #expect(throws: (any Error).self) {
      try Baz.parse(["--pink", "--round", "--square"])
    }
    // Case name instead of raw value
    #expect(throws: (any Error).self) {
      try Baz.parse(["--pink", "--extraLarge"])
    }
  }
}

private struct Qux: ParsableArguments {
  @Flag()
  var color: [Color] = []

  @Flag()
  var size: [Size] = [.small, .medium]
}

// swift-format-ignore: AlwaysUseLowerCamelCase
extension FlagsEndToEndTests {
  @Test func parsingCaseIterableArray_Values() throws {
    expectParse(Qux.self, []) { options in
      #expect(options.color == [])
      #expect(options.size == [.small, .medium])
    }
    expectParse(Qux.self, ["--pink"]) { options in
      #expect(options.color == [.pink])
      #expect(options.size == [.small, .medium])
    }
    expectParse(Qux.self, ["--pink", "--purple", "--small"]) { options in
      #expect(options.color == [.pink, .purple])
      #expect(options.size == [.small])
    }
    expectParse(Qux.self, ["--pink", "--small", "--purple", "--medium"]) {
      options in
      #expect(options.color == [.pink, .purple])
      #expect(options.size == [.small, .medium])
    }
    expectParse(Qux.self, ["--pink", "--pink", "--purple", "--pink"]) {
      options in
      #expect(options.color == [.pink, .pink, .purple, .pink])
      #expect(options.size == [.small, .medium])
    }
  }

  @Test func parsingCaseIterableArray_Fails() throws {
    #expect(throws: (any Error).self) {
      try Qux.parse(["--pink", "--small", "--bloop"])
    }
  }
}

private struct RepeatOK: ParsableArguments {
  @Flag(exclusivity: .chooseFirst)
  var color: Color

  @Flag(exclusivity: .chooseLast)
  var shape: Shape

  @Flag(exclusivity: .exclusive)
  var size: Size = .small
}

// swift-format-ignore: AlwaysUseLowerCamelCase
extension FlagsEndToEndTests {
  @Test func parsingCaseIterable_RepeatableFlags() throws {
    expectParse(RepeatOK.self, ["--pink", "--purple", "--square"]) { options in
      #expect(options.color == .pink)
      #expect(options.shape == .square)
    }

    expectParse(RepeatOK.self, ["--round", "--oblong", "--silver"]) { options in
      #expect(options.color == .silver)
      #expect(options.shape == .oblong)
    }

    expectParse(RepeatOK.self, ["--large", "--pink", "--round", "-l"]) {
      options in
      #expect(options.size == .large)
    }
  }
}
