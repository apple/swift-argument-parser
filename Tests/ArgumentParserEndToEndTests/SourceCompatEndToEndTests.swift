//===----------------------------------------------------------*- swift -*-===//
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
import ArgumentParserTestHelpers
import ArgumentParser

/// The goal of this test class is to validate source compatibility. By running
/// this class's tests, all property wrapper initializers should be called.
final class SourceCompatEndToEndTests: XCTestCase {}

// MARK: - Property Wrapper Initializers

fileprivate struct AlmostAllArguments: ParsableArguments {
  @Argument(default: 0, help: "") var a: Int
  @Argument() var a0: Int
  @Argument(help: "") var a1: Int
  @Argument(default: 0) var a2: Int

  @Argument(default: 0, help: "", transform: { _ in 0 }) var b: Int
  @Argument(default: 0) var b1: Int
  @Argument(help: "") var b2: Int
  @Argument(transform: { _ in 0 }) var b3: Int
  @Argument(help: "", transform: { _ in 0 }) var b4: Int
  @Argument(default: 0, transform: { _ in 0 }) var b5: Int
  @Argument(default: 0, help: "") var b6: Int

  @Argument(default: 0, help: "") var c: Int?
  @Argument() var c0: Int?
  @Argument(help: "") var c1: Int?
  @Argument(default: 0) var c2: Int?

  @Argument(default: 0, help: "", transform: { _ in 0 }) var d: Int?
  @Argument(help: "") var d2: Int?
  @Argument(transform: { _ in 0 }) var d3: Int?
  @Argument(help: "", transform: { _ in 0 }) var d4: Int?
  @Argument(default: 0, transform: { _ in 0 }) var d5: Int?

  @Argument(default: [1, 2], parsing: .remaining, help: "") var e: [Int]
  @Argument(parsing: .remaining, help: "") var e1: [Int]
  @Argument(default: [1, 2], parsing: .remaining) var e2: [Int]
  @Argument(default: [1, 2], help: "") var e3: [Int]
  @Argument() var e4: [Int]
  @Argument(help: "") var e5: [Int]
  @Argument(parsing: .remaining) var e6: [Int]
  @Argument(default: [1, 2]) var e7: [Int]
  @Argument(default: [1, 2], parsing: .remaining, help: "", transform: { _ in 0 }) var e8: [Int]
  @Argument(parsing: .remaining, help: "", transform: { _ in 0 }) var e9: [Int]
  @Argument(default: [1, 2], parsing: .remaining, transform: { _ in 0 }) var e10: [Int]
  @Argument(default: [1, 2], help: "", transform: { _ in 0 }) var e11: [Int]
  @Argument(transform: { _ in 0 }) var e12: [Int]
  @Argument(help: "", transform: { _ in 0 }) var e13: [Int]
  @Argument(parsing: .remaining, transform: { _ in 0 }) var e14: [Int]
  @Argument(default: [1, 2], transform: { _ in 0 }) var e15: [Int]
}

