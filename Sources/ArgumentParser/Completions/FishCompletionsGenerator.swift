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

import ArgumentParserToolInfo

extension String {
  fileprivate func fishEscape() -> String {
    replacingOccurrences(of: "'", with: #"\'"#)
  }
}

struct FishCompletionsGenerator {
  /// Generates a Fish completion script for the given command.
  static func generateCompletionScript(_ type: ParsableCommand.Type) -> String {
    return ToolInfoV0(commandStack: [type]).fishCompletionScript()
  }
}

extension ToolInfoV0 {
  fileprivate func fishCompletionScript() -> String {
    let helperFunctions = [
      self.command.fishPreprocessorFunction(),
      self.command.fishHelperFunction()
    ]
    let completions = self.command.fishCompletions()
    return
      helperFunctions.joined(separator: "\n\n")
      + "\n\n"
      + completions.joined(separator: "\n")
  }
}

extension CommandInfoV0 {
  fileprivate func fishProgramName() -> String {
    self.superCommands?.first ?? self.commandName
  }

  fileprivate func fishCommandContext() -> [String] {
    return (self.superCommands ?? []) + [self.commandName]
  }

  fileprivate func fishPreprocessorFunctionName() -> String {
    "_swift_\(self.fishProgramName())_preprocessor"
  }

  fileprivate func fishPreprocessorFunction() -> String {
    let preprocessorFunctionName = self.fishPreprocessorFunctionName()
    return """
      # A function which filters options which starts with "-" from $argv.
      function \(preprocessorFunctionName)
          set -l results
          for i in (seq (count $argv))
              switch (echo $argv[$i] | string sub -l 1)
                  case '-'
                  case '*'
                      echo $argv[$i]
              end
          end
      end
      """
  }

  fileprivate func fishHelperFunctionName() -> String {
    "_swift_\(self.fishProgramName())_using_command"
  }

  fileprivate func fishHelperFunction() -> String {
    let separator = " "

    let functionName = self.fishHelperFunctionName()
    let preprocessorFunctionName = self.fishPreprocessorFunctionName()
    return """
      function \(functionName)
          set -gx \(CompletionShell.shellEnvironmentVariableName) fish
          set -gx \(CompletionShell.shellVersionEnvironmentVariableName) "$FISH_VERSION"
          set -l currentCommands (\(preprocessorFunctionName) (commandline -opc))
          set -l expectedCommands (string split \"\(separator)\" $argv[1])
          set -l subcommands (string split \"\(separator)\" $argv[2])
          if [ (count $currentCommands) -ge (count $expectedCommands) ]
              for i in (seq (count $expectedCommands))
                  if [ $currentCommands[$i] != $expectedCommands[$i] ]
                      return 1
                  end
              end
              if [ (count $currentCommands) -eq (count $expectedCommands) ]
                  return 0
              end
              if [ (count $subcommands) -gt 1 ]
                  for i in (seq (count $subcommands))
                      if [ $currentCommands[(math (count $expectedCommands) + 1)] = $subcommands[$i] ]
                          return 1
                      end
                  end
              end
              return 0
          end
          return 1
      end
      """
  }

  fileprivate func fishCompletions() -> [String] {
    let subcommands = (self.subcommands ?? []).filter { $0.shouldDisplay }
    let programName = self.fishProgramName()
    let helperFunctionName = self.fishHelperFunctionName()

    var prefix = "complete -c \(programName) -n '\(helperFunctionName) \"\(self.fishCommandContext().joined(separator: " "))\""
    if !subcommands.isEmpty {
      prefix += " \"\(subcommands.map { $0.commandName }.joined(separator: " "))\""
    }
    prefix += "'"

    let subcommandCompletions: [String] = subcommands.map { subcommand in
      let escapedAbstract = (subcommand.abstract ?? "").fishEscape()
      let suggestion = "-f -a '\(subcommand.commandName)' -d '\(escapedAbstract)'"
      return "\(prefix) \(suggestion)"
    }

    let argumentCompletions = (self.arguments ?? [])
      .filter { $0.shouldDisplay }
      .compactMap { $0.fishCompletions(self) }
      .map { $0.joined(separator: " ") }
      .map { "\(prefix) \($0)" }

    let completionsFromSubcommands = subcommands.flatMap { $0.fishCompletions() }

    return completionsFromSubcommands + argumentCompletions + subcommandCompletions
  }
}

extension ArgumentInfoV0 {
  fileprivate func fishCompletions(_ command: CommandInfoV0) -> [String]? {
    var results: [String] = []

    results += (self.names ?? []).map { $0.fishCompletion() }

    if let abstract = self.abstract {
      results += ["-d '\(abstract.fishEscape())'"]
    }
    
    switch self.completionKind {
    case .none where (self.names ?? []).isEmpty:
      return nil
    case .none:
      break
    case .list(let list):
      results += ["-r -f -k -a '\(list.joined(separator: " "))'"]
    case .file(let extensions):
      let pattern = "*.{\(extensions.joined(separator: ","))}"
      results += ["-r -f -a '(for i in \(pattern); echo $i;end)'"]
    case .directory:
      results += ["-r -f -a '(__fish_complete_directories)'"]
    case .shellCommand(let shellCommand):
      results += ["-r -f -a '(\(shellCommand))'"]
    case .custom:
      results += ["-r -f -a '(command \(command.fishProgramName()) \(commonCustomCompletionCall(command: command)) (commandline -opc)[1..-1])'"]
    }

    return results
  }
}

extension ArgumentInfoV0.NameInfoV0 {
  fileprivate func fishCompletion() -> String {
    switch self.kind {
    case .long:
      return "-l \(self.name)"
    case .short:
      return "-s \(self.name)"
    case .longWithSingleDash:
      return "-o \(self.name)"
    }
  }
}
