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

internal struct OpenCLIv0_1Generator {
  private var openCLI: OpenCLIv0_1

  init(_ type: ParsableArguments.Type) {
    self.init(commandStack: [type.asCommand])
  }

  init(commandStack: [ParsableCommand.Type]) {
    self.openCLI = OpenCLIv0_1(commandStack: commandStack)
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

extension OpenCLIv0_1 {
  init(commandStack: [ParsableCommand.Type]) {
    guard let rootCommand = commandStack.first else {
      preconditionFailure("commandStack must not be empty")
    }

    let config = rootCommand.configuration
    let info = OpenCLIv0_1.CliInfo(
      title: rootCommand._commandName,
      version: config.version.isEmpty ? "1.0.0" : config.version,
      summary: config.abstract.isEmpty ? nil : config.abstract,
      description: config.discussion.isEmpty ? nil : config.discussion
    )

    let argumentSet = commandStack.allArguments()
    let (options, arguments) = OpenCLIv0_1.extractOptionsAndArguments(
      from: argumentSet)

    let commands = config.subcommands.compactMap {
      subcommand -> OpenCLIv0_1.Command? in
      OpenCLIv0_1.Command(
        subcommand: subcommand, parentStack: commandStack)
    }

    let conventions = OpenCLIv0_1.Conventions()
    let conventionsToInclude =
      conventions.hasNonDefaultValues ? conventions : nil

    self.init(
      opencli: "0.1",
      info: info,
      conventions: conventionsToInclude,
      arguments: arguments.isEmpty ? nil : arguments,
      options: options.isEmpty ? nil : options,
      commands: commands.isEmpty ? nil : commands
    )
  }

  internal static func extractOptionsAndArguments(from argumentSet: ArgumentSet)
    -> ([OpenCLIv0_1.Option], [OpenCLIv0_1.Argument])
  {
    var options: [OpenCLIv0_1.Option] = []
    var arguments: [OpenCLIv0_1.Argument] = []

    for argDef in argumentSet {
      switch argDef.kind {
      case .named:
        if let option = OpenCLIv0_1.Option(from: argDef) {
          options.append(option)
        }
      case .positional:
        if let argument = OpenCLIv0_1.Argument(from: argDef) {
          arguments.append(argument)
        }
      case .default:
        break
      }
    }

    return (options, arguments)
  }
}

extension OpenCLIv0_1.Command {
  init?(subcommand: ParsableCommand.Type, parentStack: [ParsableCommand.Type]) {
    let config = subcommand.configuration
    let commandStack = parentStack + [subcommand]
    let argumentSet = commandStack.allArguments()
    let (options, arguments) = OpenCLIv0_1.extractOptionsAndArguments(
      from: argumentSet)

    let subcommands = config.subcommands.compactMap {
      subSubcommand -> OpenCLIv0_1.Command? in
      OpenCLIv0_1.Command(
        subcommand: subSubcommand, parentStack: commandStack)
    }

    self.init(
      name: subcommand._commandName,
      aliases: config.aliases.isEmpty ? nil : config.aliases,
      options: options.isEmpty ? nil : options,
      arguments: arguments.isEmpty ? nil : arguments,
      commands: subcommands.isEmpty ? nil : subcommands,
      description: config.abstract.isEmpty ? nil : config.abstract,
      hidden: !config.shouldDisplay ? true : nil
    )
  }
}

extension OpenCLIv0_1.Option {
  init?(from argDef: ArgumentDefinition) {
    guard case .named = argDef.kind else { return nil }

    let names = argDef.names.map { $0.synopsisString }
    guard let primaryName = names.first else { return nil }

    let aliases = Array(names.dropFirst())

    // Extract arguments for this option if it takes values
    var optionArguments: [OpenCLIv0_1.Argument]? = nil
    switch argDef.update {
    case .unary:
      let argument = OpenCLIv0_1.Argument(
        name: argDef.valueName,
        required: !argDef.help.options.contains(.isOptional) ? true : nil,
        description: argDef.help.abstract.isEmpty ? nil : argDef.help.abstract,
        swiftArgumentParserDefaultValue: argDef.help.defaultValue
      )
      optionArguments = [argument]
    case .nullary:
      break
    }

    self.init(
      name: primaryName,
      required: !argDef.help.options.contains(.isOptional) ? true : nil,
      aliases: aliases.isEmpty ? nil : aliases,
      arguments: optionArguments,
      description: argDef.help.abstract.isEmpty ? nil : argDef.help.abstract,
      hidden: argDef.help.visibility.base != .default ? true : nil,
      swiftArgumentParserRepeating: argDef.help.options.contains(.isRepeating)
        ? true : nil,
      swiftArgumentParserFile: {
        switch argDef.completion.kind {
        case .file(let extensions):
          return OpenCLIv0_1.SwiftArgumentParserFile(extensions: extensions)
        default: return nil
        }
      }(),
      swiftArgumentParserDirectory: {
        switch argDef.completion.kind {
        case .directory: return true
        default: return nil
        }
      }(),
      swiftArgumentParserDefaultValue: argDef.help.defaultValue
    )
  }
}

extension OpenCLIv0_1.Argument {
  init?(from argDef: ArgumentDefinition) {
    guard case .positional = argDef.kind else { return nil }

    self.init(
      name: argDef.valueName,
      required: !argDef.help.options.contains(.isOptional) ? true : nil,
      description: argDef.help.abstract.isEmpty ? nil : argDef.help.abstract,
      hidden: argDef.help.visibility.base != .default ? true : nil,
      swiftArgumentParserFile: {
        switch argDef.completion.kind {
        case .file(let extensions):
          return OpenCLIv0_1.SwiftArgumentParserFile(extensions: extensions)
        default: return nil
        }
      }(),
      swiftArgumentParserDirectory: {
        switch argDef.completion.kind {
        case .directory: return true
        default: return nil
        }
      }(),
      swiftArgumentParserDefaultValue: argDef.help.defaultValue
    )
  }
}
