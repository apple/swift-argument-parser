//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import XCTest

@testable import ArgumentParser

final class NameSpecificationTests: XCTestCase {}

// swift-format-ignore: AlwaysUseLowerCamelCase
// https://github.com/apple/swift-argument-parser/issues/710
extension NameSpecificationTests {
  func testFlagNames_withNoPrefix() {
    let key = InputKey(name: "index", parent: nil)

    XCTAssertEqual(
      FlagInversion.prefixedNo.enableDisableNamePair(
        for: key, name: .long
      ).1, [.long("no-index")])
    XCTAssertEqual(
      FlagInversion.prefixedNo.enableDisableNamePair(
        for: key, name: .customLong("foo")
      ).1, [.long("no-foo")])
    XCTAssertEqual(
      FlagInversion.prefixedNo.enableDisableNamePair(
        for: key, name: .customLong("foo-bar-baz")
      ).1, [.long("no-foo-bar-baz")])
    XCTAssertEqual(
      FlagInversion.prefixedNo.enableDisableNamePair(
        for: key, name: .customLong("foo_bar_baz")
      ).1, [.long("no_foo_bar_baz")])
    XCTAssertEqual(
      FlagInversion.prefixedNo.enableDisableNamePair(
        for: key, name: .customLong("fooBarBaz")
      ).1, [.long("noFooBarBaz")])

    // Short names don't work in combination
    XCTAssertEqual(
      FlagInversion.prefixedNo.enableDisableNamePair(
        for: key, name: .short
      ).1, [])
  }

  func testFlagNames_withEnableDisablePrefix() {
    let key = InputKey(name: "index", parent: nil)
    XCTAssertEqual(
      FlagInversion.prefixedEnableDisable.enableDisableNamePair(
        for: key, name: .long
      ).0, [.long("enable-index")])
    XCTAssertEqual(
      FlagInversion.prefixedEnableDisable.enableDisableNamePair(
        for: key, name: .long
      ).1, [.long("disable-index")])

    XCTAssertEqual(
      FlagInversion.prefixedEnableDisable.enableDisableNamePair(
        for: key, name: .customLong("foo")
      ).0, [.long("enable-foo")])
    XCTAssertEqual(
      FlagInversion.prefixedEnableDisable.enableDisableNamePair(
        for: key, name: .customLong("foo")
      ).1, [.long("disable-foo")])

    XCTAssertEqual(
      FlagInversion.prefixedEnableDisable.enableDisableNamePair(
        for: key, name: .customLong("foo-bar-baz")
      ).0, [.long("enable-foo-bar-baz")])
    XCTAssertEqual(
      FlagInversion.prefixedEnableDisable.enableDisableNamePair(
        for: key, name: .customLong("foo-bar-baz")
      ).1, [.long("disable-foo-bar-baz")])
    XCTAssertEqual(
      FlagInversion.prefixedEnableDisable.enableDisableNamePair(
        for: key, name: .customLong("foo_bar_baz")
      ).0, [.long("enable_foo_bar_baz")])
    XCTAssertEqual(
      FlagInversion.prefixedEnableDisable.enableDisableNamePair(
        for: key, name: .customLong("foo_bar_baz")
      ).1, [.long("disable_foo_bar_baz")])
    XCTAssertEqual(
      FlagInversion.prefixedEnableDisable.enableDisableNamePair(
        for: key, name: .customLong("fooBarBaz")
      ).0, [.long("enableFooBarBaz")])
    XCTAssertEqual(
      FlagInversion.prefixedEnableDisable.enableDisableNamePair(
        for: key, name: .customLong("fooBarBaz")
      ).1, [.long("disableFooBarBaz")])

    // Short names don't work in combination
    XCTAssertEqual(
      FlagInversion.prefixedEnableDisable.enableDisableNamePair(
        for: key, name: .short
      ).1, [])
  }
}

// swift-format-ignore: AlwaysUseLowerCamelCase
private func Assert(
  nameSpecification: NameSpecification, key: String, parent: InputKey? = nil,
  makeNames expected: [Name], file: StaticString = #filePath, line: UInt = #line
) {
  let names = nameSpecification.makeNames(InputKey(name: key, parent: parent))
  Assert(names: names, expected: expected, file: file, line: line)
}

// swift-format-ignore: AlwaysUseLowerCamelCase
private func Assert<N>(
  names: [N], expected: [N], file: StaticString = #filePath, line: UInt = #line
) where N: Equatable {
  for name in names {
    XCTAssert(
      expected.contains(name), "Unexpected name '\(name)'.", file: file,
      line: line)
  }
  for expected in expected {
    XCTAssert(
      names.contains(expected), "Missing name '\(expected)'.", file: file,
      line: line)
  }
}

