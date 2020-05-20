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

struct BashCompletionsGenerator {
  static func generateCompletionScript(_ type: ParsableCommand.Type) -> String {
    """
    #!/bin/bash

    \(generateCompletionFunction([type]))

    complete -F _math math
    """
  }

  static func generateCompletionFunction(_ commands: [ParsableCommand.Type]) -> String {
    let type = commands.last!
    let functionName = commands.map { "_\($0._commandName)" }.joined()
    let isRootCommand = commands.count == 1
    let dollarOne = isRootCommand ? "1" : "$1"
    let subcommandArgument = isRootCommand ? "2" : "$(($1+1))"
    
    var completionWords = generateArgumentWords(commands)
    var additionalCompletions = generateArgumentCompletions(commands)
    var optionHandlers = generateOptionHandlers(commands)

    var subcommands = type.configuration.subcommands
    var subcommandHandler = ""
    if !subcommands.isEmpty {      
      if isRootCommand {
        subcommands.append(HelpCommand.self)
      }

      completionWords.append(contentsOf: subcommands.map { $0._commandName })
      let subcommandModes = subcommands.map {
        """
        '\($0._commandName):\($0.configuration.abstract)'
        """
        .indentingEachLine(by: 12)
      }
      
      subcommandHandler += "    case ${COMP_WORDS[\(dollarOne)]} in\n"
      for subcommand in subcommands {
        subcommandHandler += """
          (\(subcommand._commandName))
              \(functionName)_\(subcommand._commandName) \(subcommandArgument)
              return
              ;;
          
          """
          .indentingEachLine(by: 8)
      }
      subcommandHandler += "    esac\n"
    }

    completionWords.append(contentsOf: ["-h", "--help"])
    let compgenWords = completionWords.joined(separator: " ")

    var result = "\(functionName)() {\n"
    if isRootCommand {
      result += """
        shopt -s extglob
        declare -a cur prev
        cur="${COMP_WORDS[COMP_CWORD]}"
        prev="${COMP_WORDS[COMP_CWORD-1]}"
        COMPREPLY=()

        """.indentingEachLine(by: 4)
    }

    result += #"    opts="\#(compgenWords)"\#n"#
    for line in additionalCompletions {
      result += #"    opts="$opts \#(line)"\#n"#
    }

    result += """
        if [[ $COMP_CWORD == \(dollarOne) ]]; then
            COMPREPLY=( $(compgen -W "$opts" -- $cur) )
            return
        fi

    """

    if !optionHandlers.isEmpty {
      result += """
      case $prev in
      \(optionHandlers.indentingEachLine(by: 4))
      esac
      """.indentingEachLine(by: 4) + "\n"
    }

    result += subcommandHandler

    result += """
        COMPREPLY=( $(compgen -W "$opts" -- $cur) )
    
    """

    result += "}\n\n"

    return result +
      subcommands
        .map { generateCompletionFunction(commands + [$0]) }
        .joined()
  }

  static func generateArgumentWords(_ commands: [ParsableCommand.Type]) -> [String] {
    ArgumentSet(commands.last!)
      .flatMap { $0.bashCompletionWords() }
  }

  static func generateArgumentCompletions(_ commands: [ParsableCommand.Type]) -> [String] {
    ArgumentSet(commands.last!)
      .compactMap { arg -> String? in
        guard arg.isPositional else { return nil }

        switch arg.completion {
        case .default, .file, .directory:
          return nil
        case .list(let list):
          return list.joined(separator: " ")
        case .custom:
          // Generate a call back into the command to retrieve a completions list
          let commandName = commands.first!._commandName
          let subcommandNames = commands.dropFirst().map { $0._commandName }.joined(separator: " ")
          // TODO: Make this work for @Arguments
          let argumentName = arg.preferredNameForSynopsis?.synopsisString
                ?? arg.help.keys.first?.rawValue ?? "---"
          
          return "$(\(commandName) ---completion \(subcommandNames) -- \(argumentName) $COMP_WORDS)"
        }
      }
  }

  static func generateOptionHandlers(_ commands: [ParsableCommand.Type]) -> String {
    ArgumentSet(commands.last!)
      .compactMap { arg -> String? in
        let words = arg.bashCompletionWords()
        if words.isEmpty { return nil }

        if arg.isNullary {
            return """
            \(arg.bashCompletionWords().joined(separator: "|")))
            ;;
            """
        } else {
            return """
            \(arg.bashCompletionWords().joined(separator: "|")))
            \(arg.bashValueCompletion(commands).indentingEachLine(by: 4))
                return
            ;;
            """
        }
      }
      .joined(separator: "\n")
  }
}

extension ArgumentDefinition {
  func bashCompletionWords() -> [String] {
    names.map { $0.synopsisString }
  }

  /// Returns the bash completion following an option's `--name`
  func bashValueCompletion(_ commands: [ParsableCommand.Type]) -> String {
    switch completion {
    case .default:
      return ""
      
    case .file(let pattern):
      let pattern = pattern.map { " '\($0)'" } ?? ""
      return "COMPREPLY=()\n_filedir\(pattern)"

    case .directory:
      return "COMPREPLY=()\n_filedir -d"
      
    case .list(let list):
      return #"COMPREPLY=( $(compgen -W "\#(list.joined(separator: " "))" -- $cur) )"#
      
    case .custom:
      // Generate a call back into the command to retrieve a completions list
      let commandName = commands.first!._commandName
      let subcommandNames = commands.dropFirst().map { $0._commandName }.joined(separator: " ")
      // TODO: Make this work for @Arguments
      let argumentName = preferredNameForSynopsis?.synopsisString
            ?? self.help.keys.first?.rawValue ?? "---"
      
      return #"COMPREPLY=( $(compgen -W "$(\#(commandName) ---completion \#(subcommandNames) -- \#(argumentName) $COMP_WORDS)" -- $cur) )"#
    }
  }
}
