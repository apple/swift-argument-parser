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

@_implementationOnly import Foundation
@_implementationOnly import ArgumentParserToolInfo

internal struct DumpHelpGenerator {
  var toolInfo: ToolInfoV0

  init(_ type: ParsableArguments.Type) {
    self.init(commandStack: [type.asCommand])
  }

  init(commandStack: [ParsableCommand.Type]) {
    self.toolInfo = ToolInfoV0(commandStack: commandStack)
  }

  func rendered() -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    if #available(macOS 10.13, iOS 11.0, *) {
      encoder.outputFormatting.insert(.sortedKeys)
    }
    guard let encoded = try? encoder.encode(self.toolInfo) else { return "" }
    return String(data: encoded, encoding: .utf8) ?? ""
  }
}

fileprivate extension BidirectionalCollection where Element == ParsableCommand.Type {
  /// Returns the ArgumentSet for the last command in this stack, including
  /// help and version flags, when appropriate.
  func allArguments() -> ArgumentSet {
    guard var arguments = self.last.map({ ArgumentSet($0, creatingHelp: false) })
    else { return ArgumentSet() }
    self.versionArgumentDefinition().map { arguments.append($0) }
    self.helpArgumentDefinition().map { arguments.append($0) }
    return arguments
  }
}

fileprivate extension ArgumentSet {
  func mergingCompositeArguments() -> ArgumentSet {
    var arguments = ArgumentSet()
    var slice = self[...]
    while var argument = slice.popFirst() {
      if argument.help.isComposite {
        // If this argument is composite, we have a group of arguments to
        // merge together.
        let groupEnd = slice
          .firstIndex { $0.help.keys != argument.help.keys }
          ?? slice.endIndex
        let group = [argument] + slice[..<groupEnd]
        slice = slice[groupEnd...]

        switch argument.kind {
        case .named:
          argument.kind = .named(group.flatMap(\.names))
        case .positional, .default:
          break
        }

        argument.help.valueName = group.map(\.valueName).first { !$0.isEmpty } ?? ""
        argument.help.defaultValue = group.compactMap(\.help.defaultValue).first
        argument.help.abstract = group.map(\.help.abstract).first { !$0.isEmpty } ?? ""
        argument.help.discussion = group.map(\.help.discussion).first { !$0.isEmpty } ?? ""
      }
      arguments.append(argument)
    }
    return arguments
  }
}

fileprivate extension ToolInfoV0 {
  init(commandStack: [ParsableCommand.Type]) {
    self.init(command: CommandInfoV0(commandStack: commandStack))
  }
}

fileprivate extension CommandInfoV0 {
  init(commandStack: [ParsableCommand.Type]) {
    guard let command = commandStack.last else {
      preconditionFailure("commandStack must not be empty")
    }

    let parents = commandStack.dropLast()
    var superCommands = parents.map { $0._commandName }
    if let superName = parents.first?.configuration._superCommandName {
      superCommands.insert(superName, at: 0)
    }

    let defaultSubcommand = command.configuration.defaultSubcommand?
      .configuration.commandName
    let subcommands = command.configuration.subcommands
      .map { subcommand -> CommandInfoV0 in
        var commandStack = commandStack
        commandStack.append(subcommand)
        return CommandInfoV0(commandStack: commandStack)
      }
    let arguments = commandStack
      .allArguments()
      .mergingCompositeArguments()
      .map(ArgumentInfoV0.init)

    self = CommandInfoV0(
      superCommands: superCommands,
      commandName: command._commandName,
      abstract: command.configuration.abstract,
      discussion: command.configuration.discussion,
      defaultSubcommand: defaultSubcommand,
      subcommands: subcommands,
      arguments: arguments)
  }
}

fileprivate extension ArgumentInfoV0 {
  init(argument: ArgumentDefinition) {
    self.init(
      kind: ArgumentInfoV0.KindV0(argument: argument),
      shouldDisplay: argument.help.shouldDisplay,
      isOptional: argument.help.options.contains(.isOptional),
      isRepeating: argument.help.options.contains(.isRepeating),
      names: argument.names.map(ArgumentInfoV0.NameInfoV0.init),
      preferredName: argument.names.preferredName.map(ArgumentInfoV0.NameInfoV0.init),
      valueName: argument.valueName,
      defaultValue: argument.help.defaultValue,
      allValues: argument.help.allValues,
      abstract: argument.help.abstract,
      discussion: argument.help.discussion)
  }
}

fileprivate extension ArgumentInfoV0.KindV0 {
  init(argument: ArgumentDefinition) {
    switch argument.kind {
    case .named:
      switch argument.update {
      case .nullary:
        self = .flag
      case .unary:
        self = .option
      }
    case .positional:
      self = .positional
    case .default:
      preconditionFailure("argument.kind must not be .default")
    }
  }
}

fileprivate extension ArgumentInfoV0.NameInfoV0 {
  init(name: Name) {
    switch name {
    case let .long(n):
      self.init(kind: .long, name: n)
    case let .short(n, _):
      self.init(kind: .short, name: String(n))
    case let .longWithSingleDash(n):
      self.init(kind: .longWithSingleDash, name: n)
    }
  }
}
