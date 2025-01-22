struct FishCompletionsGenerator {
  static func generateCompletionScript(_ type: ParsableCommand.Type) -> String {
    let programName = type._commandName
    let helperFunctions = [
      preprocessorFunction(commandName: programName),
      helperFunction(commandName: programName)
    ]
    let completions = generateCompletions([type])

    return helperFunctions.joined(separator: "\n\n") + "\n\n" + completions.joined(separator: "\n")
  }
}

// MARK: - Private functions

extension FishCompletionsGenerator {
  private static func generateCompletions(_ commands: [ParsableCommand.Type]) -> [String] {
    let type = commands.last!
    let isRootCommand = commands.count == 1
    let programName = commands[0]._commandName
    var subcommands = type.configuration.subcommands
      .filter { $0.configuration.shouldDisplay }

    if !subcommands.isEmpty && isRootCommand {
      subcommands.append(HelpCommand.self)
    }

    let helperFunctionName = helperFunctionName(commandName: programName)

    var prefix = "complete -c \(programName) -n '\(helperFunctionName) \"\(commands.map { $0._commandName }.joined(separator: separator))\""
    if !subcommands.isEmpty {
      prefix += " \"\(subcommands.map { $0._commandName }.joined(separator: separator))\""
    }
    prefix += "'"

    func complete(suggestion: String) -> String {
      "\(prefix) \(suggestion)"
    }

    let subcommandCompletions: [String] = subcommands.map { subcommand in
      let escapedAbstract = subcommand.configuration.abstract.fishEscape()
      let suggestion = "-f -a '\(subcommand._commandName)' -d '\(escapedAbstract)'"
      return complete(suggestion: suggestion)
    }

    let argumentCompletions = commands
      .argumentsForHelp(visibility: .default)
      .compactMap { $0.argumentSegments(commands) }
      .map { $0.joined(separator: " ") }
      .map { complete(suggestion: $0) }

    let completionsFromSubcommands = subcommands.flatMap { subcommand in
      generateCompletions(commands + [subcommand])
    }

    return completionsFromSubcommands + argumentCompletions + subcommandCompletions
  }
}

extension ArgumentDefinition {
  fileprivate func argumentSegments(_ commands: [ParsableCommand.Type]) -> [String]? {
    guard help.visibility.base == .default
    else { return nil }
    
    var results: [String] = []
    
    if !names.isEmpty {
      results += names.map{ $0.asFishSuggestion }
    }
    
    if !help.abstract.isEmpty {
      results += ["-d '\(help.abstract.fishEscape())'"]
    }
    
    switch completion.kind {
    case .default where names.isEmpty:
      return nil
    case .default:
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
      let commandName = commands.first!._commandName
      results += ["-r -f -a '(command \(commandName) \(customCompletionCall(commands)) (commandline -opc)[1..-1])'"]
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
  fileprivate func fishEscape() -> String {
    replacingOccurrences(of: "'", with: #"\'"#)
  }
}

extension FishCompletionsGenerator {

  private static var separator: String { " " }

  private static func preprocessorFunctionName(commandName: String) -> String {
    "_swift_\(commandName)_preprocessor"
  }

  private static func preprocessorFunction(commandName: String) -> String {
    """
    # A function which filters options which starts with "-" from $argv.
    function \(preprocessorFunctionName(commandName: commandName))
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

  private static func helperFunctionName(commandName: String) -> String {
    "_swift_" + commandName + "_using_command"
  }

  private static func helperFunction(commandName: String) -> String {
    let functionName = helperFunctionName(commandName: commandName)
    let preprocessorFunctionName = preprocessorFunctionName(commandName: commandName)
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
}
