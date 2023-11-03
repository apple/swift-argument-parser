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

final class SingleValueParsingStrategyTests: XCTestCase {
}

// MARK: Scanning for Value

fileprivate struct Bar: ParsableArguments {
  @Option(parsing: .scanningForValue) var name: String
  @Option(parsing: .scanningForValue) var format: String
  @Option(parsing: .scanningForValue) var input: String
}

extension SingleValueParsingStrategyTests {
  func testParsing_scanningForValue_1() throws {
    AssertParse(Bar.self, ["--name", "Foo", "--format", "Bar", "--input", "Baz"]) { bar in
      XCTAssertEqual(bar.name, "Foo")
      XCTAssertEqual(bar.format, "Bar")
      XCTAssertEqual(bar.input, "Baz")
    }
  }
  
  func testParsing_scanningForValue_2() throws {
    AssertParse(Bar.self, ["--name", "--format", "Foo", "Bar", "--input", "Baz"]) { bar in
      XCTAssertEqual(bar.name, "Foo")
      XCTAssertEqual(bar.format, "Bar")
      XCTAssertEqual(bar.input, "Baz")
    }
  }
  
  func testParsing_scanningForValue_3() throws {
    AssertParse(Bar.self, ["--name", "--format", "--input", "Foo", "Bar", "Baz"]) { bar in
      XCTAssertEqual(bar.name, "Foo")
      XCTAssertEqual(bar.format, "Bar")
      XCTAssertEqual(bar.input, "Baz")
    }
  }
}

// MARK: Unconditional

fileprivate struct Baz: ParsableArguments {
  @Option(parsing: .unconditional) var name: String
  @Option(parsing: .unconditional) var format: String
  @Option(parsing: .unconditional) var input: String
}

extension SingleValueParsingStrategyTests {
  func testParsing_unconditional_1() throws {
    AssertParse(Baz.self, ["--name", "Foo", "--format", "Bar", "--input", "Baz"]) { bar in
      XCTAssertEqual(bar.name, "Foo")
      XCTAssertEqual(bar.format, "Bar")
      XCTAssertEqual(bar.input, "Baz")
    }
  }
  
  func testParsing_unconditional_2() throws {
    AssertParse(Baz.self, ["--name", "--name", "--format", "--format", "--input", "--input"]) { bar in
      XCTAssertEqual(bar.name, "--name")
      XCTAssertEqual(bar.format, "--format")
      XCTAssertEqual(bar.input, "--input")
    }
  }
  
  func testParsing_unconditional_3() throws {
    AssertParse(Baz.self, ["--name", "-Foo", "--format", "-Bar", "--input", "-Baz"]) { bar in
      XCTAssertEqual(bar.name, "-Foo")
      XCTAssertEqual(bar.format, "-Bar")
      XCTAssertEqual(bar.input, "-Baz")
    }
  }
  
  struct Tuple2: ParsableArguments {
    @Option var count: (Int, Int)
  }
  
  struct SignedTuple5: ParsableArguments {
    @Option(parsing: .unconditional)
    var count: (Int, Int, Int, Int, Int)
  }
  
  struct Tuple9: ParsableArguments {
    @Option var count: (Int, Int, Int, Int, Int, Int, Int, Int, Int)

    func check() -> Bool {
      count.0 == 1
      && count.1 == 2
      && count.2 == 3
      && count.3 == 4
      && count.4 == 5
      && count.5 == 6
      && count.6 == 7
      && count.7 == 8
      && count.8 == 9
    }
  }
  
  struct ScanningTuple12: ParsableArguments {
    @Option(parsing: .scanningForValue)
    var count: (
      Int, Int, Int, Int, Int, Int,
      Int, Int, Int, Int, Int, Int)
    
    @Flag var verbose = false
    
    func check() -> Bool {
      count.0 == 1
      && count.1 == 2
      && count.2 == 3
      && count.3 == 4
      && count.4 == 5
      && count.5 == 6
      && count.6 == 7
      && count.7 == 8
      && count.8 == 9
      && count.9 == 10
      && count.10 == 11
      && count.11 == 12
    }
  }
  
