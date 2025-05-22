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
  var fishCompletionScript: String {
    // swift-format-ignore: NeverForceUnwrap
    // Preconditions:
    // - first must be non-empty for a fish completion script to be of use.
    // - first is guaranteed non-empty in the one place where this computed var is used.
    let commandName = first!._commandName
    return """
      function \(shouldOfferCompletionsForFunctionName) -a expected_commands -a expected_positional_index
          set -l unparsed_tokens (\(tokensFunctionName) -pc)
          set -l positional_index 0
          set -l commands

          switch $unparsed_tokens[1]
      \(commandCases)
          end

          test "$commands" = "$expected_commands" -a \\( -z "$expected_positional_index" -o "$expected_positional_index" -eq "$positional_index" \\)
      end

      function \(tokensFunctionName)
          if test (string split -m 1 -f 1 -- . "$FISH_VERSION") -gt 3
              commandline --tokens-raw $argv
          else
              commandline -o $argv
          end
      end

      function \(parseSubcommandFunctionName) -S
          argparse -s r -- $argv
          set -l positional_count $argv[1]
          set -l option_specs $argv[2..]

          set -a commands $unparsed_tokens[1]
          set -e unparsed_tokens[1]

          set positional_index 0

          while true
              argparse -sn "$commands" $option_specs -- $unparsed_tokens 2> /dev/null
              set unparsed_tokens $argv
              set positional_index (math $positional_index + 1)
              if test (count $unparsed_tokens) -eq 0 -o \\( -z "$_flag_r" -a "$positional_index" -gt "$positional_count" \\)
                  return 0
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
          set -x \(CompletionShell.shellEnvironmentVariableName) fish
          set -x \(CompletionShell.shellVersionEnvironmentVariableName) $FISH_VERSION

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
    let subcommands = subcommands
    // swift-format-ignore: NeverForceUnwrap
    // Precondition: last is guaranteed to be non-empty
    return """
      case '\(last!._commandName)'
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
              \(subcommands.map { (self + [$0]).commandCases }.joined(separator: "\n"))
                  end
              """
          )
      """
      .indentingEachLine(by: 4)
  }

  private var completions: [String] {
    // swift-format-ignore: NeverForceUnwrap
    // Precondition: first is guaranteed to be non-empty
    let prefix = """
      complete -c '\(first!._commandName)'\
       -n '\(shouldOfferCompletionsForFunctionName)\
       "\(map { $0._commandName }.joined(separator: separator))"
      """

    let subcommands = subcommands

    var positionalIndex = 0

    let argumentCompletions =
      completableArguments
      .map { (arg: ArgumentDefinition) in
        """
        \(prefix)\(arg.isPositional
          ? """
          \({
            positionalIndex += 1
            return " \(positionalIndex)"
          }())
          """
          : ""
        )' \(argumentSegments(arg).joined(separator: separator))
        """
      }

    positionalIndex += 1

    return
      argumentCompletions
      + subcommands.map { subcommand in
        "\(prefix) \(positionalIndex)' -fa '\(subcommand._commandName)' -d '\(subcommand.configuration.abstract.fishEscapeForSingleQuotedString())'"
      }
      + subcommands.flatMap { subcommand in
        (self + [subcommand]).completions
      }
  }

  private var subcommands: Self {
    // swift-format-ignore: NeverForceUnwrap
    // Precondition: last is guaranteed to be non-empty
    var subcommands = last!.configuration.subcommands
      .filter { $0.configuration.shouldDisplay }
    if count == 1 {
      subcommands.addHelpSubcommandIfMissing()
    }
    return subcommands
  }

  private var completableArguments: [ArgumentDefinition] {
    argumentsForHelp(visibility: .default).compactMap { arg in
      switch arg.completion.kind {
      case .default where arg.names.isEmpty:
        return nil
      default:
        return
          arg.help.visibility.base == .default
          ? arg
          : nil
      }
    }
  }

  private func argumentSegments(_ arg: ArgumentDefinition) -> [String] {
    var results: [String] = []

    if !arg.names.isEmpty {
      results += arg.names.map { $0.asFishSuggestion }
      if !arg.help.abstract.isEmpty {
        results += [
          "-d '\(arg.help.abstract.fishEscapeForSingleQuotedString())'"
        ]
      }
    }

    let r = arg.isPositional ? "" : "r"

    switch arg.completion.kind {
    case .default:
      if case .unary = arg.update {
        results += ["-\(r)fka ''"]
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
      results += ["-\(r)fka '(\(shellCommand))'"]
    case .custom, .customAsync:
      results += [
        """
        -\(r)fka '(\
        \(customCompletionFunctionName) \(arg.customCompletionCall(self)) \
        (count (\(tokensFunctionName) -pc)) (\(tokensFunctionName) -tC)\
        )'
        """
      ]
    case .customDeprecated:
      results += [
        """
        -\(r)fka '(\(customCompletionFunctionName) \(arg.customCompletionCall(self)))'
        """
      ]
    }

    return results
  }

  var positionalArgumentCountArguments: String {
    let positionalArguments = positionalArguments
    return """
      \(positionalArguments.contains(where: { $0.isRepeatingPositional }) ? "-r " : "")\(positionalArguments.count)
      """
  }

  private var shouldOfferCompletionsForFunctionName: String {
    // swift-format-ignore: NeverForceUnwrap
    // Precondition: first is guaranteed to be non-empty
    "__\(first!._commandName)_should_offer_completions_for"
  }

  private var tokensFunctionName: String {
    // swift-format-ignore: NeverForceUnwrap
    // Precondition: first is guaranteed to be non-empty
    "__\(first!._commandName)_tokens"
  }

  private var parseSubcommandFunctionName: String {
    // swift-format-ignore: NeverForceUnwrap
    // Precondition: first is guaranteed to be non-empty
    "__\(first!._commandName)_parse_subcommand"
  }

  private var completeDirectoriesFunctionName: String {
    // swift-format-ignore: NeverForceUnwrap
    // Precondition: first is guaranteed to be non-empty
    "__\(first!._commandName)_complete_directories"
  }

  private var customCompletionFunctionName: String {
    // swift-format-ignore: NeverForceUnwrap
    // Precondition: first is guaranteed to be non-empty
    "__\(first!._commandName)_custom_completion"
  }
}

extension ArgumentDefinition {
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

  private func name(_ nameType: Name.Case) -> String? {
    names.first(where: {
      $0.case == nameType
    })?
    .valueString
  }

  private func optionSpecRequiresValue(_ optionSpec: String) -> String {
    switch update {
    case .unary:
      return "\(optionSpec)="
    default:
      return optionSpec
    }
  }
}

extension Name {
  fileprivate var asFishSuggestion: String {
    switch self {
    case .long(let longName):
      return "-l '\(longName.fishEscapeForSingleQuotedString())'"
    case .short(let shortName, _):
      return "-s '\(String(shortName).fishEscapeForSingleQuotedString())'"
    case .longWithSingleDash(let dashedName):
      return "-o '\(dashedName.fishEscapeForSingleQuotedString())'"
    }
  }
}

extension String {
  fileprivate func fishEscapeForSingleQuotedString(
    iterationCount: UInt64 = 1
  ) -> Self {
    iterationCount == 0
      ? self
      : replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "'", with: "\\'")
        .fishEscapeForSingleQuotedString(iterationCount: iterationCount - 1)
  }
}

private var separator: String { " " }
