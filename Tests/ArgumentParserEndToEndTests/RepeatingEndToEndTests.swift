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
import Foundation
import Testing

@Suite struct RepeatingEndToEndTests {}

// MARK: -

private struct Bar: ParsableArguments {
  @Option() var name: [String] = []
}

// swift-format-ignore: AlwaysUseLowerCamelCase
extension RepeatingEndToEndTests {
  @Test func parsing_repeatingString() throws {
    expectParse(Bar.self, []) { bar in
      #expect(bar.name.isEmpty)
    }

    expectParse(Bar.self, ["--name", "Bar"]) { bar in
      #expect(bar.name.count == 1)
      #expect(bar.name.first == "Bar")
    }

    expectParse(Bar.self, ["--name", "Bar", "--name", "Foo"]) { bar in
      #expect(bar.name.count == 2)
      #expect(bar.name.first == "Bar")
      #expect(bar.name.last == "Foo")
    }
  }
}

// MARK: -

private struct Foo: ParsableArguments {
  @Flag()
  var verbose: Int
}

// swift-format-ignore: AlwaysUseLowerCamelCase
extension RepeatingEndToEndTests {
  @Test func parsing_incrementInteger() throws {
    expectParse(Foo.self, []) { options in
      #expect(options.verbose == 0)
    }
    expectParse(Foo.self, ["--verbose"]) { options in
      #expect(options.verbose == 1)
    }
    expectParse(Foo.self, ["--verbose", "--verbose"]) { options in
      #expect(options.verbose == 2)
    }
  }
}

// MARK: -

private struct Baz: ParsableArguments {
  @Flag var verbose: Bool = false
  @Option(parsing: .remaining) var names: [String] = []
}

// swift-format-ignore: AlwaysUseLowerCamelCase
extension RepeatingEndToEndTests {
  @Test func parsing_repeatingStringRemaining_1() {
    expectParse(Baz.self, []) { baz in
      #expect(!baz.verbose)
      #expect(baz.names.isEmpty)
    }
  }

  @Test func parsing_repeatingStringRemaining_2() {
    expectParse(Baz.self, ["--names"]) { baz in
      #expect(!baz.verbose)
      #expect(baz.names.isEmpty)
    }
  }

  @Test func parsing_repeatingStringRemaining_3() {
    expectParse(Baz.self, ["--names", "one"]) { baz in
      #expect(!baz.verbose)
      #expect(baz.names == ["one"])
    }
  }

  @Test func parsing_repeatingStringRemaining_4() {
    expectParse(Baz.self, ["--names", "one", "two"]) { baz in
      #expect(!baz.verbose)
      #expect(baz.names == ["one", "two"])
    }
  }

  @Test func parsing_repeatingStringRemaining_5() {
    expectParse(Baz.self, ["--verbose", "--names", "one", "two"]) { baz in
      #expect(baz.verbose)
      #expect(baz.names == ["one", "two"])
    }
  }

  @Test func parsing_repeatingStringRemaining_6() {
    expectParse(Baz.self, ["--names", "one", "two", "--verbose"]) { baz in
      #expect(!baz.verbose)
      #expect(baz.names == ["one", "two", "--verbose"])
    }
  }

  @Test func parsing_repeatingStringRemaining_7() {
    expectParse(Baz.self, ["--verbose", "--names", "one", "two", "--verbose"]) {
      baz in
      #expect(baz.verbose)
      #expect(baz.names == ["one", "two", "--verbose"])
    }
  }

  @Test func parsing_repeatingStringRemaining_8() {
    expectParse(
      Baz.self,
      ["--verbose", "--names", "one", "two", "--verbose", "--other", "three"]
    ) { baz in
      #expect(baz.verbose)
      #expect(baz.names == ["one", "two", "--verbose", "--other", "three"])
    }
  }
}

// MARK: -

private struct Outer: ParsableCommand {
  static let configuration = CommandConfiguration(subcommands: [Inner.self])
}

private struct Inner: ParsableCommand {
  @Flag
  var verbose: Bool = false

  @Argument(parsing: .captureForPassthrough)
  var files: [String] = []
}

// swift-format-ignore: AlwaysUseLowerCamelCase
extension RepeatingEndToEndTests {
  @Test func parsing_subcommandRemaining() {
    expectParseCommand(
      Outer.self, Inner.self,
      ["inner", "--verbose", "one", "two", "--", "three", "--other"]
    ) { inner in
      #expect(inner.verbose)
      #expect(inner.files == ["one", "two", "--", "three", "--other"])
    }
  }
}

// MARK: -