  func testParsing_Tuple2() throws {
    AssertParse(Tuple2.self, ["--count", "1", "2"]) { tuple2 in
      XCTAssertEqual(tuple2.count.0, 1)
      XCTAssertEqual(tuple2.count.1, 2)
    }
    XCTAssertThrowsError(try Tuple2.parse(["--count"]))
    XCTAssertThrowsError(try Tuple2.parse(["--count", "1"]))
    XCTAssertThrowsError(try Tuple2.parse(["--count", "1", "2", "3"]))
    XCTAssertThrowsError(try Tuple2.parse(["--count", "ZZ", "2"]))
    XCTAssertThrowsError(try Tuple2.parse(["--count", "1", "ZZ"]))
  }

  func testParsing_Tuple9() throws {
    for n in 0...11 {
      let args = ["--count"] + (0..<n).map { "\($0 + 1)" }
      if n == 9 {
        AssertParse(Tuple9.self, args) { tuple9 in
          XCTAssert(tuple9.check())
        }
        
        // Correct number, but incorrect value
        for i in 1..<args.count where i > 1 {
          var args = args
          args[i] = "zzz-\(i)"
          do {
            _ = try Tuple9.parse(args)
            XCTFail("Didn't throw on invalid argument value")
          } catch {
            let errorString = Tuple9.message(for: error)
            XCTAssert(errorString.contains("zzz-\(i)"))
          }
        }
      } else {
        // Incorrect number of arguments
        XCTAssertThrowsError(try Tuple9.parse(args))
      }
    }
  }

  func testParsing_SignedTuple5() throws {
    for n in 0...7 {
      let args = ["--count"] + (0..<n).map { "-\($0 + 1)" }
      if n == 5 {
        AssertParse(SignedTuple5.self, args) { tuple5 in
          XCTAssertEqual(tuple5.count.0, -1)
          XCTAssertEqual(tuple5.count.1, -2)
          XCTAssertEqual(tuple5.count.2, -3)
          XCTAssertEqual(tuple5.count.3, -4)
          XCTAssertEqual(tuple5.count.4, -5)
        }
        
        // Correct number, but incorrect value
        for i in 1..<args.count where i > 1 {
          var args = args
          args[i] = "zzz-\(i)"
          do {
            _ = try SignedTuple5.parse(args)
            XCTFail("Didn't throw on invalid argument value")
          } catch {
            let errorString = SignedTuple5.message(for: error)
            XCTAssert(errorString.contains("zzz-\(i)"))
          }
        }
      } else {
        // Incorrect number of arguments
        XCTAssertThrowsError(try SignedTuple5.parse(args))
      }
    }
  }

  func testParsing_ScanningTuple12() throws {
    for n in 0...14 {
      let args = ["--count"] + (0..<n).map { "\($0 + 1)" }
      if n == 12 {
        AssertParse(ScanningTuple12.self, args) { tuple12 in
          XCTAssert(tuple12.check())
          XCTAssertFalse(tuple12.verbose)
        }
        
        // Check with an intervening `--verbose` flag
        for i in 0...args.count {
          var args = args
          args.insert("--verbose", at: i)
          AssertParse(ScanningTuple12.self, args) { tuple12 in
            XCTAssert(tuple12.check())
            XCTAssertTrue(tuple12.verbose)
          }
        }
        
        // Correct number, but incorrect value
        for i in 1..<args.count where i > 1 {
          var args = args
          args[i] = "zzz-\(i)"
          do {
            _ = try ScanningTuple12.parse(args)
            XCTFail("Didn't throw on invalid argument value")
          } catch {
            let errorString = ScanningTuple12.message(for: error)
            XCTAssert(errorString.contains("zzz-\(i)"))
          }
        }
      } else {
        // Incorrect number of arguments
        XCTAssertThrowsError(try ScanningTuple12.parse(args))
      }
    }
  }
}
