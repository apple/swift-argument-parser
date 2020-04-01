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

func generateCompletionScript(_ type: ParsableCommand.Type) -> String {
  """
  #compdef \(type._commandName)
  local context state state_descr line
  typeset -A opt_args

  \(generateCompletionFunction(type, isRootCommand: true))
  _\(type._commandName)
  """
}

func generateCompletionFunction(_ type: ParsableCommand.Type, isRootCommand: Bool = false, prefix: String = "") -> String {
  let functionName = "\(prefix)_\(type._commandName)"
  
  var args = generateCompletionArguments(type)
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
              local modes
              modes=(
      \(subcommandModes.joined(separator: "\n"))
              )
              _describe "mode" modes
              ;;
          (arg)
              case ${words[1]} in
      \(subcommandArgs.joined(separator: "\n"))
              esac
              ;;
      esac
      
      """
      .indentingEachLine(by: 8)
  }
  
  let functionText = """
    \(functionName)() {
        integer ret=1
        local -a args
        args+=(
    \(args.joined(separator: "\n").indentingEachLine(by: 8))
        )
        _arguments -w -s -S $args[@] && ret=0
    \(subcommandHandler)\
        return ret
    }
    
    
    """
  
  return functionText +
    subcommands
      .map { generateCompletionFunction($0, prefix: functionName) }
      .joined()
}

func generateCompletionArguments(_ type: ParsableCommand.Type) -> [String] {
  ArgumentSet(type)
    .compactMap { $0.completionString }
}

extension String {
  fileprivate func zshEscapingSingleQuotes() -> String {
    self.split(separator: "'").joined(separator: #"'"'"'"#)
  }
  
  fileprivate func indentingEachLine(by n: Int) -> String {
    self.split(separator: "\n")
      .map { String(repeating: " ", count: n) + $0 }
      .joined(separator: "\n")
  }
}

extension ArgumentDefinition {
  var completionAbstract: String? {
    help.help?.abstract.zshEscapingSingleQuotes()
  }
  
  var completionString: String? {
    var inputs: String
    switch update {
    case .unary:
      inputs = ":\(valueName):\(completion.zshString)"
    case .nullary:
      inputs = ""
    }

    let line: String
    switch names.count {
    case 0:
      return nil
    case 1:
      line = """
      \(names[0].synopsisString)[\(completionAbstract ?? "")]
      """
    default:
      let synopses = names.map { $0.synopsisString }
      line = """
      (\(synopses.joined(separator: " ")))'\
      {\(synopses.joined(separator: ","))}\
      '[\(completionAbstract ?? "")]
      """
    }
    
    return "'\(line)\(inputs)'"
  }
}

extension CompletionKind {
  var zshString: String {
    switch self {
    case .default:
      return ""
    case .file:
      return "_files"
    case .directory:
      return "_files -/"
    case .list(let list):
      return "(" + list.joined(separator: " ") + ")"
    case .custom(let f):
      return ""
    }
  }
}