// swift-format-ignore: AlwaysUseLowerCamelCase
private func AssertInvalid(
  nameSpecification: NameSpecification,
  file: StaticString = #filePath,
  line: UInt = #line
) {
  XCTAssert(
    nameSpecification.elements.contains(where: {
      if case .invalidLiteral = $0.base { return true } else { return false }
    }), "Expected invalid name.",
    file: file, line: line)
}

// swift-format-ignore: AlwaysUseLowerCamelCase
// https://github.com/apple/swift-argument-parser/issues/710
extension NameSpecificationTests {
  func testMakeNames_short() {
    Assert(nameSpecification: .short, key: "foo", makeNames: [.short("f")])
  }

  func testMakeNames_Long() {
    Assert(
      nameSpecification: .long, key: "fooBarBaz",
      makeNames: [.long("foo-bar-baz")])
    Assert(
      nameSpecification: .long, key: "fooURLForBarBaz",
      makeNames: [.long("foo-url-for-bar-baz")])
  }

  func testMakeNames_customLong() {
    Assert(
      nameSpecification: .customLong("bar"), key: "foo",
      makeNames: [.long("bar")])
  }

  func testMakeNames_customShort() {
    Assert(
      nameSpecification: .customShort("v"), key: "foo", makeNames: [.short("v")]
    )
  }

  func testMakeNames_customLongWithSingleDash() {
    Assert(
      nameSpecification: .customLong("baz", withSingleDash: true), key: "foo",
      makeNames: [.longWithSingleDash("baz")])
  }

  func testMakeNames_shortLiteral() {
    Assert(nameSpecification: "-x", key: "foo", makeNames: [.short("x")])
    Assert(nameSpecification: ["-x"], key: "foo", makeNames: [.short("x")])
  }

  func testMakeNames_longLiteral() {
    Assert(nameSpecification: "--foo", key: "foo", makeNames: [.long("foo")])
    Assert(nameSpecification: ["--foo"], key: "foo", makeNames: [.long("foo")])
    Assert(
      nameSpecification: "--foo-bar-baz", key: "foo",
      makeNames: [.long("foo-bar-baz")])
    Assert(
      nameSpecification: "--fooBarBAZ", key: "foo",
      makeNames: [.long("fooBarBAZ")])
  }

  func testMakeNames_longWithSingleDashLiteral() {
    Assert(
      nameSpecification: "-foo", key: "foo",
      makeNames: [.longWithSingleDash("foo")])
    Assert(
      nameSpecification: ["-foo"], key: "foo",
      makeNames: [.longWithSingleDash("foo")])
    Assert(
      nameSpecification: "-foo-bar-baz", key: "foo",
      makeNames: [.longWithSingleDash("foo-bar-baz")])
    Assert(
      nameSpecification: "-fooBarBAZ", key: "foo",
      makeNames: [.longWithSingleDash("fooBarBAZ")])
  }

  func testMakeNames_combinedLiteral() {
    Assert(
      nameSpecification: "-x -y --zilch", key: "foo",
      makeNames: [.short("x"), .short("y"), .long("zilch")])
    Assert(
      nameSpecification: "     -x       -y       ", key: "foo",
      makeNames: [.short("x"), .short("y")])
    Assert(
      nameSpecification: ["-x", "-y", "--zilch"], key: "foo",
      makeNames: [.short("x"), .short("y"), .long("zilch")])
  }

  func testMakeNames_literalFailures() {
    // Empty string
    AssertInvalid(nameSpecification: "")
    // No dash prefix
    AssertInvalid(nameSpecification: "x")
    // Dash prefix only
    AssertInvalid(nameSpecification: "-")
    AssertInvalid(nameSpecification: "--")
    AssertInvalid(nameSpecification: "---")
    // Triple dash
    AssertInvalid(nameSpecification: "---x")
    // Non-ASCII
    AssertInvalid(nameSpecification: "--café")

    // Repeating as elements
    AssertInvalid(nameSpecification: [""])
    AssertInvalid(nameSpecification: ["x"])
    AssertInvalid(nameSpecification: ["-"])
    AssertInvalid(nameSpecification: ["--"])
    AssertInvalid(nameSpecification: ["---"])
    AssertInvalid(nameSpecification: ["---x"])
    AssertInvalid(nameSpecification: ["--café"])

    // Spaces in _elements_, not the top level literal
    AssertInvalid(nameSpecification: ["-x -y -z"])
    AssertInvalid(nameSpecification: ["-x", "-y", " -z"])
  }
}
