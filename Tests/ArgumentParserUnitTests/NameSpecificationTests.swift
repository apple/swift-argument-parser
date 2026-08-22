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

import Testing

@testable import ArgumentParser

@Suite struct NameSpecificationTests {}

// swift-format-ignore: AlwaysUseLowerCamelCase
// https://github.com/apple/swift-argument-parser/issues/710
extension NameSpecificationTests {
  @Test func flagNames_withNoPrefix() {
    let key = InputKey(name: "index", parent: nil)

    #expect(
      FlagInversion.prefixedNo.enableDisableNamePair(
        for: key, name: .long
      ).1 == [.long("no-index")])
    #expect(
      FlagInversion.prefixedNo.enableDisableNamePair(
        for: key, name: .customLong("foo")
      ).1 == [.long("no-foo")])
    #expect(
      FlagInversion.prefixedNo.enableDisableNamePair(
        for: key, name: .customLong("foo-bar-baz")
      ).1 == [.long("no-foo-bar-baz")])
    #expect(
      FlagInversion.prefixedNo.enableDisableNamePair(
        for: key, name: .customLong("foo_bar_baz")
      ).1 == [.long("no_foo_bar_baz")])
    #expect(
      FlagInversion.prefixedNo.enableDisableNamePair(
        for: key, name: .customLong("fooBarBaz")
      ).1 == [.long("noFooBarBaz")])

    // Short names don't work in combination
    #expect(
      FlagInversion.prefixedNo.enableDisableNamePair(
        for: key, name: .short
      ).1 == [])
  }

  @Test func flagNames_withEnableDisablePrefix() {
    let key = InputKey(name: "index", parent: nil)
    #expect(
      FlagInversion.prefixedEnableDisable.enableDisableNamePair(
        for: key, name: .long
      ).0 == [.long("enable-index")])
    #expect(
      FlagInversion.prefixedEnableDisable.enableDisableNamePair(
        for: key, name: .long
      ).1 == [.long("disable-index")])

    #expect(
      FlagInversion.prefixedEnableDisable.enableDisableNamePair(
        for: key, name: .customLong("foo")
      ).0 == [.long("enable-foo")])
    #expect(
      FlagInversion.prefixedEnableDisable.enableDisableNamePair(
        for: key, name: .customLong("foo")
      ).1 == [.long("disable-foo")])

    #expect(
      FlagInversion.prefixedEnableDisable.enableDisableNamePair(
        for: key, name: .customLong("foo-bar-baz")
      ).0 == [.long("enable-foo-bar-baz")])
    #expect(
      FlagInversion.prefixedEnableDisable.enableDisableNamePair(
        for: key, name: .customLong("foo-bar-baz")
      ).1 == [.long("disable-foo-bar-baz")])
    #expect(
      FlagInversion.prefixedEnableDisable.enableDisableNamePair(
        for: key, name: .customLong("foo_bar_baz")
      ).0 == [.long("enable_foo_bar_baz")])
    #expect(
      FlagInversion.prefixedEnableDisable.enableDisableNamePair(
        for: key, name: .customLong("foo_bar_baz")
      ).1 == [.long("disable_foo_bar_baz")])
    #expect(
      FlagInversion.prefixedEnableDisable.enableDisableNamePair(
        for: key, name: .customLong("fooBarBaz")
      ).0 == [.long("enableFooBarBaz")])
    #expect(
      FlagInversion.prefixedEnableDisable.enableDisableNamePair(
        for: key, name: .customLong("fooBarBaz")
      ).1 == [.long("disableFooBarBaz")])

    // Short names don't work in combination
    #expect(
      FlagInversion.prefixedEnableDisable.enableDisableNamePair(
        for: key, name: .short
      ).1 == [])
  }
}

private func expectNames(
  nameSpecification: NameSpecification,
  key: String,
  parent: InputKey? = nil,
  makeNames expected: [Name],
  sourceLocation: SourceLocation = #_sourceLocation
) {
  let names = nameSpecification.makeNames(InputKey(name: key, parent: parent))
  expectNames(
    names: names, expected: expected, sourceLocation: sourceLocation)
}

private func expectNames<N>(
  names: [N], expected: [N],
  sourceLocation: SourceLocation = #_sourceLocation
) where N: Equatable {
  for name in names {
    #expect(
      expected.contains(name),
      "Unexpected name '\(name)'.",
      sourceLocation: sourceLocation)
  }
  for expected in expected {
    #expect(
      names.contains(expected),
      "Missing name '\(expected)'.",
      sourceLocation: sourceLocation)
  }
}

private func expectInvalid(
  nameSpecification: NameSpecification,
  sourceLocation: SourceLocation = #_sourceLocation
) {
  #expect(
    nameSpecification.elements.contains(where: {
      if case .invalidLiteral = $0.base { return true } else { return false }
    }),
    "Expected invalid name.",
    sourceLocation: sourceLocation)
}

