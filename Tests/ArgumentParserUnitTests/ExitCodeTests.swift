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
@testable import ArgumentParser

final class ExitCodeTests: XCTestCase {
}

// MARK: -

extension ExitCodeTests {
  struct A: ParsableArguments {}
  struct E: Error {}

  func testExitCodes() {
    XCTAssertEqual(ExitCode.failure, A.exitCode(for: E()))
    XCTAssertEqual(ExitCode.validationFailure, A.exitCode(for: ValidationError("")))
    
    do {
      _ = try A.parse(["-h"])
      XCTFail("Didn't throw help request error.")
    } catch {
      XCTAssertEqual(ExitCode.success, A.exitCode(for: error))
    }
  }

  func testExitCode_Success() {
    XCTAssertFalse(A.exitCode(for: E()).isSuccess)
    XCTAssertFalse(A.exitCode(for: ValidationError("")).isSuccess)
    
    do {
      _ = try A.parse(["-h"])
      XCTFail("Didn't throw help request error.")
    } catch {
      XCTAssertTrue(A.exitCode(for: error).isSuccess)
    }
  }
}
