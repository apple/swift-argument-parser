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

/// Build a set of subcommands which can potentially be grouped.
@resultBuilder
public struct SubcommandsBuilder {
  public static func buildExpression(_ single: ParsableCommand.Type) -> [Subcommand] {
    return [.single(single)]
  }

  public static func buildExpression(_ group: CommandGroup) -> [Subcommand] {
    return [.group(group)]
  }

  public static func buildBlock(_ subcommands: [Subcommand]...) -> [Subcommand] {
    return subcommands.flatMap { $0 }
  }

  public static func buildOptional(_ component: [Subcommand]?) -> [Subcommand] {
    return component ?? []
  }

  public static func buildEither(first component: [Subcommand]) -> [Subcommand] {
    return component
  }

  public static func buildEither(second component: [Subcommand]) -> [Subcommand] {
    return component
  }

  public static func buildLimitedAvailability(_ component: [Subcommand]) -> [Subcommand] {
    return component
  }

  public static func buildArray(_ components: [[Subcommand]]) -> [Subcommand] {
    return components.flatMap { $0 }
  }
}

/// Describes a single subcommand or a group thereof.
public enum Subcommand: Sendable {
  case single(ParsableCommand.Type)
  case group(CommandGroup)
}

extension Subcommand {
  /// Return a flattened list of all of the subcommands in this tree where the
  /// group structure has been eliminated.
  var flattenedSubcommands: [ParsableCommand.Type] {
    switch self {
    case .single(let command):
      return [command]
    case .group(let group):
      return group.subcommands
    }
  }
}
