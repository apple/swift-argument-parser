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

#if swift(>=6.0)
internal import ArgumentParserToolInfo
internal import class Foundation.JSONEncoder
#else
import ArgumentParserToolInfo
import class Foundation.JSONEncoder
#endif

internal struct DumpHelpGenerator {
  private var toolInfo: ToolInfoV0

  init(_ type: ParsableArguments.Type) {
    self.init(commandStack: [type.asCommand])
  }

  init(commandStack: [ParsableCommand.Type]) {
    self.toolInfo = ToolInfoV0(commandStack: commandStack)
  }

  func rendered() -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    encoder.outputFormatting.insert(.sortedKeys)
    guard let encoded = try? encoder.encode(self.toolInfo) else { return "" }
    return String(data: encoded, encoding: .utf8) ?? ""
  }
}

extension BidirectionalCollection where Element == ParsableCommand.Type {
  /// Returns the ArgumentSet for the last command in this stack, including
  /// help and version flags, when appropriate.
  fileprivate func allArguments() -> ArgumentSet {
    guard
      var arguments = self.last.map({
        ArgumentSet($0, visibility: .private, parent: nil)
      })
    else { return ArgumentSet() }
    self.versionArgumentDefinition().map { arguments.append($0) }
    self.helpArgumentDefinition().map { arguments.append($0) }
    return arguments
  }
}

extension ArgumentSet {
  fileprivate func mergingCompositeArguments() -> ArgumentSet {
    var arguments = ArgumentSet()
    var slice = self[...]
    while var argument = slice.popFirst() {
      if argument.help.isComposite {
        // If this argument is composite, we have a group of arguments to
        // merge together.
        let groupEnd =
          slice
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

        argument.help.valueName =
          group.map(\.valueName).first { !$0.isEmpty } ?? ""
        argument.help.defaultValue = group.compactMap(\.help.defaultValue).first
        argument.help.abstract =
          group.map(\.help.abstract).first { !$0.isEmpty } ?? ""
        argument.help.discussion = group.compactMap(\.help.discussion).first
      }
      arguments.append(argument)
    }
    return arguments
  }
}

extension ToolInfoV0 {
  fileprivate init(commandStack: [ParsableCommand.Type]) {
    self.init(command: CommandInfoV0(commandStack: commandStack))
    // FIXME: This is a hack to inject the help command into the tool info
    // instead we should try to lift this into the parseable command tree
    var helpCommandInfo = CommandInfoV0(commandStack: [HelpCommand.self])
    helpCommandInfo.superCommands =
      (self.command.superCommands ?? []) + [self.command.commandName]
    self.command.subcommands =
      (self.command.subcommands ?? []) + [helpCommandInfo]
  }
}

extension CommandInfoV0 {
  fileprivate init(commandStack: [ParsableCommand.Type]) {
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
    let arguments =
      commandStack
      .allArguments()
      .mergingCompositeArguments()
      .compactMap(ArgumentInfoV0.init)

    self = CommandInfoV0(
      superCommands: superCommands,
      shouldDisplay: command.configuration.shouldDisplay,
      commandName: command._commandName,
      abstract: command.configuration.abstract,
      discussion: command.configuration.discussion,
      defaultSubcommand: defaultSubcommand,
      subcommands: subcommands,
      arguments: arguments)
  }
}

extension ArgumentInfoV0 {
  fileprivate init?(argument: ArgumentDefinition) {
    guard let kind = ArgumentInfoV0.KindV0(argument: argument) else {
      return nil
    }

    let discussion: String?
    let allValueDescriptions: [String: String]?
    switch argument.help.discussion {
    case .none:
      discussion = nil
      allValueDescriptions = nil
    case .staticText(let _discussion):
      discussion = _discussion
      allValueDescriptions = nil
    case .enumerated(let _discussion, let options):
      discussion = _discussion
      allValueDescriptions = options.allValueDescriptions
    }

    self.init(
      kind: kind,
      shouldDisplay: argument.help.visibility.base == .default,
      sectionTitle: argument.help.parentTitle.nonEmpty,
      isOptional: argument.help.options.contains(.isOptional),
      isRepeating: argument.help.options.contains(.isRepeating),
      names: argument.names.map(ArgumentInfoV0.NameInfoV0.init),
      preferredName: argument.names.preferredName.map(
        ArgumentInfoV0.NameInfoV0.init),
      valueName: argument.valueName,
      defaultValue: argument.help.defaultValue,
      allValueStrings: argument.help.allValueStrings,
      allValueDescriptions: allValueDescriptions,
      completionKind: ArgumentInfoV0.CompletionKindV0(
        completion: argument.completion),
      abstract: argument.help.abstract,
      discussion: discussion)
  }
}

extension ArgumentInfoV0.KindV0 {
  fileprivate init?(argument: ArgumentDefinition) {
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
      return nil
    }
  }
}

extension ArgumentInfoV0.NameInfoV0 {
  fileprivate init(name: Name) {
    switch name {
    case .long(let n):
      self.init(kind: .long, name: n)
    case .short(let n, _):
      self.init(kind: .short, name: String(n))
    case .longWithSingleDash(let n):
      self.init(kind: .longWithSingleDash, name: n)
    }
  }
}

extension ArgumentInfoV0.CompletionKindV0 {
  fileprivate init?(completion: CompletionKind) {
    switch completion.kind {
    case .`default`:
      return nil
    case .list(let values):
      self = .list(values: values)
    case .file(let extensions):
      self = .file(extensions: extensions)
    case .directory:
      self = .directory
    case .shellCommand(let command):
      self = .shellCommand(command: command)
    case .custom(_):
      self = .custom
    case .customDeprecated(_):
      self = .customDeprecated
    }
  }
}
