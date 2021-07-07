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
  var `optional`: Self? { isEmpty ? nil : self }
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
    self.superCommands = superCommands.optional

    self.commandName = commandName
    self.abstract = abstract.optional
    self.discussion = discussion.optional

    self.defaultSubcommand = defaultSubcommand?.optional
    self.subcommands = subcommands.optional
    self.arguments = arguments.optional
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
    abstract: String?,
    discussion: String?
  ) {
    self.kind = kind

    self.shouldDisplay = shouldDisplay
    self.isOptional = isOptional
    self.isRepeating = isRepeating

    self.names = names?.optional
    self.preferredName = preferredName

    self.valueName = valueName?.optional
    self.defaultValue = defaultValue?.optional

    self.abstract = abstract?.optional
    self.discussion = discussion?.optional
  }
}
