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

struct ZshCompletionsGenerator {
  static func generateCompletionScript(_ type: ParsableCommand.Type) -> String {
    """
    #compdef \(type._commandName)
    local context state state_descr line
    _\(type._commandName)_commandname="\(type._commandName)"
    typeset -A opt_args

    \(generateCompletionFunction([type]))
    _custom_completion() {
        local completions=($($*))
        _describe '' completions
    }

    _\(type._commandName)
    """
  }
  
  static func generateCompletionFunction(_ commands: [ParsableCommand.Type]) -> String {
    let type = commands.last!
    let functionName = commands.map { "_\($0._commandName)" }.joined()
    let isRootCommand = commands.count == 1
    
    var args = generateCompletionArguments(commands)
    args.append("'(-h --help)'{-h,--help}'[Print help information.]'")
    
    var subcommands = type.configuration.subcommands
    var subcommandHandler = ""
    if !subcommands.isEmpty {
      args.append("'(-): :->command'")
      args.append("'(-)*:: :->arg'")
      
      if isRootCommand {
        subcommands.append(HelpCommand.self)
      }

      let subcommandModes = subcommands.map {
        """
        '\($0._commandName):\($0.configuration.abstract)'
        """
        .indentingEachLine(by: 12)
      }
      let subcommandArgs = subcommands.map {
        """
        (\($0._commandName))
            \(functionName)_\($0._commandName)
            ;;
        """
        .indentingEachLine(by: 12)
      }
      
      subcommandHandler = """
        case $state in
            (command)
                local subcommands
                subcommands=(
        \(subcommandModes.joined(separator: "\n"))
                )
                _describe "subcommand" subcommands
                ;;
            (arg)
                case ${words[1]} in
        \(subcommandArgs.joined(separator: "\n"))
                esac
                ;;
        esac
        
        """
        .indentingEachLine(by: 4)
    }
    
    let functionText = """
      \(functionName)() {
          integer ret=1
          local -a args
          args+=(
      \(args.joined(separator: "\n").indentingEachLine(by: 8))
          )
          _arguments -w -s -S $args[@] && ret=0
      \(subcommandHandler)
          return ret
      }
      
      
      """
    
    return functionText +
      subcommands
        .map { generateCompletionFunction(commands + [$0]) }
        .joined()
  }

  static func generateCompletionArguments(_ commands: [ParsableCommand.Type]) -> [String] {
    ArgumentSet(commands.last!)
      .compactMap { $0.zshCompletionString(commands) }
  }
}

extension String {
  fileprivate func zshEscapingSingleQuotes() -> String {
    self.split(separator: "'").joined(separator: #"'"'"'"#)
  }
}

extension ArgumentDefinition {
  var zshCompletionAbstract: String? {
    help.help?.abstract.zshEscapingSingleQuotes()
  }
  
  func zshCompletionString(_ commands: [ParsableCommand.Type]) -> String? {
    var inputs: String
    switch update {
    case .unary:
      inputs = ":\(valueName):\(zshActionString(commands))"
    case .nullary:
      inputs = ""
    }

    let line: String
    switch names.count {
    case 0:
      return nil
    case 1:
      line = """
      \(names[0].synopsisString)[\(zshCompletionAbstract ?? "")]
      """
    default:
      let synopses = names.map { $0.synopsisString }
      line = """
      (\(synopses.joined(separator: " ")))'\
      {\(synopses.joined(separator: ","))}\
      '[\(zshCompletionAbstract ?? "")]
      """
    }
    
    return "'\(line)\(inputs)'"
  }

  /// Returns the zsh "action" for an argument completion string.
  func zshActionString(_ commands: [ParsableCommand.Type]) -> String {
    switch completion {
    case .default:
      return ""
      
    case .file(let pattern?):
      return "_files -g \(pattern)"
    case .file:
      return "_files"
      
    case .directory(let pattern?):
      return "_files -/ -g \(pattern)"
    case .directory:
      return "_files -/"
      
    case .list(let list):
      return "(" + list.joined(separator: " ") + ")"
      
    case .custom:
      // Generate a call back into the command to retrieve a completions list
      let commandName = commands.first!._commandName
      let subcommandNames = commands.dropFirst().map { $0._commandName }.joined(separator: " ")
      // TODO: Make this work for @Arguments
      let argumentName = preferredNameForSynopsis?.synopsisString ?? "-no-name-"
      return "{_custom_completion $_\(commandName)_commandname ---completion \(subcommandNames) -- \(argumentName)}"
    }
  }
}