private struct Qux: ParsableArguments {
  @Option(parsing: .upToNextOption) var names: [String] = []
  @Flag var verbose: Bool = false
  @Argument() var extra: String?
}

// swift-format-ignore: AlwaysUseLowerCamelCase
extension RepeatingEndToEndTests {
  @Test func parsing_repeatingStringUpToNext() throws {
    expectParse(Qux.self, []) { qux in
      #expect(!qux.verbose)
      #expect(qux.names.isEmpty)
      #expect(qux.extra == nil)
    }

    expectParse(Qux.self, ["--names", "one"]) { qux in
      #expect(!qux.verbose)
      #expect(qux.names == ["one"])
      #expect(qux.extra == nil)
    }

    expectParse(
      Qux.self,
      [
        "--names", "one", "two", "--verbose", "--names", "three", "--names",
        "four",
      ]
    ) { qux in
      #expect(qux.verbose)
      #expect(qux.names == ["one", "two", "three", "four"])
      #expect(qux.extra == nil)
    }

    expectParse(
      Qux.self,
      [
        "extra", "--names", "one", "--names", "two", "--verbose", "--names",
        "three", "four",
      ]
    ) { qux in
      #expect(qux.verbose)
      #expect(qux.names == ["one", "two", "three", "four"])
      #expect(qux.extra == "extra")
    }

    expectParse(Qux.self, ["--names", "one", "two"]) { qux in
      #expect(!qux.verbose)
      #expect(qux.names == ["one", "two"])
      #expect(qux.extra == nil)
    }

    expectParse(Qux.self, ["--names", "one", "two", "--verbose"]) { qux in
      #expect(qux.verbose)
      #expect(qux.names == ["one", "two"])
      #expect(qux.extra == nil)
    }

    expectParse(Qux.self, ["--names", "one", "two", "--verbose", "three"]) {
      qux in
      #expect(qux.verbose)
      #expect(qux.names == ["one", "two"])
      #expect(qux.extra == "three")
    }

    expectParse(Qux.self, ["--verbose", "--names", "one", "two"]) { qux in
      #expect(qux.verbose)
      #expect(qux.names == ["one", "two"])
      #expect(qux.extra == nil)
    }

    expectParse(Qux.self, ["--verbose", "--names=one"]) { qux in
      #expect(qux.verbose)
      #expect(qux.names == ["one"])
      #expect(qux.extra == nil)
    }

    expectParse(Qux.self, ["--verbose", "--names=one", "two"]) { qux in
      #expect(qux.verbose)
      #expect(qux.names == ["one", "two"])
      #expect(qux.extra == nil)
    }

    expectParse(Qux.self, ["--names=one", "--verbose", "two"]) { qux in
      #expect(qux.verbose)
      #expect(qux.names == ["one"])
      #expect(qux.extra == "two")
    }
  }

  @Test func parsing_repeatingStringUpToNext_Fails() throws {
    #expect(throws: (any Error).self) {
      try Qux.parse(["--names", "one", "--other"])
    }
    #expect(throws: (any Error).self) {
      try Qux.parse(["--names", "one", "two", "--other"])
    }
    #expect(throws: (any Error).self) { try Qux.parse(["--names", "--other"]) }
    #expect(throws: (any Error).self) {
      try Qux.parse(["--names", "--verbose"])
    }
    #expect(throws: (any Error).self) {
      try Qux.parse(["--names", "--verbose", "three"])
    }
  }
}

// MARK: -

private struct Wobble: ParsableArguments {
  struct WobbleError: Error {}
  struct Name: Equatable, Sendable {
    var value: String

    init(_ value: String) throws {
      if value == "bad" { throw WobbleError() }
      self.value = value
    }
  }
  @Option(transform: Name.init) var names: [Name] = []
  @Option(parsing: .upToNextOption, transform: Name.init) var moreNames:
    [Name] = []
  @Option(parsing: .remaining, transform: Name.init) var evenMoreNames: [Name] =
    []
}

// swift-format-ignore: AlwaysUseLowerCamelCase
extension RepeatingEndToEndTests {
  @Test func parsing_repeatingWithTransform() throws {
    let names = ["--names", "one", "--names", "two"]
    let moreNames = ["--more-names", "three", "four", "five"]
    let evenMoreNames = ["--even-more-names", "six", "--seven", "--eight"]

    expectParse(Wobble.self, []) { wobble in
      #expect(wobble.names.isEmpty)
      #expect(wobble.moreNames.isEmpty)
      #expect(wobble.evenMoreNames.isEmpty)
    }

    expectParse(Wobble.self, names) { wobble in
      #expect(wobble.names.map { $0.value } == ["one", "two"])
      #expect(wobble.moreNames.isEmpty)
      #expect(wobble.evenMoreNames.isEmpty)
    }

    expectParse(Wobble.self, moreNames) { wobble in
      #expect(wobble.names.isEmpty)
      #expect(wobble.moreNames.map { $0.value } == ["three", "four", "five"])
      #expect(wobble.evenMoreNames.isEmpty)
    }

    expectParse(Wobble.self, evenMoreNames) { wobble in
      #expect(wobble.names.isEmpty)
      #expect(wobble.moreNames.isEmpty)
      #expect(
        wobble.evenMoreNames.map { $0.value } == ["six", "--seven", "--eight"])
    }

