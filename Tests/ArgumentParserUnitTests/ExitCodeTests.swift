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

import Foundation
import Testing

@testable import ArgumentParser

@Suite struct ExitCodeTests {}

// MARK: -

// swift-format-ignore: AlwaysUseLowerCamelCase
// https://github.com/apple/swift-argument-parser/issues/710
extension ExitCodeTests {
  struct A: ParsableArguments {}
  struct E: Error {}
  struct C: ParsableCommand {
    static let configuration = CommandConfiguration(version: "v1")
  }

  @Test func exitCodes() {
    #expect(A.exitCode(for: E()) == ExitCode.failure)
    #expect(A.exitCode(for: ValidationError("")) == ExitCode.validationFailure)

    do {
      _ = try A.parse(["-h"])
      Issue.record("Didn't throw help request error.")
    } catch {
      #expect(A.exitCode(for: error) == ExitCode.success)
    }

    do {
      _ = try A.parse(["--version"])
      Issue.record("Didn't throw unrecognized --version error.")
    } catch {
      #expect(A.exitCode(for: error) == ExitCode.validationFailure)
    }

    do {
      _ = try C.parse(["--version"])
      Issue.record("Didn't throw version request error.")
    } catch {
      #expect(C.exitCode(for: error) == ExitCode.success)
    }
  }

  @Test func exitCode_Success() {
    #expect(A.exitCode(for: E()).isSuccess == false)
    #expect(A.exitCode(for: ValidationError("")).isSuccess == false)

    do {
      _ = try A.parse(["-h"])
      Issue.record("Didn't throw help request error.")
    } catch {
      #expect(A.exitCode(for: error).isSuccess)
    }

    do {
      _ = try A.parse(["--version"])
      Issue.record("Didn't throw unrecognized --version error.")
    } catch {
      #expect(A.exitCode(for: error).isSuccess == false)
    }

    do {
      _ = try C.parse(["--version"])
      Issue.record("Didn't throw version request error.")
    } catch {
      #expect(C.exitCode(for: error).isSuccess)
    }
  }
}

// MARK: - NSError tests

extension ExitCodeTests {
  @Test func nsErrorIsHandled() {
    struct NSErrorCommand: ParsableCommand {
      static let message =
        "The file “foo/bar” couldn’t be opened because there is no such file"

      static let fileNotFoundNSError = NSError(
        domain: "TestError",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: Self.message])
    }
    #expect(
      NSErrorCommand.exitCode(for: NSErrorCommand.fileNotFoundNSError)
        == ExitCode(rawValue: 1))

    #if canImport(FoundationEssentials)
    let prefix = "Error Domain=TestError Code=1 \"(null)\""
    #if compiler(<6.1)
    #expect(
      NSErrorCommand.message(for: NSErrorCommand.fileNotFoundNSError)
        == "\(prefix)")
    #else
    #expect(
      NSErrorCommand.message(for: NSErrorCommand.fileNotFoundNSError)
        == "\(prefix)UserInfo={NSLocalizedDescription=\(NSErrorCommand.message)}"
    )
    #endif
    #else
    #expect(
      NSErrorCommand.message(for: NSErrorCommand.fileNotFoundNSError)
        == NSErrorCommand.message)
    #endif
  }
}
