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

  /// A short description of the commands in this group, which will be
  /// displayed in help.
  public let abstract: String?

  /// The list of subcommands that are part of this group.
  public let subcommands: [ParsableCommand.Type]

  /// Create a command group.
  public init(
    name: String,
    abstract: String? = nil,
    @CommandsBuilder subcommands: () -> [ParsableCommand.Type]
  ) {
    self.name = name
    self.abstract = abstract
    self.subcommands = subcommands()
  }
}

/// Result builder that forms a list of commands.
@resultBuilder
public struct CommandsBuilder {
  public static func buildBlock(_ commands: ParsableCommand.Type...) -> [ParsableCommand.Type] {
      return commands
  }
}
