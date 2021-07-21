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

fileprivate extension Collection {
  var nonEmpty: Self? { isEmpty ? nil : self }
}

@_spi(ToolInfo)
public struct ToolInfoHeader: Decodable {
  public var serializationVersion: Int

  public init(serializationVersion: Int) {
    self.serializationVersion = serializationVersion
  }
}

@_spi(ToolInfo)
public struct ToolInfoV0: Codable, Hashable {
  public var serializationVersion: Int = 0
  public var command: CommandInfoV0

  public init(
    serializationVersion: Int = 0,
    command: CommandInfoV0
  ) {
    self.serializationVersion = serializationVersion
    self.command = command
  }
}

@_spi(ToolInfo)
public struct CommandInfoV0: Codable, Hashable {
  public var superCommands: [String]?

  public var commandName: String
  public var abstract: String?
  public var discussion: String?

  public var defaultSubcommand: String?
  public var subcommands: [CommandInfoV0]?
  public var arguments: [ArgumentInfoV0]?

  public init(
    superCommands: [String],
    commandName: String,
    abstract: String,
    discussion: String,
    defaultSubcommand: String?,
    subcommands: [CommandInfoV0],
    arguments: [ArgumentInfoV0]
  ) {
    self.superCommands = superCommands.nonEmpty

    self.commandName = commandName
    self.abstract = abstract.nonEmpty
    self.discussion = discussion.nonEmpty

    self.defaultSubcommand = defaultSubcommand?.nonEmpty
    self.subcommands = subcommands.nonEmpty
    self.arguments = arguments.nonEmpty
  }
}

@_spi(ToolInfo)
public struct ArgumentInfoV0: Codable, Hashable {
  public struct NameInfoV0: Codable, Hashable {
    public enum KindV0: String, Codable, Hashable {
      case long
      case short
      case longWithSingleDash
    }
    public var kind: KindV0
    public var name: String

    public init(kind: NameInfoV0.KindV0, name: String) {
      self.kind = kind
      self.name = name
    }
  }

  public enum KindV0: String, Codable, Hashable {
    case positional
    case option
    case flag
  }

  public var kind: KindV0

  public var shouldDisplay: Bool
  public var isOptional: Bool
  public var isRepeating: Bool

  public var names: [NameInfoV0]?
  public var preferredName: NameInfoV0?

  public var valueName: String?
  public var defaultValue: String?
  public var allValues: [String]?

  public var abstract: String?
  public var discussion: String?

  public init(
    kind: KindV0,
    shouldDisplay: Bool,
    isOptional: Bool,
    isRepeating: Bool,
    names: [NameInfoV0]?,
    preferredName: NameInfoV0?,
    valueName: String?,
    defaultValue: String?,
    allValues: [String]?,
    abstract: String?,
    discussion: String?
  ) {
    self.kind = kind

    self.shouldDisplay = shouldDisplay
    self.isOptional = isOptional
    self.isRepeating = isRepeating

    self.names = names?.nonEmpty
    self.preferredName = preferredName

    self.valueName = valueName?.nonEmpty
    self.defaultValue = defaultValue?.nonEmpty
    self.allValues = allValues?.nonEmpty

    self.abstract = abstract?.nonEmpty
    self.discussion = discussion?.nonEmpty
  }
}