fileprivate struct AllOptions: ParsableArguments {
  @Option(name: .long, default: 0, parsing: .next, help: "") var a: Int
  @Option(default: 0, parsing: .next, help: "") var a1: Int
  @Option(name: .long, parsing: .next, help: "") var a2: Int
  @Option(name: .long, default: 0, help: "") var a3: Int
  @Option(parsing: .next, help: "") var a4: Int
  @Option(default: 0, help: "") var a5: Int
  @Option(default: 0, parsing: .next) var a6: Int
  @Option(name: .long, help: "") var a7: Int
  @Option(name: .long, parsing: .next) var a8: Int
  @Option(name: .long, default: 0) var a9: Int
  @Option(name: .long) var a10: Int
  @Option(default: 0) var a11: Int
  @Option(parsing: .next) var a12: Int
  @Option(help: "") var a13: Int

  @Option(name: .long, default: 0, parsing: .next, help: "") var b: Int?
  @Option(default: 0, parsing: .next, help: "") var b1: Int?
  @Option(name: .long, parsing: .next, help: "") var b2: Int?
  @Option(name: .long, default: 0, help: "") var b3: Int?
  @Option(parsing: .next, help: "") var b4: Int?
  @Option(default: 0, help: "") var b5: Int?
  @Option(default: 0, parsing: .next) var b6: Int?
  @Option(name: .long, help: "") var b7: Int?
  @Option(name: .long, parsing: .next) var b8: Int?
  @Option(name: .long, default: 0) var b9: Int?
  @Option(name: .long) var b10: Int?
  @Option(default: 0) var b11: Int?
  @Option(parsing: .next) var b12: Int?
  @Option(help: "") var b13: Int?

  @Option(name: .long, default: 0, parsing: .next, help: "", transform: { _ in 0 }) var c: Int
  @Option(default: 0, parsing: .next, help: "", transform: { _ in 0 }) var c1: Int
  @Option(name: .long, parsing: .next, help: "", transform: { _ in 0 }) var c2: Int
  @Option(name: .long, default: 0, help: "", transform: { _ in 0 }) var c3: Int
  @Option(parsing: .next, help: "", transform: { _ in 0 }) var c4: Int
  @Option(default: 0, help: "", transform: { _ in 0 }) var c5: Int
  @Option(default: 0, parsing: .next, transform: { _ in 0 }) var c6: Int
  @Option(name: .long, help: "", transform: { _ in 0 }) var c7: Int
  @Option(name: .long, parsing: .next, transform: { _ in 0 }) var c8: Int
  @Option(name: .long, default: 0, transform: { _ in 0 }) var c9: Int
  @Option(name: .long, transform: { _ in 0 }) var c10: Int
  @Option(default: 0, transform: { _ in 0 }) var c11: Int
  @Option(parsing: .next, transform: { _ in 0 }) var c12: Int
  @Option(help: "", transform: { _ in 0 }) var c13: Int

  @Option(name: .long, default: 0, parsing: .next, help: "", transform: { _ in 0 }) var d: Int?
  @Option(default: 0, parsing: .next, help: "", transform: { _ in 0 }) var d1: Int?
  @Option(name: .long, parsing: .next, help: "", transform: { _ in 0 }) var d2: Int?
  @Option(name: .long, default: 0, help: "", transform: { _ in 0 }) var d3: Int?
  @Option(parsing: .next, help: "", transform: { _ in 0 }) var d4: Int?
  @Option(default: 0, help: "", transform: { _ in 0 }) var d5: Int?
  @Option(default: 0, parsing: .next, transform: { _ in 0 }) var d6: Int?
  @Option(name: .long, help: "", transform: { _ in 0 }) var d7: Int?
  @Option(name: .long, parsing: .next, transform: { _ in 0 }) var d8: Int?
  @Option(name: .long, default: 0, transform: { _ in 0 }) var d9: Int?
  @Option(name: .long, transform: { _ in 0 }) var d10: Int?
  @Option(default: 0, transform: { _ in 0 }) var d11: Int?
  @Option(parsing: .next, transform: { _ in 0 }) var d12: Int?
  @Option(help: "", transform: { _ in 0 }) var d13: Int?

  @Option(name: .long, default: [1, 2], parsing: .singleValue, help: "") var e: [Int]
  @Option(default: [1, 2], parsing: .singleValue, help: "") var e1: [Int]
  @Option(name: .long, parsing: .singleValue, help: "") var e2: [Int]
  @Option(name: .long, default: [1, 2], help: "") var e3: [Int]
  @Option(parsing: .singleValue, help: "") var e4: [Int]
  @Option(default: [1, 2], help: "") var e5: [Int]
  @Option(default: [1, 2], parsing: .singleValue) var e6: [Int]
  @Option(name: .long, help: "") var e7: [Int]
  @Option(name: .long, parsing: .singleValue) var e8: [Int]
  @Option(name: .long, default: [1, 2]) var e9: [Int]
  @Option(name: .long) var e10: [Int]
  @Option(default: [1, 2]) var e11: [Int]
  @Option(parsing: .singleValue) var e12: [Int]
  @Option(help: "") var e13: [Int]

  @Option(name: .long, default: [1, 2], parsing: .singleValue, help: "", transform: { _ in 0 }) var f: [Int]
  @Option(default: [1, 2], parsing: .singleValue, help: "", transform: { _ in 0 }) var f1: [Int]
  @Option(name: .long, parsing: .singleValue, help: "", transform: { _ in 0 }) var f2: [Int]
  @Option(name: .long, default: [1, 2], help: "", transform: { _ in 0 }) var f3: [Int]
  @Option(parsing: .singleValue, help: "", transform: { _ in 0 }) var f4: [Int]
  @Option(default: [1, 2], help: "", transform: { _ in 0 }) var f5: [Int]
  @Option(default: [1, 2], parsing: .singleValue, transform: { _ in 0 }) var f6: [Int]
  @Option(name: .long, help: "", transform: { _ in 0 }) var f7: [Int]
  @Option(name: .long, parsing: .singleValue, transform: { _ in 0 }) var f8: [Int]
  @Option(name: .long, default: [1, 2], transform: { _ in 0 }) var f9: [Int]
  @Option(name: .long, transform: { _ in 0 }) var f10: [Int]
  @Option(default: [1, 2], transform: { _ in 0 }) var f11: [Int]
  @Option(parsing: .singleValue, transform: { _ in 0 }) var f12: [Int]
  @Option(help: "", transform: { _ in 0 }) var f13: [Int]
}

