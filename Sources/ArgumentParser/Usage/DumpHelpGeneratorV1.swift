//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
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

internal struct DumpHelpGeneratorV1 {
  private var toolInfo: ToolInfoV1

  init(_ type: ParsableArguments.Type) {
    self.init(commandStack: [type.asCommand])
  }

  init(commandStack: [ParsableCommand.Type]) {
    self.toolInfo = ToolInfoV1(commandStack: commandStack)
  }

  func rendered() -> String {
    JSONEncoder.encode(self.toolInfo)
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

extension ToolInfoV1 {
  init(commandStack: [ParsableCommand.Type]) {
    self.init(command: CommandInfo(commandStack: commandStack))
    // FIXME: This is a hack to inject the help command into the tool info
    // instead we should try to lift this into the parseable command tree
    self.command.subcommands =
      (self.command.subcommands ?? []) + [
        CommandInfo(commandStack: commandStack + [HelpCommand.self])
      ]
  }
}

extension ToolInfoV1.CommandInfo {
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
      .map { subcommand -> ToolInfoV1.CommandInfo in
        var commandStack = commandStack
        commandStack.append(subcommand)
        return ToolInfoV1.CommandInfo(commandStack: commandStack)
      }
    let arguments =
      commandStack
      .allArguments()
      .compactMap(ToolInfoV1.ArgumentInfo.init)

    self = ToolInfoV1.CommandInfo(
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

extension ToolInfoV1.ArgumentInfo {
  fileprivate init?(argument: ArgumentDefinition) {
    guard let kind = ToolInfoV1.ArgumentInfo.Kind(argument: argument) else {
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
      parsingStrategy: ToolInfoV1.ArgumentInfo.ParsingStrategy(
        argument: argument),
      names: argument.names.map(ToolInfoV1.ArgumentInfo.NameInfo.init),
      preferredName: argument.names.preferredName.map(
        ToolInfoV1.ArgumentInfo.NameInfo.init),
      valueName: argument.valueName,
      defaultValue: argument.help.defaultValue,
      allValueStrings: argument.help.allValueStrings,
      allValueDescriptions: allValueDescriptions,
      completionKind: ToolInfoV1.ArgumentInfo.CompletionKind(
        completion: argument.completion),
      abstract: argument.help.abstract,
      discussion: discussion)
  }
}

extension ToolInfoV1.ArgumentInfo.Kind {
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

extension ToolInfoV1.ArgumentInfo.ParsingStrategy {
  fileprivate init(argument: ArgumentDefinition) {
    switch argument.parsingStrategy {
    case .`default`:
      self = .default
    case .scanningForValue:
      self = .scanningForValue
    case .unconditional:
      self = .unconditional
    case .upToNextOption:
      self = .upToNextOption
    case .allRemainingInput:
      self = .allRemainingInput
    case .postTerminator:
      self = .postTerminator
    case .allUnrecognized:
      self = .allUnrecognized
    }
  }
}

extension ToolInfoV1.ArgumentInfo.NameInfo {
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

extension ToolInfoV1.ArgumentInfo.CompletionKind {
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
    case .customAsync(_):
      self = .customAsync
    case .customDeprecated(_):
      self = .customDeprecated
    }
  }
}
