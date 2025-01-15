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

private func candidates(prefix: String) -> [String] {
  switch CompletionShell.requesting {
  case CompletionShell.bash:
    return ["\(prefix)1_bash", "\(prefix)2_bash", "\(prefix)3_bash"]
  case CompletionShell.fish:
    return ["\(prefix)1_fish", "\(prefix)2_fish", "\(prefix)3_fish"]
  case CompletionShell.zsh:
    return ["\(prefix)1_zsh", "\(prefix)2_zsh", "\(prefix)3_zsh"]
  default:
    return []
  }
}

final class RequestingCompletionScriptTests: XCTestCase {
}

extension RequestingCompletionScriptTests {
  struct Path: ExpressibleByArgument {
    var path: String
    
    init?(argument: String) {
      self.path = argument
    }
    
    static var defaultCompletionKind: CompletionKind {
      .file()
    }
  }
    
  enum Kind: String, ExpressibleByArgument, EnumerableFlag {
    case one, two, three = "custom-three"
  }

  struct NestedArguments: ParsableArguments {
    @Argument(completion: .custom { _ in candidates(prefix: "a") })
    var nestedArgument: String
  }
  
  struct Base: ParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "base-test",
      subcommands: [SubCommand.self]
    )

    @Option(help: "The user's name.") var name: String
    @Option() var kind: Kind
    @Option(completion: .list(candidates(prefix: "b"))) var otherKind: Kind
    
    @Option() var path1: Path
    @Option() var path2: Path?
    @Option(completion: .list(candidates(prefix: "c"))) var path3: Path
    
    @Flag(help: .hidden) var verbose = false
    @Flag var allowedKinds: [Kind] = []
    @Flag var kindCounter: Int
    
    @Option() var rep1: [String]
    @Option(name: [.short, .long]) var rep2: [String]
    
    @Argument(completion: .custom { _ in candidates(prefix: "d") }) var argument: String
    @OptionGroup var nested: NestedArguments
    
    struct SubCommand: ParsableCommand {
      static let configuration = CommandConfiguration(
        commandName: "sub-command"
      )
    }
  }

  func testBase_Zsh() throws {
    let script1 = try CompletionsGenerator(command: Base.self, shell: .zsh)
          .generateCompletionScript()
    XCTAssertEqual(zshRequestingBaseCompletions, script1)
    
    let script2 = try CompletionsGenerator(command: Base.self, shellName: "zsh")
          .generateCompletionScript()
    XCTAssertEqual(zshRequestingBaseCompletions, script2)
    
    let script3 = Base.completionScript(for: .zsh)
    XCTAssertEqual(zshRequestingBaseCompletions, script3)
  }

  func testBase_Bash() throws {
    let script1 = try CompletionsGenerator(command: Base.self, shell: .bash)
          .generateCompletionScript()
    XCTAssertEqual(bashRequestingBaseCompletions, script1)
    
    let script2 = try CompletionsGenerator(command: Base.self, shellName: "bash")
          .generateCompletionScript()
    XCTAssertEqual(bashRequestingBaseCompletions, script2)
    
    let script3 = Base.completionScript(for: .bash)
    XCTAssertEqual(bashRequestingBaseCompletions, script3)
  }

  func testBase_Fish() throws {
    let script1 = try CompletionsGenerator(command: Base.self, shell: .fish)
          .generateCompletionScript()
    XCTAssertEqual(fishRequestingBaseCompletions, script1)
    
    let script2 = try CompletionsGenerator(command: Base.self, shellName: "fish")
          .generateCompletionScript()
    XCTAssertEqual(fishRequestingBaseCompletions, script2)
    
    let script3 = Base.completionScript(for: .fish)
    XCTAssertEqual(fishRequestingBaseCompletions, script3)
  }
}

extension RequestingCompletionScriptTests {
  struct Custom: ParsableCommand {
    @Option(name: .shortAndLong, completion: .custom { _ in candidates(prefix: "e") })
    var one: String

    @Argument(completion: .custom { _ in candidates(prefix: "f") })
    var two: String

