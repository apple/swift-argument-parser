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

final class URLArgumentTests: XCTestCase {}

extension URLArgumentTests {
  func testURLArguments() {
    XCTAssertEqual(URL(argument: "/System")?.path, URL(fileURLWithPath: "/System").path)
    XCTAssertEqual(URL(argument: ".")?.path, URL(fileURLWithPath: FileManager.default.currentDirectoryPath).path)
    XCTAssertEqual(URL(argument: "..")?.path, URL(fileURLWithPath: FileManager.default.currentDirectoryPath).deletingLastPathComponent().path)
    XCTAssertEqual(URL(argument: "subfolder/data.file")?.path, URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("subfolder/data.file").path)
    XCTAssertEqual(URL(argument: "data.file")?.path, URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("data.file").path)
    XCTAssertEqual(URL(argument: "https://github.com"), URL(string: "https://github.com"))
    XCTAssertEqual(URL(argument: "ftp://192.168.1.100"), URL(string: "ftp://192.168.1.100"))
    XCTAssertEqual(URL(argument: "https://localhost:8080"), URL(string: "https://localhost:8080"))
  }
}