struct AllFlags: ParsableArguments {
  enum E: String, EnumerableFlag {
    case one, two, three
  }
  
  @Flag(name: .long, help: "") var a: Bool
  @Flag() var a0: Bool
  @Flag(name: .long) var a1: Bool
  @Flag(help: "") var a2: Bool

  @Flag(name: .long, inversion: .prefixedNo, exclusivity: .chooseLast, help: "") var b: Bool
  @Flag(inversion: .prefixedNo, exclusivity: .chooseLast, help: "") var b1: Bool
  @Flag(name: .long, inversion: .prefixedNo, help: "") var b2: Bool
  @Flag(name: .long, inversion: .prefixedNo, exclusivity: .chooseLast) var b3: Bool
  @Flag(inversion: .prefixedNo, help: "") var b4: Bool
  @Flag(inversion: .prefixedNo, exclusivity: .chooseLast) var b5: Bool
  @Flag(name: .long, inversion: .prefixedNo) var b6: Bool
  @Flag(inversion: .prefixedNo) var b7: Bool

  @Flag(name: .long, default: false, inversion: .prefixedNo, exclusivity: .chooseLast, help: "") var c: Bool
  @Flag(default: false, inversion: .prefixedNo, exclusivity: .chooseLast, help: "") var c1: Bool
  @Flag(name: .long, default: false, inversion: .prefixedNo, help: "") var c2: Bool
  @Flag(name: .long, default: false, inversion: .prefixedNo, exclusivity: .chooseLast) var c3: Bool
  @Flag(default: false, inversion: .prefixedNo, help: "") var c4: Bool
  @Flag(default: false, inversion: .prefixedNo, exclusivity: .chooseLast) var c5: Bool
  @Flag(name: .long, default: false, inversion: .prefixedNo) var c6: Bool
  @Flag(default: false, inversion: .prefixedNo) var c7: Bool

  @Flag(name: .long, default: nil, inversion: .prefixedNo, exclusivity: .chooseLast, help: "") var d: Bool
  @Flag(default: nil, inversion: .prefixedNo, exclusivity: .chooseLast, help: "") var d1: Bool
  @Flag(name: .long, default: nil, inversion: .prefixedNo, help: "") var d2: Bool
  @Flag(name: .long, default: nil, inversion: .prefixedNo, exclusivity: .chooseLast) var d3: Bool
  @Flag(default: nil, inversion: .prefixedNo, help: "") var d4: Bool
  @Flag(default: nil, inversion: .prefixedNo, exclusivity: .chooseLast) var d5: Bool
  @Flag(name: .long, default: nil, inversion: .prefixedNo) var d6: Bool
  @Flag(default: nil, inversion: .prefixedNo) var d7: Bool

  @Flag(name: .long, help: "") var e: Int
  @Flag() var e0: Int
  @Flag(name: .long) var e1: Int
  @Flag(help: "") var e2: Int

  @Flag(default: .one, exclusivity: .chooseLast, help: "") var f: E
  @Flag() var f1: E
  @Flag(exclusivity: .chooseLast, help: "") var f2: E
  @Flag(default: .one, help: "") var f3: E
  @Flag(default: .one, exclusivity: .chooseLast) var f4: E
  @Flag(help: "") var f5: E
  @Flag(exclusivity: .chooseLast) var f6: E
  @Flag(default: .one) var f7: E

  @Flag(exclusivity: .chooseLast, help: "") var g: E?
  @Flag() var g1: E?
  @Flag(help: "") var g2: E?
  @Flag(exclusivity: .chooseLast) var g3: E?

  @Flag(help: "") var h: [E]
  @Flag() var h1: [E]
}

extension SourceCompatEndToEndTests {
  func testParsingAll() throws {
    // This is just checking building the argument definitions, not the actual
    // validation or usage of these definitions, which would fail.
    _ = AlmostAllArguments()
    _ = AllOptions()
    _ = AllFlags()
  }
}

