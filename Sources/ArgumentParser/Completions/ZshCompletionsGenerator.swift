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
  /// Generates a Zsh completion script for the given command.
  static func generateCompletionScript(_ type: ParsableCommand.Type) -> String {
    let initialFunctionName = [type].completionFunctionName()

    return """
      #compdef \(type._commandName)

      \(generateCompletionFunction([type]))\
      _custom_completion() {
          local -a completions
          completions=("${(@f)"$("${@}")"}")
          if [[ "${#completions[@]}" -gt 1 ]]; then
              completions=("${completions[@]:0:-1}")
              local -ar non_empty_completions=("${completions[@]:#(|:*)}")
              local -ar empty_completions=("${(M)completions[@]:#(|:*)}")
              _describe '' non_empty_completions -- empty_completions -P $'\\'\\''
          fi
      }

      \(initialFunctionName)
      """
  }

  static func generateCompletionFunction(_ commands: [ParsableCommand.Type])
    -> String
  {
    guard let type = commands.last else { return "" }
    let functionName = commands.completionFunctionName()
    let isRootCommand = commands.count == 1

    var args = generateCompletionArguments(commands)
    var subcommands = type.configuration.subcommands
      .filter { $0.configuration.shouldDisplay }

    let subcommandHandler: String
    if subcommands.isEmpty {
      subcommandHandler = ""
    } else {
      args.append("'(-): :->command'")
      args.append("'(-)*:: :->arg'")

      if isRootCommand {
        subcommands.append(HelpCommand.self)
      }

      let subcommandModes = subcommands.map {
        """
                    '\($0._commandName):\($0.configuration.abstract.zshEscaped())'
        """
      }
      let subcommandArgs = subcommands.map {
        """
                \($0._commandName))
                    \(functionName)_\($0._commandName)
                    ;;
        """
      }

      subcommandHandler = """
            case "${state}" in
            command)
                local -ar subcommands=(
        \(subcommandModes.joined(separator: "\n"))
                )
                _describe "subcommand" subcommands
                ;;
            arg)
                case "${words[1]}" in
        \(subcommandArgs.joined(separator: "\n"))
                esac
                ;;
            esac

        """
    }

    let functionText = """
      \(functionName)() {
      \(isRootCommand
        ? """
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


      """

    return functionText
      + subcommands
      .map { generateCompletionFunction(commands + [$0]) }
      .joined()
  }

  static func generateCompletionArguments(_ commands: [ParsableCommand.Type])
    -> [String]
  {
    commands
      .argumentsForHelp(visibility: .default)
      .compactMap { $0.zshCompletionString(commands) }
  }
}

extension String {
  fileprivate func zshEscapingSingleQuotes() -> String {
    replacingOccurrences(of: "'", with: "'\\''")
  }

  fileprivate func zshEscapingMetacharacters() -> String {
    replacingOccurrences(
      of: #"[\\\[\]]"#, with: #"\\$0"#, options: .regularExpression
    )
  }

  fileprivate func zshEscaped() -> String {
    zshEscapingMetacharacters().zshEscapingSingleQuotes()
  }
}

extension ArgumentDefinition {
  var zshCompletionAbstract: String {
    guard !help.abstract.isEmpty else { return "" }
    return "[\(help.abstract.zshEscaped())]"
  }

  func zshCompletionString(_ commands: [ParsableCommand.Type]) -> String? {
    guard help.visibility.base == .default else { return nil }

    let inputs: String
    switch update {
    case .unary:
      inputs = ":\(valueName):\(zshActionString(commands))"
    case .nullary:
      inputs = ""
    }

    let line: String
    switch names.count {
    case 0:
      line = ""
    case 1:
      let star = isRepeatableOption ? "*" : ""
      line = """
        \(star)\(names[0].synopsisString)\(zshCompletionAbstract)
        """
    default:
      let synopses = names.map { $0.synopsisString }
      let suppression =
        isRepeatableOption ? "*" : "(\(synopses.joined(separator: " ")))"
      line = """
        \(suppression)'\
        {\(synopses.joined(separator: ","))}\
        '\(zshCompletionAbstract)
        """
    }

    return "'\(line)\(inputs)'"
  }

  /// - returns: `true` if `self` is an option and can be tab-completed multiple times in one command line.
  ///   For example, `ssh` allows the `-L` option to be given multiple times, to establish multiple port forwardings.
  private var isRepeatableOption: Bool {
    guard
      case .named(_) = kind,
      help.options.contains(.isRepeating)
    else { return false }

    switch parsingStrategy {
    case .default, .unconditional: return true
    default: return false
    }
  }

  /// Returns the zsh "action" for an argument completion string.
  func zshActionString(_ commands: [ParsableCommand.Type]) -> String {
    switch completion.kind {
    case .default:
      return ""

    case .file(let extensions):
      let pattern =
        extensions.isEmpty
        ? ""
        : " -g '\(extensions.map { "*." + $0 }.joined(separator: " "))'"
      return "_files\(pattern.zshEscaped())"

    case .directory:
      return "_files -/"

    case .list(let list):
      return "(" + list.joined(separator: " ") + ")"

    case .shellCommand(let command):
      return
        "{local -a list;list=(${(f)\"$(\(command.zshEscapingSingleQuotes()))\"});_describe \"\" list}"

    case .custom:
      // Generate a call back into the command to retrieve a completions list
      return
        "{_custom_completion \"${command_name}\" \(customCompletionCall(commands)) \"${command_line[@]}\"}"
    }
  }
}
