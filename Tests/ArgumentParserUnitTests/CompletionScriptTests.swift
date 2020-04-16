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
  enum Kind: String, ExpressibleByArgument, CaseIterable {
    case one, two, three
  }
  
  struct Base: ParsableCommand {
    @Option(help: "The user's name.") var name: String
    @Option() var kind: Kind
    @Option(completion: .list(["1", "2", "3"])) var otherKind: Kind
  }

  func testBase() throws {
    let script = generateCompletionScript(Base.self)
    XCTAssertEqual("""
      #compdef base
      local context state state_descr line
      typeset -A opt_args

      _base() {
          integer ret=1
          local -a args
          args+=(
              '--name[The user'"'"'s name.]:name:'
              '--kind[]:kind:(one two three)'
              '--other-kind[]:other-kind:(1 2 3)'
              '(-h --help)'{-h,--help}'[Print help information.]'
          )
          _arguments -w -s -S $args[@] && ret=0
          return ret
      }


      _base
      """, script)
  }
}
