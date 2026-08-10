//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import Testing

@testable import ArgumentParser

@Suite struct MirrorTests {
  private struct Foo {
    let foo: String?
    let bar: String
    let baz: String!
  }

  @Test(
    arguments: [
      (foo: "foo", baz: "baz"),
      (foo: "foo", baz: nil),
      (foo: nil, baz: "baz"),
      (foo: nil, baz: nil),
    ] as [(String?, String?)]
  ) func testRealValue(foo: String?, baz: String?) async throws {

    func checkChildValue(_ child: Mirror.Child, expectedString: String?) {
      if let expectedString = expectedString {
        guard let stringValue = child.value as? String else {
          Issue.record("child.value is not a String type")
          return
        }
        #expect(stringValue == expectedString)
      } else {
        #expect(nilOrValue(child.value) == nil)
        // This is why we use `unwrapedOptionalValue` for optionality checks
        // Even though the `value` is `nil` this returns `false`
        #expect(child.value as Any? != nil)
      }
    }
    let fooChild = Foo(foo: foo, bar: "foobar", baz: baz)
    for child in Mirror(reflecting: fooChild).children {
      switch child.label {
      case "foo":
        checkChildValue(child, expectedString: foo)
      case "bar":
        checkChildValue(child, expectedString: "foobar")
      case "baz":
        checkChildValue(child, expectedString: baz)
      default:
        Issue.record("Unexpected child")
      }
    }
  }
}
