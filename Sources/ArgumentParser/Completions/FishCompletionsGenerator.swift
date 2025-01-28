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

struct FishCompletionsGenerator {
  static func generateCompletionScript(_ type: ParsableCommand.Type) -> String {
    let commandName = type._commandName
    let usingCommandFunctionName =
      usingCommandFunctionName(commandName: commandName)
    let commandsAndPositionalsFunctionName =
      commandsAndPositionalsFunctionName(commandName: commandName)
    return """
      # A function which filters options which starts with "-" from $argv.
      function \(commandsAndPositionalsFunctionName)
          set -l results
          for i in (seq (count $argv))
              switch (echo $argv[$i] | string sub -l 1)
                  case '-'
                  case '*'
                      echo $argv[$i]
              end
          end
      end

      function \(usingCommandFunctionName)
          set -gx \(CompletionShell.shellEnvironmentVariableName) fish
          set -gx \(CompletionShell.shellVersionEnvironmentVariableName) "$FISH_VERSION"
          set -l commands_and_positionals (\(commandsAndPositionalsFunctionName) (commandline -opc))
          set -l expected_commands (string split -- '\(separator)' $argv[1])
          set -l subcommands (string split -- '\(separator)' $argv[2])
          if [ (count $commands_and_positionals) -ge (count $expected_commands) ]
              for i in (seq (count $expected_commands))
                  if [ $commands_and_positionals[$i] != $expected_commands[$i] ]
                      return 1
                  end
              end
              if [ (count $commands_and_positionals) -eq (count $expected_commands) ]
                  return 0
              end
              if [ (count $subcommands) -gt 1 ]
                  for i in (seq (count $subcommands))
                      if [ $commands_and_positionals[(math (count $expected_commands) + 1)] = $subcommands[$i] ]
                          return 1
                      end
                  end
              end
              return 0
          end
          return 1
      end

      \(generateCompletions([type]).joined(separator: "\n"))
      """
  }
}

// MARK: - Private functions

extension FishCompletionsGenerator {
  private static func generateCompletions(
    _ commands: [ParsableCommand.Type]
  ) -> [String] {
    guard let type = commands.last else { return [] }
    let isRootCommand = commands.count == 1
    let programName = commands[0]._commandName
    var subcommands = type.configuration.subcommands
      .filter { $0.configuration.shouldDisplay }

    if isRootCommand {
      subcommands.addHelpSubcommandIfMissing()
    }

    let usingCommandFunctionName =
      usingCommandFunctionName(commandName: programName)

    var prefix =
      "complete -c \(programName) -n '\(usingCommandFunctionName) \"\(commands.map { $0._commandName }.joined(separator: separator))\""
    if !subcommands.isEmpty {
      prefix +=
        " \"\(subcommands.map { $0._commandName }.joined(separator: separator))\""
    }
    prefix += "'"

    func complete(suggestion: String) -> String {
      "\(prefix) \(suggestion)"
    }

    let subcommandCompletions: [String] = subcommands.map { subcommand in
      let escapedAbstract =
        subcommand.configuration.abstract.fishEscapeForSingleQuotedString()
      let suggestion =
        "-fa '\(subcommand._commandName)' -d '\(escapedAbstract)'"
      return complete(suggestion: suggestion)
    }

    let argumentCompletions =
      commands
      .argumentsForHelp(visibility: .default)
      .compactMap { $0.argumentSegments(commands) }
      .map { $0.joined(separator: " ") }
      .map { complete(suggestion: $0) }

    let completionsFromSubcommands = subcommands.flatMap { subcommand in
      generateCompletions(commands + [subcommand])
    }

    return
      completionsFromSubcommands + argumentCompletions + subcommandCompletions
  }
}

extension ArgumentDefinition {
  fileprivate func argumentSegments(
    _ commands: [ParsableCommand.Type]
  ) -> [String]? {
    guard help.visibility.base == .default
    else { return nil }

    var results: [String] = []

    if !names.isEmpty {
      results += names.map { $0.asFishSuggestion }
    }

    if !help.abstract.isEmpty {
      results += ["-d '\(help.abstract.fishEscapeForSingleQuotedString())'"]
    }

    switch completion.kind {
    case .default where names.isEmpty:
      return nil
    case .default:
      break
    case .list(let list):
      results += ["-rfka '\(list.joined(separator: " "))'"]
    case .file(let extensions):
      let pattern = "*.{\(extensions.joined(separator: ","))}"
      results += ["-rfa '(for i in \(pattern); echo $i;end)'"]
    case .directory:
      results += ["-rfa '(__fish_complete_directories)'"]
    case .shellCommand(let shellCommand):
      results += ["-rfa '(\(shellCommand))'"]
    case .custom:
      guard let commandName = commands.first?._commandName else { return nil }
      results += [
        "-rfa '(command \(commandName) \(customCompletionCall(commands)) (commandline -opc)[1..-1])'"
      ]
    }

    return results
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

extension FishCompletionsGenerator {
  private static func commandsAndPositionalsFunctionName(
    commandName: String
  ) -> String {
    "_swift_\(commandName)_commands_and_positionals"
  }

  private static func usingCommandFunctionName(commandName: String) -> String {
    "_swift_" + commandName + "_using_command"
  }
}

private var separator: String { " " }
