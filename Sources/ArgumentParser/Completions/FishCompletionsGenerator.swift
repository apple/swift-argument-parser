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

#if compiler(>=6.0)
internal import ArgumentParserToolInfo
#else
import ArgumentParserToolInfo
#endif

extension ToolInfoV0 {
  var fishCompletionScript: String {
    command.fishCompletionScript
  }
}

extension CommandInfoV0 {
  fileprivate var fishCompletionScript: String {
    """
    function \(shouldOfferCompletionsForFlagsOrOptionsFunctionName) -a expected_commands
        set -l non_repeating_flags_or_options $argv[2..]

        set -l non_repeating_flags_or_options_absent 0
        set -l positional_index 0
        set -l commands
        \(parseTokensFunctionName)
        test "$commands" = "$expected_commands"; and return $non_repeating_flags_or_options_absent
    end

    function \(shouldOfferCompletionsForPositionalFunctionName) -a expected_commands expected_positional_index positional_index_comparison
        if test -z $positional_index_comparison
            set positional_index_comparison -eq
        end

        set -l non_repeating_flags_or_options
        set -l non_repeating_flags_or_options_absent 0
        set -l positional_index 0
        set -l commands
        \(parseTokensFunctionName)
        test "$commands" = "$expected_commands" -a \\( "$positional_index" "$positional_index_comparison" "$expected_positional_index" \\)
    end

    function \(parseTokensFunctionName) -S
        set -l unparsed_tokens (\(tokensFunctionName) -pc)
        set -l present_flags_and_options

        switch $unparsed_tokens[1]
    \(commandCases)
        end
    end

    function \(tokensFunctionName)
        if test (string split -m 1 -f 1 -- . "$FISH_VERSION") -gt 3
            commandline --tokens-raw $argv
        else
            commandline -o $argv
        end
    end

    function \(parseSubcommandFunctionName) -S -a positional_count
        argparse -s r -- $argv
        set -l option_specs $argv[2..]

        set -a commands $unparsed_tokens[1]
        set -e unparsed_tokens[1]

        set positional_index 0

        while true
            argparse -sn "$commands" $option_specs -- $unparsed_tokens 2> /dev/null
            set unparsed_tokens $argv
            set positional_index (math $positional_index + 1)

            for non_repeating_flag_or_option in $non_repeating_flags_or_options
                if set -ql _flag_$non_repeating_flag_or_option
                    set non_repeating_flags_or_options_absent 1
                    break
                end
            end

            if test (count $unparsed_tokens) -eq 0 -o \\( -z "$_flag_r" -a "$positional_index" -gt "$positional_count" \\)
                break
            end
            set -e unparsed_tokens[1]
        end
    end

    function \(completeDirectoriesFunctionName)
        set -l token (commandline -t)
        string match -- '*/' $token
        set -l subdirs $token*/
        printf '%s\\n' $subdirs
    end

    function \(customCompletionFunctionName)
        set -x \(Platform.Environment.Key.shellName.rawValue) fish
        set -x \(Platform.Environment.Key.shellVersion.rawValue) $FISH_VERSION

        set -l tokens (\(tokensFunctionName) -p)
        if test -z (\(tokensFunctionName) -t)
            set -l index (count (\(tokensFunctionName) -pc))
            set tokens $tokens[..$index] \\'\\' $tokens[(math $index + 1)..]
        end
        command $tokens[1] $argv $tokens
    end

    complete -c '\(commandName)' -f
    \(completions.joined(separator: "\n"))
    """
  }

  private var commandCases: String {
    let subcommands = (subcommands ?? []).filter(\.shouldDisplay)
    return """
      case '\(commandName)'
          \(parseSubcommandFunctionName) \(positionalArgumentCountArguments) \(
            completableArguments
            .compactMap(\.optionSpec)
            .map { "'\($0.fishEscapeForSingleQuotedString())'" }
            .joined(separator: separator)
          )\(
            subcommands.isEmpty
              ? ""
              : """

                  switch $unparsed_tokens[1]
              \(subcommands.map(\.commandCases).joined(separator: "\n"))
                  end
              """
          )
      """
      .indentingEachLine(by: 4)
  }

  private var completions: [String] {
    let prefix = "complete -c '\(initialCommand)' -n '"

    let subcommands = (subcommands ?? []).filter(\.shouldDisplay)

    var positionalIndex = 0

    var repeatingPositionalComparison = ""
    let argumentCompletions =
      completableArguments
      .compactMap { arg in
        if arg.kind == .positional {
          guard repeatingPositionalComparison.isEmpty else {
            return nil as String?
          }

          if arg.isRepeating {
            repeatingPositionalComparison = " -ge"
          }
        }

        return """
          \(prefix)\(
            arg.kind == .positional
            ? """
            \(shouldOfferCompletionsForPositionalFunctionName) "\(commandContext.joined(separator: separator))" \({
              positionalIndex += 1
              return "\(positionalIndex)\(repeatingPositionalComparison)"
            }())
            """
            : """
              \(shouldOfferCompletionsForFlagsOrOptionsFunctionName) "\(commandContext.joined(separator: separator))"\
              \((arg.isRepeating ? [] : arg.names ?? []).map { " \($0.name)" }.sorted().joined())
              """
          )' \(argumentSegments(arg).joined(separator: separator))
          """
      }

    positionalIndex += 1

    return
      argumentCompletions
      + subcommands.map {
        """
        \(prefix)\(shouldOfferCompletionsForPositionalFunctionName) "\(commandContext.joined(separator: separator))"\
         \(positionalIndex)' -fa '\($0.commandName)' -d '\($0.abstract?.fishEscapeForSingleQuotedString() ?? "")'
        """
      }
      + subcommands.flatMap(\.completions)
  }

