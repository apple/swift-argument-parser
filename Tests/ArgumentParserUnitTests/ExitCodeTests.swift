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
  struct C: ParsableCommand {
    static var configuration = CommandConfiguration(version: "v1")
  }
  
  func testExitCodes() {
    XCTAssertEqual(ExitCode.failure, A.exitCode(for: E()))
    XCTAssertEqual(ExitCode.validationFailure, A.exitCode(for: ValidationError("")))
    
    do {
      _ = try A.parse(["-h"])
      XCTFail("Didn't throw help request error.")
    } catch {
      XCTAssertEqual(ExitCode.success, A.exitCode(for: error))
    }
    
    do {
      _ = try A.parse(["--version"])
      XCTFail("Didn't throw unrecognized --version error.")
    } catch {
      XCTAssertEqual(ExitCode.validationFailure, A.exitCode(for: error))
    }

    do {
      _ = try C.parse(["--version"])
      XCTFail("Didn't throw version request error.")
    } catch {
      XCTAssertEqual(ExitCode.success, C.exitCode(for: error))
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
    
    do {
      _ = try A.parse(["--version"])
      XCTFail("Didn't throw unrecognized --version error.")
    } catch {
      XCTAssertFalse(A.exitCode(for: error).isSuccess)
    }
    
    do {
      _ = try C.parse(["--version"])
      XCTFail("Didn't throw version request error.")
    } catch {
      XCTAssertTrue(C.exitCode(for: error).isSuccess)
    }
  }
}

// MARK: - CustomNSError tests

extension ExitCodeTests {
  enum MyCustomNSError: CustomNSError {
    case myFirstCase
    case mySecondCase

    var errorCode: Int {
      switch self {
      case .myFirstCase:
        return 101
      case .mySecondCase:
        return 102
      }
    }

    var errorUserInfo: [String : Any] {
      switch self {
      case .myFirstCase:
        return [NSLocalizedDescriptionKey: "My first case localized description"]
      case .mySecondCase:
        return [:]
      }
    }
  }

  struct CheckFirstCustomNSErrorCommand: ParsableCommand {

    @Option
    var errorCase: Int

    func run() throws {
      switch errorCase {
      case 101:
        throw MyCustomNSError.myFirstCase
      default:
        throw MyCustomNSError.mySecondCase
      }
    }
  }
  
  func testCustomErrorCodeForTheFirstCase() {
    XCTAssertEqual(CheckFirstCustomNSErrorCommand.exitCode(for: MyCustomNSError.myFirstCase), ExitCode(rawValue: 101))
  }

  func testCustomErrorCodeForTheSecondCase() {
    XCTAssertEqual(CheckFirstCustomNSErrorCommand.exitCode(for: MyCustomNSError.mySecondCase), ExitCode(rawValue: 102))
  }
}
