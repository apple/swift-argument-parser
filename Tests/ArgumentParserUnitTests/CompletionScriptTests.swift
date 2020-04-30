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
    let script = try CompletionsGenerator(command: Base.self, shell: "zsh")
          .generateCompletionScript()
    XCTAssertEqual(baseCompletions, script)
  }
}

extension CompletionScriptTests {
  struct Custom: ParsableCommand {
    @Option(name: .shortAndLong, completion: .custom { _ in ["a", "b", "c"] })
    var one: String

    @Argument(completion: .custom { _ in ["d", "e", "f"] })
    var two: String

    @Option(name: .customShort("z"), completion: .custom { _ in ["x", "y", "z"] })
    var three: String
  }
  
  func verifyCustomOutput(
    _ arg: String,
    expectedOutput: String,
    file: StaticString = #file, line: UInt = #line
  ) throws {
    do {
      _ = try Custom.parse(["---completion", "--", arg])
      XCTFail("Didn't error as expected", file: file, line: line)
    } catch let error as CommandError {
      guard case .completionScriptCustomResponse(let output) = error.parserError else {
        XCTFail("Unexpected error: \(error)", file: file, line: line)
        return
      }
      XCTAssertEqual(expectedOutput, output, file: file, line: line)
    }
  }
  
  func testCustomCompletions() throws {
    try verifyCustomOutput("-o", expectedOutput: "a\nb\nc")
    try verifyCustomOutput("--one", expectedOutput: "a\nb\nc")
    try verifyCustomOutput("two", expectedOutput: "d\ne\nf")
    try verifyCustomOutput("-z", expectedOutput: "x\ny\nz")
  }
}

let baseCompletions = """
#compdef base
local context state state_descr line
_base_commandname="base"
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


_custom_completion() {
    local completions=($($*))
    _describe '' completions
}

_base
"""
