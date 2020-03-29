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
@testable import ArgumentParser

final class ParsableArgumentsValidationTests: XCTestCase {
  private struct A: ParsableCommand {
    @Option(help: "The number of times to repeat 'phrase'.")
    var count: Int?
    
    @Argument(help: "The phrase to repeat.")
    var phrase: String
    
    enum CodingKeys: String, CodingKey {
      case count
      case phrase
    }
    
    func run() throws {}
  }
  
  private struct B: ParsableCommand {
    @Option(help: "The number of times to repeat 'phrase'.")
    var count: Int?
    
    @Argument(help: "The phrase to repeat.")
    var phrase: String
    
    func run() throws {}
  }
  
  private struct C: ParsableCommand {
    @Option(help: "The number of times to repeat 'phrase'.")
    var count: Int?
    
    @Argument(help: "The phrase to repeat.")
    var phrase: String
    
    enum CodingKeys: String, CodingKey {
      case phrase
    }
    
    func run() throws {}
  }
  
  private struct D: ParsableArguments {
    @Argument(help: "The phrase to repeat.")
    var phrase: String
    
    @Option(help: "The number of times to repeat 'phrase'.")
    var count: Int?
    
    enum CodingKeys: String, CodingKey {
      case count
    }
  }
  
  private struct E: ParsableArguments {
    @Argument(help: "The phrase to repeat.")
    var phrase: String
    
    @Option(help: "The number of times to repeat 'phrase'.")
    var count: Int?
    
    @Flag(help: "Include a counter with each repetition.")
    var includeCounter: Bool
    
    enum CodingKeys: String, CodingKey {
      case count
    }
  }
  
  func testCodingKeyValidation() throws {
    try ParsableArgumentsCodingKeyValidator.validate(A.self)
    
    try ParsableArgumentsCodingKeyValidator.validate(B.self)
    
    XCTAssertThrowsError(try ParsableArgumentsCodingKeyValidator.validate(C.self)) { (error) in
      if let error = error as? ParsableArgumentsCodingKeyValidator.Error {
        XCTAssert(error.missingCodingKeys == ["count"])
      } else {
        XCTFail()
      }
    }
    
    XCTAssertThrowsError(try ParsableArgumentsCodingKeyValidator.validate(D.self)) { (error) in
      if let error = error as? ParsableArgumentsCodingKeyValidator.Error {
        XCTAssert(error.missingCodingKeys == ["phrase"])
      } else {
        XCTFail()
      }
    }
    
    XCTAssertThrowsError(try ParsableArgumentsCodingKeyValidator.validate(E.self)) { (error) in
      if let error = error as? ParsableArgumentsCodingKeyValidator.Error {
        XCTAssert(error.missingCodingKeys == ["phrase", "includeCounter"])
      } else {
        XCTFail()
      }
    }
  }
  
  private struct F: ParsableArguments {
    @Argument()
    var phrase: String
    
    @Argument()
    var items: [Int]
  }
  
  private struct G: ParsableArguments {
    @Argument()
    var items: [Int]
    
    @Argument()
    var phrase: String
  }
  
  private struct H: ParsableArguments {
    @Argument()
    var items: [Int]
    
    @Option()
    var option: Bool
  }
  
  private struct I: ParsableArguments {
    @Argument()
    var name: String
    
    @OptionGroup()
    var options: F
  }
  
  private struct J: ParsableArguments {
    struct Options: ParsableArguments {
      @Argument()
      var numberOfItems: [Int]
    }
    
    @OptionGroup()
    var options: Options
    
    @Argument()
    var phrase: String
  }
  
  private struct K: ParsableArguments {
    struct Options: ParsableArguments {
      @Argument()
      var items: [Int]
    }
    
    @Argument()
    var phrase: String
    
    @OptionGroup()
    var options: Options
  }
  
  func testPositionalArgumentsValidation() throws {
    try PositionalArgumentsValidator.validate(A.self)
    try PositionalArgumentsValidator.validate(F.self)
    XCTAssertThrowsError(try PositionalArgumentsValidator.validate(G.self)) { error in
      if let error = error as? PositionalArgumentsValidator.Error {
        XCTAssert(error.positionalArgumentFollowingRepeated == "phrase")
        XCTAssert(error.repeatedPositionalArgument == "items")
      } else {
        XCTFail()
      }
      XCTAssert(error is PositionalArgumentsValidator.Error)
    }
    try PositionalArgumentsValidator.validate(H.self)
    try PositionalArgumentsValidator.validate(I.self)
    XCTAssertThrowsError(try PositionalArgumentsValidator.validate(J.self)) { error in
      if let error = error as? PositionalArgumentsValidator.Error {
        XCTAssert(error.positionalArgumentFollowingRepeated == "phrase")
        XCTAssert(error.repeatedPositionalArgument == "numberOfItems")
      } else {
        XCTFail()
      }
      XCTAssert(error is PositionalArgumentsValidator.Error)
    }
    try PositionalArgumentsValidator.validate(K.self)
  }
}
