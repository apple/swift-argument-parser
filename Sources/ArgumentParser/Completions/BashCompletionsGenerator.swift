//===----------------------------------------------------------------------===//
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

      \(cursorIndexInCurrentWordFunctionName)() {
          local remaining="${COMP_LINE}"

          local word
          for word in "${COMP_WORDS[@]::COMP_CWORD}"; do
              remaining="${remaining##*([[:space:]])"${word}"*([[:space:]])}"
          done

          local -ir index="$((COMP_POINT - ${#COMP_LINE} + ${#remaining}))"
          if [[ "${index}" -le 0 ]]; then
              printf 0
          else
              printf %s "${index}"
          fi
      }

      # positional arguments:
      #
      # - 1: the current (sub)command's count of positional arguments
      #
      # required variables:
      #
      # - flags: the flags that the current (sub)command can accept
      # - options: the options that the current (sub)command can accept
      # - positional_number: value ignored
      # - unparsed_words: unparsed words from the current command line
      #
      # modified variables:
      #
      # - flags: remove flags for this (sub)command that are already on the command line
      # - options: remove options for this (sub)command that are already on the command line
      # - positional_number: set to the current positional number
      # - unparsed_words: remove all flags, options, and option values for this (sub)command
      \(offerFlagsOptionsFunctionName)() {
          local -ir positional_count="${1}"
          positional_number=0

          local was_flag_option_terminator_seen=false
          local is_parsing_option_value=false

          local -ar unparsed_word_indices=("${!unparsed_words[@]}")
          local -i word_index
          for word_index in "${unparsed_word_indices[@]}"; do
              if "${is_parsing_option_value}"; then
                  # This word is an option value:
                  # Reset marker for next word iff not currently the last word
                  [[ "${word_index}" -ne "${unparsed_word_indices[${#unparsed_word_indices[@]} - 1]}" ]] && is_parsing_option_value=false
                  unset "unparsed_words[${word_index}]"
                  # Do not process this word as a flag or an option
                  continue
              fi

              local word="${unparsed_words["${word_index}"]}"
              if ! "${was_flag_option_terminator_seen}"; then
                  case "${word}" in
                  --)
                      unset "unparsed_words[${word_index}]"
                      # by itself -- is a flag/option terminator, but if it is the last word, it is the start of a completion
                      if [[ "${word_index}" -ne "${unparsed_word_indices[${#unparsed_word_indices[@]} - 1]}" ]]; then
                          was_flag_option_terminator_seen=true
                      fi
                      continue
                      ;;
                  -*)
                      # ${word} is a flag or an option
                      # If ${word} is an option, mark that the next word to be parsed is an option value
                      local option
                      for option in "${options[@]}"; do
                          [[ "${word}" = "${option}" ]] && is_parsing_option_value=true && break
                      done

                      # Remove ${word} from ${flags} or ${options} so it isn't offered again
                      local not_found=true
                      local -i index
                      for index in "${!flags[@]}"; do
                          if [[ "${flags[${index}]}" = "${word}" ]]; then
                              unset "flags[${index}]"
                              flags=("${flags[@]}")
                              not_found=false
                              break
                          fi
                      done
                      if "${not_found}"; then
                          for index in "${!options[@]}"; do
                              if [[ "${options[${index}]}" = "${word}" ]]; then
                                  unset "options[${index}]"
                                  options=("${options[@]}")
                                  break
                              fi
                          done
                      fi
                      unset "unparsed_words[${word_index}]"
                      continue
                      ;;
                  esac
              fi

              # ${word} is neither a flag, nor an option, nor an option value
              if [[ "${positional_number}" -lt "${positional_count}" ]]; then
                  # ${word} is a positional
                  ((positional_number++))
                  unset "unparsed_words[${word_index}]"
              else
                  if [[ -z "${word}" ]]; then
                      # Could be completing a flag, option, or subcommand
                      positional_number=-1
                  else
                      # ${word} is a subcommand or invalid, so stop processing this (sub)command
                      positional_number=-2
                  fi
                  break
              fi
          done

          unparsed_words=("${unparsed_words[@]}")

          if\\
              ! "${was_flag_option_terminator_seen}"\\
              && ! "${is_parsing_option_value}"\\
              && [[ ("${cur}" = -* && "${positional_number}" -ge 0) || "${positional_number}" -eq -1 ]]
          then
              COMPREPLY+=($(compgen -W "${flags[*]} ${options[*]}" -- "${cur}"))
          fi
      }

      \(addCompletionsFunctionName)() {
          local completion
          while IFS='' read -r completion; do
              COMPREPLY+=("${completion}")
          done < <(IFS=$'\\n' compgen "${@}" -- "${cur}")
      }

      \(customCompleteFunctionName)() {
          if [[ -n "${cur}" || -z ${COMP_WORDS[${COMP_CWORD}]} || "${COMP_LINE:${COMP_POINT}:1}" != ' ' ]]; then
              local -ar words=("${COMP_WORDS[@]}")
          else
              local -ar words=("${COMP_WORDS[@]::${COMP_CWORD}}" '' "${COMP_WORDS[@]:${COMP_CWORD}}")
          fi

          "${COMP_WORDS[0]}" "${@}" "${words[@]}"
      }

      \(completionFunctions)\
      complete -o filenames -F \(completionFunctionName().shellEscapeForVariableName()) \(commandName)
      """
  }

  /// Generates a Bash completion function for the last command in the given list.
  private var completionFunctions: String {
    guard let type = last else {
      fatalError()
    }
    let functionName =
      completionFunctionName().shellEscapeForVariableName()

    var subcommands =
      type.configuration.subcommands.filter { $0.configuration.shouldDisplay }

    // Start building the resulting function code.
    var result = ""

    // Include initial setup iff the root command.
    let declareTopLevelArray: String
    if count == 1 {
      subcommands.addHelpSubcommandIfMissing()

      result += """
            trap "$(shopt -p);$(shopt -po)" RETURN
            shopt -s extglob
            set +o history +o posix

            local -xr \(CompletionShell.shellEnvironmentVariableName)=bash
            local -x \(CompletionShell.shellVersionEnvironmentVariableName)
            \(CompletionShell.shellVersionEnvironmentVariableName)="$(IFS='.';printf %s "${BASH_VERSINFO[*]}")"
            local -r \(CompletionShell.shellVersionEnvironmentVariableName)

            local -r cur="${2}"
            local -r prev="${3}"

            local -i positional_number
            local -a unparsed_words=("${COMP_WORDS[@]:1:${COMP_CWORD}}")


        """

      declareTopLevelArray = "local -a "
    } else {
      declareTopLevelArray = ""
    }

    let positionalArguments = positionalArguments

    let flagCompletions = flagCompletions
    let optionCompletions = optionCompletions
    if !flagCompletions.isEmpty || !optionCompletions.isEmpty {
      result += """
            \(declareTopLevelArray)flags=(\(flagCompletions.joined(separator: " ")))
            \(declareTopLevelArray)options=(\(optionCompletions.joined(separator: " ")))
            \(offerFlagsOptionsFunctionName) \(positionalArguments.count)

        """
    }

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
          \(bashValueCompletion(arg).indentingEachLine(by: 8))\
                  return
                  ;;
          """
      }
      .joined(separator: "\n")
    if !optionHandlers.isEmpty {
      result += """

            # Offer option value completions
            case "${prev}" in
        \(optionHandlers)
            esac

        """
    }

    let positionalCases =
      zip(1..., positionalArguments)
      .compactMap { position, arg in
        let completion = bashValueCompletion(arg)
        return completion.isEmpty
          ? nil
          : """
              \(position))
          \(completion.indentingEachLine(by: 8))\
                  return
                  ;;

          """
      }

    if !positionalCases.isEmpty {
      result += """

            # Offer positional completions
            case "${positional_number}" in
        \(positionalCases.joined())\
            esac

        """
    }

    if !subcommands.isEmpty {
      result += """

            # Offer subcommand / subcommand argument completions
            local -r subcommand="${unparsed_words[0]}"
            unset 'unparsed_words[0]'
            unparsed_words=("${unparsed_words[@]}")
            case "${subcommand}" in
            \(subcommands.map { $0._commandName }.joined(separator: "|")))
                # Offer subcommand argument completions
                "\(functionName)_${subcommand}"
                ;;
            *)
                # Offer subcommand completions
                COMPREPLY+=($(compgen -W '\(
                  subcommands.map { $0._commandName.shellEscapeForSingleQuotedString() }.joined(separator: " ")
                )' -- "${cur}"))
                ;;
            esac

        """
    }

    if result.isEmpty {
      result = "    :\n"
    }

    return """
      \(functionName)() {
      \(result)\
      }

      \(subcommands.map { (self + [$0]).completionFunctions }.joined())
      """
  }

  /// Returns flag completions for the last command of the given array.
  private var flagCompletions: [String] {
    argumentsForHelp(visibility: .default).flatMap {
      switch ($0.kind, $0.update) {
      case (.named, .nullary):
        return $0.bashCompletionWords
      default:
        return []
      }
    }
  }

  /// Returns option completions for the last command of the given array.
  private var optionCompletions: [String] {
    argumentsForHelp(visibility: .default).flatMap {
      switch ($0.kind, $0.update) {
      case (.named, .unary):
        return $0.bashCompletionWords
      default:
        return []
      }
    }
  }

  /// Returns the bash completions that can follow the given argument's `--name`.
  private func bashValueCompletion(_ arg: ArgumentDefinition) -> String {
    switch arg.completion.kind {
    case .default:
      return ""

    case .file(let extensions) where extensions.isEmpty:
      return """
        \(addCompletionsFunctionName) -f

        """

    case .file(let extensions):
      let exts =
        extensions
        .map { $0.shellEscapeForSingleQuotedString() }.joined(separator: "|")
      return """
        \(addCompletionsFunctionName) -o plusdirs -fX '!*.@(\(exts))'

        """

    case .directory:
      return """
        \(addCompletionsFunctionName) -d

        """

    case .list(let list):
      return """
        \(addCompletionsFunctionName) -W\
         '\(list.map { $0.shellEscapeForSingleQuotedString() }.joined(separator: "'$'\\n''"))'

        """

    case .shellCommand(let command):
      return """
        \(addCompletionsFunctionName) -W "$(eval '\(command.shellEscapeForSingleQuotedString())')"

        """

    case .custom:
      // Generate a call back into the command to retrieve a completions list
      return """
        \(addCompletionsFunctionName) -W\
         "$(\(customCompleteFunctionName) \(arg.customCompletionCall(self))\
         "${COMP_CWORD}"\
         "$(\(cursorIndexInCurrentWordFunctionName))")"

        """

    case .customDeprecated:
      // Generate a call back into the command to retrieve a completions list
      return """
        \(addCompletionsFunctionName) -W\
         "$(\(customCompleteFunctionName) \(arg.customCompletionCall(self)))"

        """
    }
  }

  private var cursorIndexInCurrentWordFunctionName: String {
    "_\(prefix(1).completionFunctionName().shellEscapeForVariableName())_cursor_index_in_current_word"
  }

  private var offerFlagsOptionsFunctionName: String {
    "_\(prefix(1).completionFunctionName().shellEscapeForVariableName())_offer_flags_options"
  }

  private var addCompletionsFunctionName: String {
    "_\(prefix(1).completionFunctionName().shellEscapeForVariableName())_add_completions"
  }

  private var customCompleteFunctionName: String {
    "_\(prefix(1).completionFunctionName().shellEscapeForVariableName())_custom_complete"
  }
}

extension ArgumentDefinition {
  /// Returns the different completion names for this argument.
  fileprivate var bashCompletionWords: [String] {
    help.visibility.base == .default
      ? names.map(\.synopsisString)
      : []
  }
}