    @Option(name: .customShort("z"), completion: .custom { _ in candidates(prefix: "g") })
    var three: String
    
    @OptionGroup var nested: NestedArguments
    
    struct NestedArguments: ParsableArguments {
      @Argument(completion: .custom { _ in candidates(prefix: "h") })
      var four: String
    }
  }
  
  func verifyCustomOutput(
    _ arg: String,
    forShell shell: String,
    expectedOutputPrefix prefix: String,
    file: StaticString = #filePath,
    line: UInt = #line
  ) throws {
    do {
      setenv("SAP_SHELL", shell, 1)
      defer {
        unsetenv("SAP_SHELL")
      }
      _ = try Custom.parse(["---completion", "--", arg])
      XCTFail("Didn't error as expected", file: (file), line: line)
    } catch let error as CommandError {
      guard case .completionScriptCustomResponse(let output) = error.parserError else {
        throw error
      }
      XCTAssertEqual(
        prefix.isEmpty
        ? ""
        : "\(prefix)1_\(shell)\n\(prefix)2_\(shell)\n\(prefix)3_\(shell)",
        output,
        file: (file),
        line: line
      )
    }
  }
  
  func testCustomCompletions(forShell shell: String) throws {
    try verifyCustomOutput("-o", forShell: shell, expectedOutputPrefix: "e")
    try verifyCustomOutput("--one", forShell: shell, expectedOutputPrefix: "e")
    try verifyCustomOutput("two", forShell: shell, expectedOutputPrefix: "f")
    try verifyCustomOutput("-z", forShell: shell, expectedOutputPrefix: "g")
    try verifyCustomOutput("nested.four", forShell: shell, expectedOutputPrefix: "h")
    
    XCTAssertThrowsError(try verifyCustomOutput("--bad", forShell: shell, expectedOutputPrefix: ""))
    XCTAssertThrowsError(try verifyCustomOutput("four", forShell: shell, expectedOutputPrefix: ""))
  }

  func testBashCustomCompletions() throws {
    try testCustomCompletions(forShell: "bash")
  }

  func testFishCustomCompletions() throws {
    try testCustomCompletions(forShell: "fish")
  }

  func testZshCustomCompletions() throws {
    try testCustomCompletions(forShell: "zsh")
  }
}

extension RequestingCompletionScriptTests {
  struct EscapedCommand: ParsableCommand {
    @Option(help: #"Escaped chars: '[]\."#)
    var one: String
    
    @Argument(completion: .custom { _ in candidates(prefix: "i") })
    var two: String
  }

