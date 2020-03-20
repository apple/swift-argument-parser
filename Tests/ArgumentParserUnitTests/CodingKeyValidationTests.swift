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

final class CodingKeyValidationTests: XCTestCase {
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
  
  func testCodingKeyValidation() throws {
    var error: ParsableArgumentsCodingKeyValidator.ValidationError?
    
    ParsableArgumentsCodingKeyValidator.validate(A.self, error: &error)
    XCTAssertNil(error)
    
    ParsableArgumentsCodingKeyValidator.validate(B.self, error: &error)
    XCTAssertNil(error)
    
    ParsableArgumentsCodingKeyValidator.validate(C.self, error: &error)
    XCTAssert(error?.missingKey == "count")
    XCTAssert(error?.parsableArgumentsType.init() is C)
    
    ParsableArgumentsCodingKeyValidator.validate(D.self, error: &error)
    XCTAssert(error?.missingKey == "phrase")
    XCTAssert(error?.parsableArgumentsType.init() is D)
  }
  
}