  private var completableArguments: [ArgumentInfoV0] {
    (arguments ?? []).compactMap { arg in
      switch arg.completionKind {
      case .none where arg.names?.isEmpty ?? true:
        return nil
      default:
        return
          arg.shouldDisplay
          ? arg
          : nil
      }
    }
  }

  private func argumentSegments(_ arg: ArgumentInfoV0) -> [String] {
    var results: [String] = []

    if let names = arg.names, !names.isEmpty {
      results += names.map(\.asCompleteArgument)
      if let abstract = arg.abstract, !abstract.isEmpty {
        results += [
          "-d '\(abstract.fishEscapeForSingleQuotedString())'"
        ]
      }
    }

    let r = arg.kind == .positional ? "" : "r"

    switch arg.completionKind {
    case .none:
      switch arg.kind {
      case .positional,
        .option:
        results += ["-\(r)fka ''"]
      default:
        break
      }
      break
    case .list(let list):
      results += ["-\(r)fka '\(list.joined(separator: separator))'"]
    case .file(let extensions):
      switch extensions.count {
      case 0:
        results += ["-\(r)F"]
      case 1:
        results += [
          """
          -\(r)fa '(\
          for p in (string match -e -- \\'*/\\' (commandline -t);or printf \\n)*.\\'\(extensions.map { $0.fishEscapeForSingleQuotedString(iterationCount: 2) }.joined())\\';printf %s\\n $p;end;\
          __fish_complete_directories (commandline -t) \\'\\'\
          )'
          """
        ]
      default:
        results += [
          """
          -\(r)fa '(\
          set -l exts \(extensions.map { "\\'\($0.fishEscapeForSingleQuotedString(iterationCount: 2))\\'" }.joined(separator: separator));\
          for p in (string match -e -- \\'*/\\' (commandline -t);or printf \\n)*.{$exts};printf %s\\n $p;end;\
          __fish_complete_directories (commandline -t) \\'\\'\
          )'
          """
        ]
      }
    case .directory:
      results += ["-\(r)fa '(\(completeDirectoriesFunctionName))'"]
    case .shellCommand(let shellCommand):
      results += [
        "-\(r)fka '(\(shellCommand.fishEscapeForSingleQuotedString()))'"
      ]
    case .custom, .customAsync:
      results += [
        """
        -\(r)fka '(\
        \(customCompletionFunctionName) \(arg.commonCustomCompletionCall(command: self)) \
        (count (\(tokensFunctionName) -pc)) (\(tokensFunctionName) -tC)\
        )'
        """
      ]
    case .customDeprecated:
      results += [
        """
        -\(r)fka '(\(customCompletionFunctionName) \(arg.commonCustomCompletionCall(command: self)))'
        """
      ]
    }

    return results
  }

  var positionalArgumentCountArguments: String {
    let positionalArguments = positionalArguments
    return """
      \(positionalArguments.contains(where: { $0.isRepeating }) ? "-r " : "")\(positionalArguments.count)
      """
  }

  private var shouldOfferCompletionsForFlagsOrOptionsFunctionName: String {
    "\(completionFunctionPrefix)_should_offer_completions_for_flags_or_options"
  }

  private var shouldOfferCompletionsForPositionalFunctionName: String {
    "\(completionFunctionPrefix)_should_offer_completions_for_positional"
  }

  private var parseTokensFunctionName: String {
    "\(completionFunctionPrefix)_parse_tokens"
  }

  private var tokensFunctionName: String {
    "\(completionFunctionPrefix)_tokens"
  }

  private var parseSubcommandFunctionName: String {
    "\(completionFunctionPrefix)_parse_subcommand"
  }

  private var completeDirectoriesFunctionName: String {
    "\(completionFunctionPrefix)_complete_directories"
  }

  private var customCompletionFunctionName: String {
    "\(completionFunctionPrefix)_custom_completion"
  }
}

extension ArgumentInfoV0 {
  fileprivate var optionSpec: String? {
    guard let shortName = name(.short) else {
      guard let longName = name(.long) else {
        return nil
      }
      return optionSpecRequiresValue(longName)
    }
    guard let longName = name(.long) else {
      return optionSpecRequiresValue(shortName)
    }
    return optionSpecRequiresValue("\(shortName)/\(longName)")
  }

  private func name(_ nameKind: NameInfoV0.KindV0) -> String? {
    (names ?? []).first(where: { $0.kind == nameKind })?.name
  }

  private func optionSpecRequiresValue(_ optionSpec: String) -> String {
    switch kind {
    case .option:
      return "\(optionSpec)=\(isRepeating ? "+" : "")"
    default:
      return optionSpec
    }
  }
}

extension ArgumentInfoV0.NameInfoV0 {
  fileprivate var asCompleteArgument: String {
    switch kind {
    case .long:
      return "-l '\(name.fishEscapeForSingleQuotedString())'"
    case .short:
      return "-s '\(name.fishEscapeForSingleQuotedString())'"
    case .longWithSingleDash:
      return "-o '\(name.fishEscapeForSingleQuotedString())'"
    }
  }
}

extension String {
  fileprivate func fishEscapeForSingleQuotedString(
    iterationCount: UInt64 = 1
  ) -> Self {
    iterationCount == 0
      ? self
      : self
        .replacing("\\", with: "\\\\")
        .replacing("'", with: "\\'")
        .fishEscapeForSingleQuotedString(iterationCount: iterationCount - 1)
  }
}

private var separator: String { " " }
