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
import TestHelpers
import ArgumentParser

final class ValidationEndToEndTests: XCTestCase {
}

fileprivate enum UserValidationError: LocalizedError {
  case userValidationError
  
  var errorDescription: String? {
    switch self {
    case .userValidationError:
      return "UserValidationError"
    }
  }
}

fileprivate struct Foo: ParsableArguments {
  @Option()
  var count: Int?
  
  @Argument()
  var names: [String]
  
  @Flag()
  var version: Bool
  
  @Flag(name: [.customLong("throw")])
  var throwCustomError: Bool
  
  mutating func validate() throws {
    if version {
      throw CleanExit.message("0.0.1")
    }
    
    if names.isEmpty {
      throw ValidationError("Must specify at least one name.")
    }
    
    if let count = count, names.count != count {
      throw ValidationError("Number of names (\(names.count)) doesn't match count (\(count)).")
    }
    
    if throwCustomError {
      throw UserValidationError.userValidationError
    }
  }
}

extension ValidationEndToEndTests {
  func testValidation() throws {
    AssertParse(Foo.self, ["Joe"]) { foo in
      XCTAssertEqual(foo.names, ["Joe"])
      XCTAssertNil(foo.count)
    }
    
    AssertParse(Foo.self, ["Joe", "Moe", "--count", "2"]) { foo in
      XCTAssertEqual(foo.names, ["Joe", "Moe"])
      XCTAssertEqual(foo.count, 2)
    }
  }
  
  func testValidation_Version() throws {
    AssertErrorMessage(Foo.self, ["--version"], "0.0.1")
    AssertFullErrorMessage(Foo.self, ["--version"], "0.0.1")
  }
  
  func testValidation_Fails() throws {
    AssertErrorMessage(Foo.self, [], "Must specify at least one name.")
    AssertFullErrorMessage(Foo.self, [], """
            Error: Must specify at least one name.
            Usage: foo [--count <count>] [<names> ...] [--version] [--throw]
            """)
    
    AssertErrorMessage(Foo.self, ["--count", "3", "Joe"], """
            Number of names (1) doesn't match count (3).
            """)
    AssertFullErrorMessage(Foo.self, ["--count", "3", "Joe"], """
            Error: Number of names (1) doesn't match count (3).
            Usage: foo [--count <count>] [<names> ...] [--version] [--throw]
            """)
  }
  
  func testCustomErrorValidation() {
    // verify that error description is printed if avaiable via LocalizedError
    AssertErrorMessage(Foo.self, ["--throw", "Joe"], UserValidationError.userValidationError.errorDescription!)
  }
}
