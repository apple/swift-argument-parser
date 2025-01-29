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

extension [ParsableCommand.Type] {
  /// Generates a Zsh completion script for the given command.
  var zshCompletionScript: String {
    """
    #compdef \(first?._commandName ?? "")

    \(completionFunctions)\
    __completion() {
        local -ar non_empty_completions=("${@:#(|:*)}")
        local -ar empty_completions=("${(M)@:#(|:*)}")
        _describe '' non_empty_completions -- empty_completions -P $'\\'\\''
    }

    _custom_completion() {
        local -a completions
        completions=("${(@f)"$("${@}")"}")
        if [[ "${#completions[@]}" -gt 1 ]]; then
            __completion "${completions[@]:0:-1}"
        fi
    }

    \(completionFunctionName())
    """
  }

  private var completionFunctions: String {
    guard let type = last else { return "" }
    let functionName = completionFunctionName()
    let isRootCommand = count == 1

    var args = argumentsForHelp(visibility: .default)
      .compactMap { zshCompletionString($0) }
    var subcommands = type.configuration.subcommands
      .filter { $0.configuration.shouldDisplay }

    let subcommandHandler: String
    if subcommands.isEmpty {
      subcommandHandler = ""
    } else {
      args.append("'(-): :->command'")
      args.append("'(-)*:: :->arg'")

      if isRootCommand {
        subcommands.addHelpSubcommandIffMissing()
      }

      subcommandHandler = """
            case "${state}" in
            command)
                local -ar subcommands=(
        \(
          subcommands.map { """
                        '\($0._commandName):\($0.configuration.abstract.zshEscapeForSingleQuotedExplanation())'
            """
          }
          .joined(separator: "\n")
        )
                )
                _describe "subcommand" subcommands
                ;;
            arg)
                case "${words[1]}" in
                \(subcommands.map { $0._commandName }.joined(separator: "|")))
                    "\(functionName)_${words[1]}"
                    ;;
                esac
                ;;
            esac

        """
    }

    return """
      \(functionName)() {
      \(isRootCommand
        ? """
              emulate -RL zsh -G
              setopt extendedglob
              unsetopt aliases banghist

              local -xr \(CompletionShell.shellEnvironmentVariableName)=zsh
              local -x \(CompletionShell.shellVersionEnvironmentVariableName)
              \(CompletionShell.shellVersionEnvironmentVariableName)="$(builtin emulate zsh -c 'printf %s "${ZSH_VERSION}"')"
              local -r \(CompletionShell.shellVersionEnvironmentVariableName)

              local context state state_descr line
              local -A opt_args

              local -r command_name="${words[1]}"
              local -ar command_line=("${words[@]}")


          """
        : ""
      )\
          local -i ret=1
          local -ar args=(
      \(args.joined(separator: "\n").indentingEachLine(by: 8))
          )
          _arguments -w -s -S "${args[@]}" && ret=0
      \(subcommandHandler)
          return "${ret}"
      }

      \(subcommands.map { (self + [$0]).completionFunctions }.joined())
      """
  }

  private func zshCompletionString(_ arg: ArgumentDefinition) -> String? {
    guard arg.help.visibility.base == .default else { return nil }

    let inputs: String
    switch arg.update {
    case .unary:
      inputs = ":\(arg.valueName):\(zshActionString(arg))"
    case .nullary:
      inputs = ""
    }

    let line: String
    switch arg.names.count {
    case 0:
      line = ""
    case 1:
      line = """
        \(arg.isRepeatableOption ? "*" : "")\(arg.names[0].synopsisString)\(arg.zshCompletionAbstract)
        """
    default:
      let synopses = arg.names.map { $0.synopsisString }
      line = """
        \(arg.isRepeatableOption ? "*" : "(\(synopses.joined(separator: " ")))")'\
        {\(synopses.joined(separator: ","))}\
        '\(arg.zshCompletionAbstract)
        """
    }

    return "'\(line)\(inputs)'"
  }

  /// Returns the zsh "action" for an argument completion string.
  private func zshActionString(_ arg: ArgumentDefinition) -> String {
    switch arg.completion.kind {
    case .default:
      return ""

    case .file(let extensions):
      return
        extensions.isEmpty
        ? "_files"
        : "_files -g '\\''\(extensions.map { "*.\($0.zshEscapeForSingleQuotedExplanation())" }.joined(separator: " "))'\\''"

    case .directory:
      return "_files -/"

    case .list(let list):
      return "(\(list.joined(separator: " ")))"

    case .shellCommand(let command):
      return
        "{local -a list;list=(${(f)\"$(\(command.shellEscapeForSingleQuotedString()))\"});_describe \"\" list}"

    case .custom:
      // Generate a call back into the command to retrieve a completions list
      return
        "{_custom_completion \"${command_name}\" \(arg.customCompletionCall(self)) \"${command_line[@]}\"}"
    }
  }
}

extension String {
  fileprivate func zshEscapeForSingleQuotedExplanation() -> String {
    replacingOccurrences(
      of: #"[\\\[\]]"#,
      with: #"\\$0"#,
      options: .regularExpression
    )
    .shellEscapeForSingleQuotedString()
  }
}

extension ArgumentDefinition {
  /// - returns: `true` if `self` is an option and can be tab-completed multiple times in one command line.
  ///   For example, `ssh` allows the `-L` option to be given multiple times, to establish multiple port forwardings.
  fileprivate var isRepeatableOption: Bool {
    guard
      case .named(_) = kind,
      help.options.contains(.isRepeating)
    else { return false }

    switch parsingStrategy {
    case .default, .unconditional: return true
    default: return false
    }
  }

  fileprivate var zshCompletionAbstract: String {
    guard !help.abstract.isEmpty else { return "" }
    return "[\(help.abstract.zshEscapeForSingleQuotedExplanation())]"
  }
}
