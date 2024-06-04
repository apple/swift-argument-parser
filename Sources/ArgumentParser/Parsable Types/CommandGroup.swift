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

/// A set of commands grouped together under a common name.
public struct CommandGroup: Sendable {
  /// The name of the command group that will be displayed in help.
  public let name: String

  /// The list of subcommands that are part of this group.
  public let subcommands: [ParsableCommand.Type]

  /// Create a command group.
  public init(
    name: String,
    @CommandsBuilder subcommands: () -> [ParsableCommand.Type]
  ) {
    self.name = name
    self.subcommands = subcommands()
  }
}

/// Result builder that forms a list of commands.
@resultBuilder
public struct CommandsBuilder {
  public static func buildExpression(_ command: ParsableCommand.Type) -> [ParsableCommand.Type] {
    return [command]
  }

  public static func buildBlock(_ commands: [ParsableCommand.Type]...) -> [ParsableCommand.Type] {
    return commands.flatMap { $0 }
  }

  public static func buildOptional(_ commands: [ParsableCommand.Type]?) -> [ParsableCommand.Type] {
    return commands ?? []
  }

  public static func buildEither(first commands: [ParsableCommand.Type]) -> [ParsableCommand.Type] {
    return commands
  }

  public static func buildEither(second commands: [ParsableCommand.Type]) -> [ParsableCommand.Type] {
    return commands
  }

  public static func buildLimitedAvailability(_ commands: [ParsableCommand.Type]) -> [ParsableCommand.Type] {
    return commands
  }

  public static func buildArray(_ commands: [[any ParsableCommand.Type]]) -> [any ParsableCommand.Type] {
    return commands.flatMap { $0 }
  }
}
