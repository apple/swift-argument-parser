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
      function \(commandsAndPositionalsFunctionName) -S
          switch $positionals[1]
      \(commandCases)
          case '*'
              set commands $positionals[1]
              set -e positionals[1]
          end
      end

      function \(commandsAndPositionalsFunctionName)_helper -S -a argparse_options
          set -l option_specs $argv[2..]
          set -a commands $positionals[1]
          set -e positionals[1]
          if test -z $argparse_options
              argparse -n "$commands" $option_specs -- $positionals 2> /dev/null
              set positionals $argv
          else
              argparse (string split -- '\(separator)' $argparse_options) -n "$commands" $option_specs -- $positionals 2> /dev/null
              set positionals $argv
          end
      end

      function \(tokensFunctionName)
          if test (string split -m 1 -f 1 -- . $FISH_VERSION) -gt 3
              commandline --tokens-raw $argv
          else
              commandline -o $argv
          end
      end

      function \(usingCommandFunctionName) -a expected_commands
          set commands
          set positionals (\(tokensFunctionName) -pc)
          \(commandsAndPositionalsFunctionName)
          test "$commands" = $expected_commands
      end

      function \(positionalIndexFunctionName)
          set positionals (\(tokensFunctionName) -pc)
          \(commandsAndPositionalsFunctionName)
          math (count $positionals) + 1
      end

      function \(completeDirectoriesFunctionName)
          set token (commandline -t)
          string match -- '*/' $token
          set subdirs $token*/
          printf '%s\\n' $subdirs
      end

      function \(customCompletionFunctionName)
          set -x \(CompletionShell.shellEnvironmentVariableName) fish
          set -x \(CompletionShell.shellVersionEnvironmentVariableName) $FISH_VERSION

          set tokens (\(tokensFunctionName) -p)
          if test -z (\(tokensFunctionName) -t)
              set index (count (\(tokensFunctionName) -pc))
              set tokens $tokens[..$index] \\'\\' $tokens[$(math $index + 1)..]
          end
          command $tokens[1] $argv $tokens
      end

      complete -c \(commandName) -f
      \(completions.joined(separator: "\n"))
      """
  }

  private var commandCases: String {
    let subcommands = subcommands
    // swift-format-ignore: NeverForceUnwrap
    // Precondition: last is guaranteed to be non-empty
    return """
      case '\(last!._commandName)'
          \(commandsAndPositionalsFunctionName)_helper '\(
            subcommands.isEmpty ? "" : "-s"
          )' \(
            completableArguments
            .compactMap(\.optionSpec)
            .map { "'\($0.fishEscapeForSingleQuotedString())'" }
            .joined(separator: separator)
          )\(
            subcommands.isEmpty
              ? ""
              : """

                  switch $positionals[1]
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
    let commandName = first!._commandName
    let prefix = """
      complete -c \(commandName)\
       -n '\(usingCommandFunctionName)\
       "\(map { $0._commandName }.joined(separator: separator))"
      """

    let subcommands = subcommands

    func complete(suggestion: String, extraTests: [String] = []) -> String {
      "\(prefix)\(extraTests.map { ";\($0)" }.joined())' \(suggestion)"
    }

    let subcommandCompletions: [String] = subcommands.map { subcommand in
      complete(
        suggestion:
          "-fa '\(subcommand._commandName)' -d '\(subcommand.configuration.abstract.fishEscapeForSingleQuotedString())'"
      )
    }

    var positionalIndex = 0

    let argumentCompletions =
      completableArguments
      .map { (arg: ArgumentDefinition) in
        complete(
          suggestion: argumentSegments(arg).joined(separator: separator),
          extraTests: arg.isPositional
            ? [
              """
              and test (\(positionalIndexFunctionName)) \
              -eq \({
                positionalIndex += 1
                return positionalIndex
              }())
              """
            ]
            : []
        )
      }

    let completionsFromSubcommands = subcommands.flatMap { subcommand in
      (self + [subcommand]).completions
    }

    return
      completionsFromSubcommands + argumentCompletions + subcommandCompletions
  }

  private var subcommands: Self {
    guard
      let command = last,
      ArgumentSet(command, visibility: .default, parent: nil)
        .filter(\.isPositional).isEmpty
    else {
      return []
    }
    var subcommands = command.configuration.subcommands
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

    switch arg.completion.kind {
    case .default:
      break
    case .list(let list):
      results += ["-rfka '\(list.joined(separator: separator))'"]
    case .file(let extensions):
      switch extensions.count {
      case 0:
        results += ["-rF"]
      case 1:
        results += [
          """
          -rfa '(\
          for p in (string match -e -- \\'*/\\' (commandline -t);or printf \\n)*.\\'\(extensions.map { $0.fishEscapeForSingleQuotedString(iterationCount: 2) }.joined())\\';printf %s\\n $p;end;\
          __fish_complete_directories (commandline -t) \\'\\'\
          )'
          """
        ]
      default:
        results += [
          """
          -rfa '(\
          set exts \(extensions.map { "\\'\($0.fishEscapeForSingleQuotedString(iterationCount: 2))\\'" }.joined(separator: separator));\
          for p in (string match -e -- \\'*/\\' (commandline -t);or printf \\n)*.{$exts};printf %s\\n $p;end;\
          __fish_complete_directories (commandline -t) \\'\\'\
          )'
          """
        ]
      }
    case .directory:
      results += ["-rfa '(\(completeDirectoriesFunctionName))'"]
    case .shellCommand(let shellCommand):
      results += ["-rfka '(\(shellCommand))'"]
    case .custom:
      results += [
        """
        -rfka '(\(customCompletionFunctionName) \(arg.customCompletionCall(self)))'
        """
      ]
    }

    return results
  }

  private var commandsAndPositionalsFunctionName: String {
    // swift-format-ignore: NeverForceUnwrap
    // Precondition: first is guaranteed to be non-empty
    "_swift_\(first!._commandName)_commands_and_positionals"
  }

  private var tokensFunctionName: String {
    // swift-format-ignore: NeverForceUnwrap
    // Precondition: first is guaranteed to be non-empty
    "_swift_\(first!._commandName)_tokens"
  }

  private var usingCommandFunctionName: String {
    // swift-format-ignore: NeverForceUnwrap
    // Precondition: first is guaranteed to be non-empty
    "_swift_\(first!._commandName)_using_command"
  }

  private var positionalIndexFunctionName: String {
    // swift-format-ignore: NeverForceUnwrap
    // Precondition: first is guaranteed to be non-empty
    "_swift_\(first!._commandName)_positional_index"
  }

  private var completeDirectoriesFunctionName: String {
    // swift-format-ignore: NeverForceUnwrap
    // Precondition: first is guaranteed to be non-empty
    "_swift_\(first!._commandName)_complete_directories"
  }

  private var customCompletionFunctionName: String {
    // swift-format-ignore: NeverForceUnwrap
    // Precondition: first is guaranteed to be non-empty
    "_swift_\(first!._commandName)_custom_completion"
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
      return "-l \(longName)"
    case .short(let shortName, _):
      return "-s \(shortName)"
    case .longWithSingleDash(let dashedName):
      return "-o \(dashedName)"
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
