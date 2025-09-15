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
internal import Foundation
internal import ArgumentParserOpenCLI
#else
import Foundation
import ArgumentParserOpenCLI
#endif

internal struct OpenCLIGenerator {
  private var openCLI: OpenCLI

  init(_ type: ParsableArguments.Type) {
    self.init(commandStack: [type.asCommand])
  }

  init(commandStack: [ParsableCommand.Type]) {
    self.openCLI = OpenCLI(commandStack: commandStack)
  }

  func rendered() -> String {
    do {
      let encoder = Foundation.JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
      let data = try encoder.encode(self.openCLI)
      return String(data: data, encoding: .utf8) ?? "{}"
    } catch {
      return "{\"error\": \"Failed to encode OpenCLI: \(error)\"}"
    }
  }
}

extension OpenCLI {
  init(commandStack: [ParsableCommand.Type]) {
    guard let rootCommand = commandStack.first else {
      preconditionFailure("commandStack must not be empty")
    }

    let config = rootCommand.configuration
    let info = CliInfo(
      title: rootCommand._commandName,
      version: config.version.isEmpty ? "1.0.0" : config.version,
      summary: config.abstract.isEmpty ? nil : config.abstract,
      description: config.discussion.isEmpty ? nil : config.discussion
    )

    let argumentSet = commandStack.allArguments()
    let (options, arguments) = OpenCLI.extractOptionsAndArguments(
      from: argumentSet)

    let commands = config.subcommands.compactMap {
      subcommand -> ArgumentParserOpenCLI.Command? in
      ArgumentParserOpenCLI.Command(
        subcommand: subcommand, parentStack: commandStack)
    }

    self.init(
      opencli: "0.1",
      info: info,
      conventions: Conventions(),
      arguments: arguments.isEmpty ? nil : arguments,
      options: options.isEmpty ? nil : options,
      commands: commands.isEmpty ? nil : commands
    )
  }

  internal static func extractOptionsAndArguments(from argumentSet: ArgumentSet)
    -> ([ArgumentParserOpenCLI.Option], [ArgumentParserOpenCLI.Argument])
  {
    var options: [ArgumentParserOpenCLI.Option] = []
    var arguments: [ArgumentParserOpenCLI.Argument] = []

    for argDef in argumentSet {
      switch argDef.kind {
      case .named:
        if let option = ArgumentParserOpenCLI.Option(from: argDef) {
          options.append(option)
        }
      case .positional:
        if let argument = ArgumentParserOpenCLI.Argument(from: argDef) {
          arguments.append(argument)
        }
      case .default:
        break
      }
    }

    return (options, arguments)
  }
}

extension ArgumentParserOpenCLI.Command {
  init?(subcommand: ParsableCommand.Type, parentStack: [ParsableCommand.Type]) {
    let config = subcommand.configuration
    let commandStack = parentStack + [subcommand]
    let argumentSet = commandStack.allArguments()
    let (options, arguments) = OpenCLI.extractOptionsAndArguments(
      from: argumentSet)

    let subcommands = config.subcommands.compactMap {
      subSubcommand -> ArgumentParserOpenCLI.Command? in
      ArgumentParserOpenCLI.Command(
        subcommand: subSubcommand, parentStack: commandStack)
    }

    self.init(
      name: subcommand._commandName,
      aliases: config.aliases.isEmpty ? nil : config.aliases,
      options: options.isEmpty ? nil : options,
      arguments: arguments.isEmpty ? nil : arguments,
      commands: subcommands.isEmpty ? nil : subcommands,
      description: config.abstract.isEmpty ? nil : config.abstract,
      hidden: !config.shouldDisplay
    )
  }
}

extension ArgumentParserOpenCLI.Option {
  init?(from argDef: ArgumentDefinition) {
    guard case .named = argDef.kind else { return nil }

    let names = argDef.names.map { $0.synopsisString }
    guard let primaryName = names.first else { return nil }

    let aliases = Array(names.dropFirst())

    // Extract arguments for this option if it takes values
    var optionArguments: [ArgumentParserOpenCLI.Argument]? = nil
    switch argDef.update {
    case .unary:
      let argument = ArgumentParserOpenCLI.Argument(
        name: argDef.valueName,
        required: !argDef.help.options.contains(.isOptional),
        description: argDef.help.abstract.isEmpty ? nil : argDef.help.abstract
      )
      optionArguments = [argument]
    case .nullary:
      break
    }

    self.init(
      name: primaryName,
      required: !argDef.help.options.contains(.isOptional),
      aliases: aliases.isEmpty ? nil : aliases,
      arguments: optionArguments,
      description: argDef.help.abstract.isEmpty ? nil : argDef.help.abstract,
      hidden: argDef.help.visibility.base != .default
    )
  }
}

extension ArgumentParserOpenCLI.Argument {
  init?(from argDef: ArgumentDefinition) {
    guard case .positional = argDef.kind else { return nil }

    self.init(
      name: argDef.valueName,
      required: !argDef.help.options.contains(.isOptional),
      description: argDef.help.abstract.isEmpty ? nil : argDef.help.abstract,
      hidden: argDef.help.visibility.base != .default
    )
  }
}
