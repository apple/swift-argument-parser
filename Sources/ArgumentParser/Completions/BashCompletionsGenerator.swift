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
  /// Generates a Bash completion script for the given command.
  var bashCompletionScript: String {
    // TODO: Add a check to see if the command is installed where we expect?
    // swift-format-ignore: NeverForceUnwrap
    // Preconditions:
    // - first must be non-empty for a bash completion script to be of use.
    // - first is guaranteed non-empty in the one place where this computed var is used.
    let commandName = first!._commandName
    return """
      #!/bin/bash

      \(completionFunctions)

      complete -F \(completionFunctionName().shellEscapeForVariableName()) \(commandName)
      """
  }

  /// Generates a Bash completion function for the last command in the given list.
  private var completionFunctions: String {
    guard let type = last else {
      fatalError()
    }
    let functionName =
      completionFunctionName().shellEscapeForVariableName()

    // The root command gets a different treatment for the parsing index.
    let isRootCommand = count == 1
    let dollarOne = isRootCommand ? "1" : "${1}"
    let subcommandArgument = isRootCommand ? "2" : "$((${1}+1))"

    // Include 'help' in the list of subcommands for the root command.
    var subcommands = type.configuration.subcommands
      .filter { $0.configuration.shouldDisplay }
    if !subcommands.isEmpty && isRootCommand {
      subcommands.append(HelpCommand.self)
    }

    // Generate the words that are available at the "top level" of this
    // command — these are the dash-prefixed names of options and flags as well
    // as all the subcommand names.
    let completionWords =
      argumentsForHelp(visibility: .default).flatMap { $0.bashCompletionWords }
      + subcommands.map { $0._commandName }

    // Generate additional top-level completions — these are completion lists
    // or custom function-based word lists from positional arguments.
    let additionalCompletions =
      ArgumentSet(type, visibility: .default, parent: nil)
      .compactMap { arg -> String? in
        guard arg.isPositional else { return nil }

        switch arg.completion.kind {
        case .default, .file, .directory:
          return nil
        case .list(let list):
          return list.joined(separator: " ")
        case .shellCommand(let command):
          return "$(\(command))"
        case .custom:
          return """
            $("${COMP_WORDS[0]}" \(arg.customCompletionCall(self)) "${COMP_WORDS[@]}")
            """
        }
      }

    // Start building the resulting function code.
    var result = "\(functionName)() {\n"

    // The function that represents the root command has some additional setup
    // that other command functions don't need.
    if isRootCommand {
      result += """
            local -xr \(CompletionShell.shellEnvironmentVariableName)=bash
            local -x \(CompletionShell.shellVersionEnvironmentVariableName)
            \(CompletionShell.shellVersionEnvironmentVariableName)="$(IFS='.';printf %s "${BASH_VERSINFO[*]}")"
            local -r \(CompletionShell.shellVersionEnvironmentVariableName)

            local -r cur="${2}"
            local -r prev="${3}"


        """
    }

    // Start by declaring a local var for the top-level completions.
    // Return immediately if the completion matching hasn't moved further.
    result += "    opts=\"\(completionWords.joined(separator: " "))\"\n"
    for line in additionalCompletions {
      result += "    opts=\"${opts} \(line)\"\n"
    }

    result += """
          if [[ "${COMP_CWORD}" == "\(dollarOne)" ]]; then
              COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
              return
          fi

      """

    // Generate the case pattern-matching statements for option values.
    // If there aren't any, skip the case block altogether.
    let optionHandlers =
      ArgumentSet(type, visibility: .default, parent: nil)
      .compactMap { arg -> String? in
        let words = arg.bashCompletionWords
        if words.isEmpty { return nil }

        // Flags don't take a value, so we don't provide follow-on completions.
        if arg.isNullary { return nil }

        return """
              \(arg.bashCompletionWords.joined(separator: "|")))
          \(arg.bashValueCompletion(self).indentingEachLine(by: 8))\
                  return
                  ;;
          """
      }
      .joined(separator: "\n")
    if !optionHandlers.isEmpty {
      result += """
            case "${prev}" in
        \(optionHandlers)
            esac

        """
    }

    // Build out completions for the subcommands.
    if !subcommands.isEmpty {
      // Subcommands have their own case statement that delegates out to
      // the subcommand completion functions.
      result += "    case \"${COMP_WORDS[\(dollarOne)]}\" in\n"
      for subcommand in subcommands {
        result += """
              \(subcommand._commandName))
                  \(functionName)_\(subcommand._commandName) \(subcommandArgument)
                  return
                  ;;

          """
      }
      result += "    esac\n"
    }

    // Finish off the function.
    result += """
          COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
      }

      """

    return
      result + subcommands.map { (self + [$0]).completionFunctions }.joined()
  }
}

extension ArgumentDefinition {
  /// Returns the different completion names for this argument.
  fileprivate var bashCompletionWords: [String] {
    help.visibility.base == .default
      ? names.map(\.synopsisString)
      : []
  }

  /// Returns the bash completions that can follow this argument's `--name`.
  ///
  /// Uses bash-completion for file and directory values if available.
  fileprivate func bashValueCompletion(
    _ commands: [ParsableCommand.Type]
  ) -> String {
    switch completion.kind {
    case .default:
      return ""

    case .file(let extensions) where extensions.isEmpty:
      return """
        if declare -F _filedir >/dev/null; then
            _filedir
        else
            COMPREPLY=($(compgen -f -- "${cur}"))
        fi

        """

    case .file(let extensions):
      var safeExts = extensions.map { $0.shellEscapeForSingleQuotedString() }
      safeExts.append(contentsOf: safeExts.map { $0.uppercased() })

      return """
        if declare -F _filedir >/dev/null; then
            \(safeExts.map { "_filedir '\($0)'" }.joined(separator:"\n    "))
            _filedir -d
        else
            COMPREPLY=(
                \(safeExts.map { "$(compgen -f -X '!*.\($0)' -- \"${cur}\")" }.joined(separator: "\n        "))
                $(compgen -d -- "${cur}")
            )
        fi

        """

    case .directory:
      return """
        if declare -F _filedir >/dev/null; then
            _filedir -d
        else
            COMPREPLY=($(compgen -d -- "${cur}"))
        fi

        """

    case .list(let list):
      return """
        COMPREPLY=($(compgen -W "\(list.joined(separator: " "))" -- "${cur}"))

        """

    case .shellCommand(let command):
      return """
        COMPREPLY=($(\(command)))

        """

    case .custom:
      // Generate a call back into the command to retrieve a completions list
      return """
        COMPREPLY=($(compgen -W "$("${COMP_WORDS[0]}" \(customCompletionCall(commands)) "${COMP_WORDS[@]}")" -- "${cur}"))

        """
    }
  }
}
