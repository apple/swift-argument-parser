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

final class SequenceExtensionTests: XCTestCase {}

extension SequenceExtensionTests {
  func testUniqued() {
    XCTAssertEqual([], (0..<0).uniqued())
    XCTAssertEqual([0, 1, 2, 3, 4], (0..<5).uniqued())
    XCTAssertEqual([0, 1, 2, 3, 4], [0, 1, 2, 3, 4, 0, 1, 2, 3, 4].uniqued())
    XCTAssertEqual([0, 1, 2, 3, 4], [0, 1, 2, 3, 4, 4, 3, 2, 1, 0].uniqued())
  }
}