    expectParse(Wobble.self, Array([names, moreNames, evenMoreNames].joined()))
    { wobble in
      #expect(wobble.names.map { $0.value } == ["one", "two"])
      #expect(wobble.moreNames.map { $0.value } == ["three", "four", "five"])
      #expect(
        wobble.evenMoreNames.map { $0.value } == ["six", "--seven", "--eight"])
    }

    expectParse(Wobble.self, Array([moreNames, names, evenMoreNames].joined()))
    { wobble in
      #expect(wobble.names.map { $0.value } == ["one", "two"])
      #expect(wobble.moreNames.map { $0.value } == ["three", "four", "five"])
      #expect(
        wobble.evenMoreNames.map { $0.value } == ["six", "--seven", "--eight"])
    }

    expectParse(Wobble.self, Array([moreNames, evenMoreNames, names].joined()))
    { wobble in
      #expect(wobble.names.isEmpty)
      #expect(wobble.moreNames.map { $0.value } == ["three", "four", "five"])
      #expect(
        wobble.evenMoreNames.map { $0.value }
          == ["six", "--seven", "--eight", "--names", "one", "--names", "two"])
    }
  }

  @Test func parsing_repeatingWithTransform_Fails() throws {
    #expect(throws: (any Error).self) {
      try Wobble.parse(["--names", "one", "--other"])
    }
    #expect(throws: (any Error).self) {
      try Wobble.parse(["--more-names", "one", "--other"])
    }

    #expect(throws: (any Error).self) {
      try Wobble.parse(["--names", "one", "--names", "bad"])
    }
    #expect(throws: (any Error).self) {
      try Wobble.parse(["--more-names", "one", "two", "bad", "--names", "one"])
    }
    #expect(throws: (any Error).self) {
      try Wobble.parse([
        "--even-more-names", "one", "two", "--names", "one", "bad",
      ])
    }
  }
}

// MARK: -

private struct Weazle: ParsableArguments {
  @Flag var verbose: Bool = false
  @Argument() var names: [String] = []
}

// swift-format-ignore: AlwaysUseLowerCamelCase
extension RepeatingEndToEndTests {
  @Test func parsing_repeatingArgument() throws {
    expectParse(Weazle.self, ["one", "two", "three", "--verbose"]) { weazle in
      #expect(weazle.verbose)
      #expect(weazle.names == ["one", "two", "three"])
    }

    expectParse(Weazle.self, ["--verbose", "one", "two", "three"]) { weazle in
      #expect(weazle.verbose)
      #expect(weazle.names == ["one", "two", "three"])
    }

    expectParse(
      Weazle.self, ["one", "two", "three", "--", "--other", "--verbose"]
    ) { weazle in
      #expect(!weazle.verbose)
      #expect(weazle.names == ["one", "two", "three", "--other", "--verbose"])
    }
  }
}

// MARK: -

struct PerformanceTest: ParsableCommand {
  @Option(name: .short) var bundleIdentifiers: [String] = []

  mutating func run() throws { print(bundleIdentifiers) }
}

private func argumentGenerator(_ count: Int) -> [String] {
  Array((1...count).map { ["-b", "bundle-id\($0)"] }.joined())
}

private func time(_ body: () -> Void) -> TimeInterval {
  let start = Date()
  body()
  return Date().timeIntervalSince(start)
}

// swift-format-ignore: AlwaysUseLowerCamelCase
extension RepeatingEndToEndTests {
  // A regression test against array parsing performance going non-linear.
  @Test func parsing_repeatingPerformance() throws {
    let timeFor20 = time {
      expectParse(PerformanceTest.self, argumentGenerator(100)) { test in
        #expect(test.bundleIdentifiers.count == 100)
      }
    }
    let timeFor40 = time {
      expectParse(PerformanceTest.self, argumentGenerator(200)) { test in
        #expect(test.bundleIdentifiers.count == 200)
      }
    }

    #expect(timeFor40 < timeFor20 * 10)
  }
}
