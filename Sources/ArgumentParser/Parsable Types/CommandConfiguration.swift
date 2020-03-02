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

/// The configuration for a command.
public struct CommandConfiguration {
  /// The name of the command to use on the command line.
  ///
  /// If `nil`, the command name is derived by converting the name of
  /// the command type to hyphen-separated lowercase words.
  public var commandName: String?
  
  /// A one-line description of this command.
  public var abstract: String
  
  /// A longer description of this command, to be shown in the extended help
  /// display.
  public var discussion: String
  
  /// A Boolean value indicating whether this command should be shown in
  /// the extended help display.
  public var shouldDisplay: Bool
  
  /// An array of the types that define subcommands for this command.
  public var subcommands: [ParsableCommand.Type]
  
  /// The default command type to run if no subcommand is given.
  public var defaultSubcommand: ParsableCommand.Type?
  
  /// Flag names to be used for help.
  public var helpNames: NameSpecification
  
  /// Creates the configuration for a command.
  ///
  /// - Parameters:
  ///   - commandName: The name of the command to use on the command line. If
  ///     `commandName` is `nil`, the command name is derived by converting
  ///     the name of the command type to hyphen-separated lowercase words.
  ///   - abstract: A one-line description of the command.
  ///   - discussion: A longer description of the command.
  ///   - shouldDisplay: A Boolean value indicating whether the command
  ///     should be shown in the extended help display.
  ///   - subcommands: An array of the types that define subcommands for the
  ///     command.
  ///   - defaultSubcommand: The default command type to run if no subcommand
  ///     is given.
  ///   - helpNames: The flag names to use for requesting help, simulating
  ///     a Boolean property named `help`.
  public init(
    commandName: String? = nil,
    abstract: String = "",
    discussion: String = "",
    shouldDisplay: Bool = true,
    subcommands: [ParsableCommand.Type] = [],
    defaultSubcommand: ParsableCommand.Type? = nil,
    helpNames: NameSpecification = [.short, .long]
  ) {
    self.commandName = commandName
    self.abstract = abstract
    self.discussion = discussion
    self.shouldDisplay = shouldDisplay
    self.subcommands = subcommands
    self.defaultSubcommand = defaultSubcommand
    self.helpNames = helpNames
  }
}