// swift-format-ignore: AlwaysUseLowerCamelCase
// https://github.com/apple/swift-argument-parser/issues/710
extension NameSpecificationTests {
  @Test func makeNames_short() {
    expectNames(nameSpecification: .short, key: "foo", makeNames: [.short("f")])
  }

  @Test func makeNames_Long() {
    expectNames(
      nameSpecification: .long, key: "fooBarBaz",
      makeNames: [.long("foo-bar-baz")])
    expectNames(
      nameSpecification: .long, key: "fooURLForBarBaz",
      makeNames: [.long("foo-url-for-bar-baz")])
  }

  @Test func makeNames_customLong() {
    expectNames(
      nameSpecification: .customLong("bar"), key: "foo",
      makeNames: [.long("bar")])
  }

  @Test func makeNames_customShort() {
    expectNames(
      nameSpecification: .customShort("v"), key: "foo",
      makeNames: [.short("v")]
    )
  }

  @Test func makeNames_customLongWithSingleDash() {
    expectNames(
      nameSpecification: .customLong("baz", withSingleDash: true), key: "foo",
      makeNames: [.longWithSingleDash("baz")])
  }

  @Test func makeNames_shortLiteral() {
    expectNames(nameSpecification: "-x", key: "foo", makeNames: [.short("x")])
    expectNames(nameSpecification: ["-x"], key: "foo", makeNames: [.short("x")])
  }

  @Test func makeNames_longLiteral() {
    expectNames(
      nameSpecification: "--foo", key: "foo", makeNames: [.long("foo")])
    expectNames(
      nameSpecification: ["--foo"], key: "foo", makeNames: [.long("foo")])
    expectNames(
      nameSpecification: "--foo-bar-baz", key: "foo",
      makeNames: [.long("foo-bar-baz")])
    expectNames(
      nameSpecification: "--fooBarBAZ", key: "foo",
      makeNames: [.long("fooBarBAZ")])
  }

  @Test func makeNames_longWithSingleDashLiteral() {
    expectNames(
      nameSpecification: "-foo", key: "foo",
      makeNames: [.longWithSingleDash("foo")])
    expectNames(
      nameSpecification: ["-foo"], key: "foo",
      makeNames: [.longWithSingleDash("foo")])
    expectNames(
      nameSpecification: "-foo-bar-baz", key: "foo",
      makeNames: [.longWithSingleDash("foo-bar-baz")])
    expectNames(
      nameSpecification: "-fooBarBAZ", key: "foo",
      makeNames: [.longWithSingleDash("fooBarBAZ")])
  }

  @Test func makeNames_combinedLiteral() {
    expectNames(
      nameSpecification: "-x -y --zilch", key: "foo",
      makeNames: [.short("x"), .short("y"), .long("zilch")])
    expectNames(
      nameSpecification: "     -x       -y       ", key: "foo",
      makeNames: [.short("x"), .short("y")])
    expectNames(
      nameSpecification: ["-x", "-y", "--zilch"], key: "foo",
      makeNames: [.short("x"), .short("y"), .long("zilch")])
  }

  @Test func makeNames_interpolations() {
    let x = "x"
    expectNames(
      nameSpecification: ["-\(x)"], key: "foo", makeNames: [.short("x")])
    expectNames(
      nameSpecification: ["--\(x)"], key: "foo", makeNames: [.long("x")])
    expectNames(
      nameSpecification: ["-\(x)\(x)\(x)"], key: "foo",
      makeNames: [.longWithSingleDash("xxx")])
    expectNames(
      nameSpecification: "-\(x)", key: "foo", makeNames: [.short("x")])
    expectNames(
      nameSpecification: "--\(x)", key: "foo", makeNames: [.long("x")])
    expectNames(
      nameSpecification: "-\(x)\(x)\(x)", key: "foo",
      makeNames: [.longWithSingleDash("xxx")])
  }

  @Test func makeNames_literalFailures() {
    // Empty string and whitespace-only
    expectInvalid(nameSpecification: "")
    expectInvalid(nameSpecification: " ")
    expectInvalid(nameSpecification: "   ")
    // No dash prefix
    expectInvalid(nameSpecification: "x")
    // Dash prefix only
    expectInvalid(nameSpecification: "-")
    expectInvalid(nameSpecification: "--")
    expectInvalid(nameSpecification: "---")
    // Triple dash
    expectInvalid(nameSpecification: "---x")
    // Invalid characters
    expectInvalid(nameSpecification: "--café")
    expectInvalid(nameSpecification: "--c!f!")

    // Repeating as elements
    expectInvalid(nameSpecification: [""])
    expectInvalid(nameSpecification: ["x"])
    expectInvalid(nameSpecification: ["-"])
    expectInvalid(nameSpecification: ["--"])
    expectInvalid(nameSpecification: ["---"])
    expectInvalid(nameSpecification: ["---x"])
    expectInvalid(nameSpecification: ["--café"])

    // Spaces in _elements_, not the top level literal
    expectInvalid(nameSpecification: ["-x -y -z"])
    expectInvalid(nameSpecification: ["-x", "-y", " -z"])
  }
}
