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

  func testBase_Zsh() throws {
    let script1 = try CompletionsGenerator(command: Base.self, shell: .zsh)
          .generateCompletionScript()
    XCTAssertEqual(zshBaseCompletions, script1)
    
    let script2 = try CompletionsGenerator(command: Base.self, shellName: "zsh")
          .generateCompletionScript()
    XCTAssertEqual(zshBaseCompletions, script2)
    
    let script3 = Base.completionScript(for: .zsh)
    XCTAssertEqual(zshBaseCompletions, script3)
  }

  func testBase_Bash() throws {
    let script1 = try CompletionsGenerator(command: Base.self, shell: .bash)
          .generateCompletionScript()
    XCTAssertEqual(bashBaseCompletions, script1)
    
    let script2 = try CompletionsGenerator(command: Base.self, shellName: "bash")
          .generateCompletionScript()
    XCTAssertEqual(bashBaseCompletions, script2)
    
    let script3 = Base.completionScript(for: .bash)
    XCTAssertEqual(bashBaseCompletions, script3)
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
      XCTFail("Didn't error as expected", file: (file), line: line)
    } catch let error as CommandError {
      guard case .completionScriptCustomResponse(let output) = error.parserError else {
        throw error
      }
      XCTAssertEqual(expectedOutput, output, file: (file), line: line)
    }
  }
  
  func testCustomCompletions() throws {
    try verifyCustomOutput("-o", expectedOutput: "a\nb\nc")
    try verifyCustomOutput("--one", expectedOutput: "a\nb\nc")
    try verifyCustomOutput("two", expectedOutput: "d\ne\nf")
    try verifyCustomOutput("-z", expectedOutput: "x\ny\nz")
    
    XCTAssertThrowsError(try verifyCustomOutput("--bad", expectedOutput: ""))
  }
}

private let zshBaseCompletions = """
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

private let bashBaseCompletions = """
#!/bin/bash

_base() {
    declare -a cur prev
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    COMPREPLY=()
    opts="--name --kind --other-kind -h --help"
    if [[ $COMP_CWORD == 1 ]]; then
        COMPREPLY=( $(compgen -W "$opts" -- $cur) )
        return
    fi
    case $prev in
        --name)
            
            return
        ;;
        --kind)
            COMPREPLY=( $(compgen -W "one two three" -- $cur) )
            return
        ;;
        --other-kind)
            COMPREPLY=( $(compgen -W "1 2 3" -- $cur) )
            return
        ;;
    esac
    COMPREPLY=( $(compgen -W "$opts" -- $cur) )
}


complete -F _base base
"""