  func testEscaped_Zsh() throws {
    XCTAssertEqual(zshRequestingEscapedCompletion, EscapedCommand.completionScript(for: .zsh))
  }
}

let zshRequestingBaseCompletions = """
#compdef base-test
local context state state_descr line
_base_test_commandname=$words[1]
typeset -A opt_args

_base-test() {
    export SAP_SHELL=zsh
    SAP_SHELL_VERSION="$(builtin emulate zsh -c 'printf %s "${ZSH_VERSION}"')"
    export SAP_SHELL_VERSION
    integer ret=1
    local -a args
    args+=(
        '--name[The user'"'"'s name.]:name:'
        '--kind:kind:(one two custom-three)'
        '--other-kind:other-kind:(b1_zsh b2_zsh b3_zsh)'
        '--path1:path1:_files'
        '--path2:path2:_files'
        '--path3:path3:(c1_zsh c2_zsh c3_zsh)'
        '--one'
        '--two'
        '--three'
        '*--kind-counter'
        '*--rep1:rep1:'
        '*'{-r,--rep2}':rep2:'
        ':argument:{_custom_completion $_base_test_commandname ---completion  -- argument $words}'
        ':nested-argument:{_custom_completion $_base_test_commandname ---completion  -- nested.nestedArgument $words}'
        '(-h --help)'{-h,--help}'[Show help information.]'
        '(-): :->command'
        '(-)*:: :->arg'
    )
    _arguments -w -s -S $args[@] && ret=0
    case $state in
        (command)
            local subcommands
            subcommands=(
                'sub-command:'
                'help:Show subcommand help information.'
            )
            _describe "subcommand" subcommands
            ;;
        (arg)
            case ${words[1]} in
                (sub-command)
                    _base-test_sub-command
                    ;;
                (help)
                    _base-test_help
                    ;;
            esac
            ;;
    esac

    return ret
}

_base-test_sub-command() {
    integer ret=1
    local -a args
    args+=(
        '(-h --help)'{-h,--help}'[Show help information.]'
    )
    _arguments -w -s -S $args[@] && ret=0

    return ret
}

_base-test_help() {
    integer ret=1
    local -a args
    args+=(
        ':subcommands:'
    )
    _arguments -w -s -S $args[@] && ret=0

    return ret
}


_custom_completion() {
    local completions=("${(@f)$($*)}")
    _describe '' completions
}

_base-test
"""

let bashRequestingBaseCompletions = """
#!/bin/bash

_base_test() {
    export SAP_SHELL=bash
    SAP_SHELL_VERSION="$(IFS='.'; printf %s "${BASH_VERSINFO[*]}")"
    export SAP_SHELL_VERSION
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    COMPREPLY=()
    opts="--name --kind --other-kind --path1 --path2 --path3 --one --two --three --kind-counter --rep1 -r --rep2 -h --help sub-command help"
    opts="$opts $("${COMP_WORDS[0]}" ---completion  -- argument "${COMP_WORDS[@]}")"
    opts="$opts $("${COMP_WORDS[0]}" ---completion  -- nested.nestedArgument "${COMP_WORDS[@]}")"
    if [[ $COMP_CWORD == "1" ]]; then
        COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
        return
    fi
    case $prev in
        --name)

            return
        ;;
        --kind)
            COMPREPLY=( $(compgen -W "one two custom-three" -- "$cur") )
            return
        ;;
        --other-kind)
            COMPREPLY=( $(compgen -W "b1_bash b2_bash b3_bash" -- "$cur") )
            return
        ;;
        --path1)
            if declare -F _filedir >/dev/null; then
              _filedir
            else
              COMPREPLY=( $(compgen -f -- "$cur") )
            fi
            return
        ;;
        --path2)
            if declare -F _filedir >/dev/null; then
              _filedir
            else
              COMPREPLY=( $(compgen -f -- "$cur") )
            fi
            return
        ;;
        --path3)
            COMPREPLY=( $(compgen -W "c1_bash c2_bash c3_bash" -- "$cur") )
            return
        ;;
        --rep1)

            return
        ;;
        -r|--rep2)

            return
        ;;
    esac
    case ${COMP_WORDS[1]} in
        (sub-command)
            _base_test_sub-command 2
            return
            ;;
        (help)
            _base_test_help 2
            return
            ;;
    esac
    COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
}
_base_test_sub_command() {
    opts="-h --help"
    if [[ $COMP_CWORD == "$1" ]]; then
        COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
        return
    fi
    COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
}
_base_test_help() {
    opts=""
    if [[ $COMP_CWORD == "$1" ]]; then
        COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
        return
    fi
    COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
}


complete -F _base_test base-test
"""

let zshRequestingEscapedCompletion = """
#compdef escaped-command
local context state state_descr line
_escaped_command_commandname=$words[1]
typeset -A opt_args

_escaped-command() {
    export SAP_SHELL=zsh
    SAP_SHELL_VERSION="$(builtin emulate zsh -c 'printf %s "${ZSH_VERSION}"')"
    export SAP_SHELL_VERSION
    integer ret=1
    local -a args
    args+=(
        '--one[Escaped chars: '"'"'\\[\\]\\\\.]:one:'
        ':two:{_custom_completion $_escaped_command_commandname ---completion  -- two $words}'
        '(-h --help)'{-h,--help}'[Show help information.]'
    )
    _arguments -w -s -S $args[@] && ret=0

    return ret
}


_custom_completion() {
    local completions=("${(@f)$($*)}")
    _describe '' completions
}

_escaped-command
"""

let fishRequestingBaseCompletions = """
# A function which filters options which starts with "-" from $argv.
function _swift_base-test_preprocessor
    set -l results
    for i in (seq (count $argv))
        switch (echo $argv[$i] | string sub -l 1)
            case '-'
            case '*'
                echo $argv[$i]
        end
    end
end

function _swift_base-test_using_command
    set -gx SAP_SHELL fish
    set -gx SAP_SHELL_VERSION "$FISH_VERSION"
    set -l currentCommands (_swift_base-test_preprocessor (commandline -opc))
    set -l expectedCommands (string split " " $argv[1])
    set -l subcommands (string split " " $argv[2])
    if [ (count $currentCommands) -ge (count $expectedCommands) ]
        for i in (seq (count $expectedCommands))
            if [ $currentCommands[$i] != $expectedCommands[$i] ]
                return 1
            end
        end
        if [ (count $currentCommands) -eq (count $expectedCommands) ]
            return 0
        end
        if [ (count $subcommands) -gt 1 ]
            for i in (seq (count $subcommands))
                if [ $currentCommands[(math (count $expectedCommands) + 1)] = $subcommands[$i] ]
                    return 1
                end
            end
        end
        return 0
    end
    return 1
end

complete -c base-test -n '_swift_base-test_using_command "base-test sub-command"' -s h -l help -d 'Show help information.'
complete -c base-test -n '_swift_base-test_using_command "base-test" "sub-command help"' -l name -d 'The user\\'s name.'
complete -c base-test -n '_swift_base-test_using_command "base-test" "sub-command help"' -l kind -r -f -k -a 'one two custom-three'
complete -c base-test -n '_swift_base-test_using_command "base-test" "sub-command help"' -l other-kind -r -f -k -a 'b1_fish b2_fish b3_fish'
complete -c base-test -n '_swift_base-test_using_command "base-test" "sub-command help"' -l path1 -r -f -a '(for i in *.{}; echo $i;end)'
complete -c base-test -n '_swift_base-test_using_command "base-test" "sub-command help"' -l path2 -r -f -a '(for i in *.{}; echo $i;end)'
complete -c base-test -n '_swift_base-test_using_command "base-test" "sub-command help"' -l path3 -r -f -k -a 'c1_fish c2_fish c3_fish'
complete -c base-test -n '_swift_base-test_using_command "base-test" "sub-command help"' -l one
complete -c base-test -n '_swift_base-test_using_command "base-test" "sub-command help"' -l two
complete -c base-test -n '_swift_base-test_using_command "base-test" "sub-command help"' -l three
complete -c base-test -n '_swift_base-test_using_command "base-test" "sub-command help"' -l kind-counter
complete -c base-test -n '_swift_base-test_using_command "base-test" "sub-command help"' -l rep1
complete -c base-test -n '_swift_base-test_using_command "base-test" "sub-command help"' -s r -l rep2
complete -c base-test -n '_swift_base-test_using_command "base-test" "sub-command help"' -r -f -a '(command base-test ---completion  -- argument (commandline -opc)[1..-1])'
complete -c base-test -n '_swift_base-test_using_command "base-test" "sub-command help"' -r -f -a '(command base-test ---completion  -- nested.nestedArgument (commandline -opc)[1..-1])'
complete -c base-test -n '_swift_base-test_using_command "base-test" "sub-command help"' -s h -l help -d 'Show help information.'
complete -c base-test -n '_swift_base-test_using_command "base-test" "sub-command help"' -f -a 'sub-command' -d ''
complete -c base-test -n '_swift_base-test_using_command "base-test" "sub-command help"' -f -a 'help' -d 'Show subcommand help information.'
"""

// MARK: - Test Hidden Subcommand
struct RequestingParent: ParsableCommand {
    static let configuration = CommandConfiguration(subcommands: [RequestingHiddenChild.self])
}

struct RequestingHiddenChild: ParsableCommand {
    static let configuration = CommandConfiguration(shouldDisplay: false)
}

extension RequestingCompletionScriptTests {
  func testHiddenSubcommand_Zsh() throws {
    let script1 = try CompletionsGenerator(command: Parent.self, shell: .zsh)
          .generateCompletionScript()
    XCTAssertEqual(zshRequestingHiddenCompletion, script1)

    let script2 = try CompletionsGenerator(command: Parent.self, shellName: "zsh")
          .generateCompletionScript()
    XCTAssertEqual(zshRequestingHiddenCompletion, script2)

    let script3 = Parent.completionScript(for: .zsh)
    XCTAssertEqual(zshRequestingHiddenCompletion, script3)
  }

