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

final class CompletionScriptTests: XCTestCase {
}

extension CompletionScriptTests {
  enum Kind: String, ExpressibleByArgument {
    case one, two, three
  }
  
  struct Base: ParsableCommand {
    @Option() var name: String
    @Option(completion: .list(["one", "two", "three"])) var kind: Kind
  }

  func testBase() throws {
    let script = generateCompletionScript(Base.self)
    XCTAssertFalse(script.isEmpty)
  }
}