  func testHiddenSubcommand_Bash() throws {
    let script1 = try CompletionsGenerator(command: Parent.self, shell: .bash)
          .generateCompletionScript()
    XCTAssertEqual(bashRequestingHiddenCompletion, script1)

    let script2 = try CompletionsGenerator(command: Parent.self, shellName: "bash")
          .generateCompletionScript()
    XCTAssertEqual(bashRequestingHiddenCompletion, script2)

    let script3 = Parent.completionScript(for: .bash)
    XCTAssertEqual(bashRequestingHiddenCompletion, script3)
  }

  func testHiddenSubcommand_Fish() throws {
    let script1 = try CompletionsGenerator(command: Parent.self, shell: .fish)
          .generateCompletionScript()
    XCTAssertEqual(fishRequestingHiddenCompletion, script1)

    let script2 = try CompletionsGenerator(command: Parent.self, shellName: "fish")
          .generateCompletionScript()
    XCTAssertEqual(fishRequestingHiddenCompletion, script2)

    let script3 = Parent.completionScript(for: .fish)
    XCTAssertEqual(fishRequestingHiddenCompletion, script3)
  }
}

let zshRequestingHiddenCompletion = """
#compdef parent
local context state state_descr line
_parent_commandname=$words[1]
typeset -A opt_args

_parent() {
    export SAP_SHELL=zsh
    SAP_SHELL_VERSION="$(builtin emulate zsh -c 'printf %s "${ZSH_VERSION}"')"
    export SAP_SHELL_VERSION
    integer ret=1
    local -a args
    args+=(
        '(-h --help)'{-h,--help}'[Show help information.]'
    )
    _arguments -w -s -S $args[@] && ret=0

    return ret
}


_custom_completion() {
    local completions=("${(@f)$($*)}")
    _describe '' completions
}

_parent
"""

let bashRequestingHiddenCompletion = """
#!/bin/bash

_parent() {
    export SAP_SHELL=bash
    SAP_SHELL_VERSION="$(IFS='.'; printf %s "${BASH_VERSINFO[*]}")"
    export SAP_SHELL_VERSION
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    COMPREPLY=()
    opts="-h --help"
    if [[ $COMP_CWORD == "1" ]]; then
        COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
        return
    fi
    COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
}


complete -F _parent parent
"""

let fishRequestingHiddenCompletion = """
# A function which filters options which starts with "-" from $argv.
function _swift_parent_preprocessor
    set -l results
    for i in (seq (count $argv))
        switch (echo $argv[$i] | string sub -l 1)
            case '-'
            case '*'
                echo $argv[$i]
        end
    end
end

function _swift_parent_using_command
    set -gx SAP_SHELL fish
    set -gx SAP_SHELL_VERSION "$FISH_VERSION"
    set -l currentCommands (_swift_parent_preprocessor (commandline -opc))
    set -l expectedCommands (string split " " $argv[1])
    set -l subcommands (string split " " $argv[2])
    if [ (count $currentCommands) -ge (count $expectedCommands) ]
        for i in (seq (count $expectedCommands))
            if [ $currentCommands[$i] != $expectedCommands[$i] ]
                return 1
            end
        end
        if [ (count $currentCommands) -eq (count $expectedCommands) ]
            return 0
        end
        if [ (count $subcommands) -gt 1 ]
            for i in (seq (count $subcommands))
                if [ $currentCommands[(math (count $expectedCommands) + 1)] = $subcommands[$i] ]
                    return 1
                end
            end
        end
        return 0
    end
    return 1
end

complete -c parent -n '_swift_parent_using_command \"parent\"' -s h -l help -d 'Show help information.'
"""
