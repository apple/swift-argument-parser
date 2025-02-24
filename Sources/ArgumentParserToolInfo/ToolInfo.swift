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

extension Collection {
  /// - returns: A non-empty collection or `nil`.
  fileprivate var nonEmpty: Self? { isEmpty ? nil : self }
}

/// Header used to validate serialization version of an encoded ToolInfo struct.
public struct ToolInfoHeader: Decodable {
  /// A sentinel value indicating the version of the ToolInfo struct used to
  /// generate the serialized form.
  public var serializationVersion: Int

  public init(serializationVersion: Int) {
    self.serializationVersion = serializationVersion
  }
}

/// Top-level structure containing serialization version and information for all
/// commands in a tool.
public struct ToolInfoV0: Codable, Hashable {
  /// A sentinel value indicating the version of the ToolInfo struct used to
  /// generate the serialized form.
  public var serializationVersion = 0
  /// Root command of the tool.
  public var command: CommandInfoV0

  public init(command: CommandInfoV0) {
    self.command = command
  }
}

/// All information about a particular command, including arguments and
/// subcommands.
public struct CommandInfoV0: Codable, Hashable {
  /// Super commands and tools.
  public var superCommands: [String]?
  /// Command should appear in help displays.
  public var shouldDisplay: Bool = true

  /// Name used to invoke the command.
  public var commandName: String
  /// Short description of the command's functionality.
  public var abstract: String?
  /// Extended description of the command's functionality.
  public var discussion: String?

  /// Optional name of the subcommand invoked when the command is invoked with
  /// no arguments.
  public var defaultSubcommand: String?
  /// List of nested commands.
  public var subcommands: [CommandInfoV0]?
  /// List of supported arguments.
  public var arguments: [ArgumentInfoV0]?

  public init(
    superCommands: [String],
    shouldDisplay: Bool,
    commandName: String,
    abstract: String,
    discussion: String,
    defaultSubcommand: String?,
    subcommands: [CommandInfoV0],
    arguments: [ArgumentInfoV0]
  ) {
    self.superCommands = superCommands.nonEmpty
    self.shouldDisplay = shouldDisplay

    self.commandName = commandName
    self.abstract = abstract.nonEmpty
    self.discussion = discussion.nonEmpty

    self.defaultSubcommand = defaultSubcommand?.nonEmpty
    self.subcommands = subcommands.nonEmpty
    self.arguments = arguments.nonEmpty
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.superCommands = try container.decodeIfPresent(
      [String].self, forKey: .superCommands)
    self.commandName = try container.decode(String.self, forKey: .commandName)
    self.abstract = try container.decodeIfPresent(
      String.self, forKey: .abstract)
    self.discussion = try container.decodeIfPresent(
      String.self, forKey: .discussion)
    self.shouldDisplay =
      try container.decodeIfPresent(Bool.self, forKey: .shouldDisplay) ?? true
    self.defaultSubcommand = try container.decodeIfPresent(
      String.self, forKey: .defaultSubcommand)
    self.subcommands = try container.decodeIfPresent(
      [CommandInfoV0].self, forKey: .subcommands)
    self.arguments = try container.decodeIfPresent(
      [ArgumentInfoV0].self, forKey: .arguments)
  }
}

/// All information about a particular argument, including display names and
/// options.
public struct ArgumentInfoV0: Codable, Hashable {
  /// Information about an argument's name.
  public struct NameInfoV0: Codable, Hashable {
    /// Kind of prefix of an argument's name.
    public enum KindV0: String, Codable, Hashable {
      /// A multi-character name preceded by two dashes.
      case long
      /// A single character name preceded by a single dash.
      case short
      /// A multi-character name preceded by a single dash.
      case longWithSingleDash
    }

    /// Kind of prefix the NameInfoV0 describes.
    public var kind: KindV0
    /// Single or multi-character name of the argument.
    public var name: String

    public init(kind: NameInfoV0.KindV0, name: String) {
      self.kind = kind
      self.name = name
    }
  }

  /// Kind of argument.
  public enum KindV0: String, Codable, Hashable {
    /// Argument specified as a bare value on the command line.
    case positional
    /// Argument specified as a value prefixed by a `--flag` on the command line.
    case option
    /// Argument specified only as a `--flag` on the command line.
    case flag
  }

  public enum CompletionKindV0: Codable, Hashable {
    /// Use the specified list of completion strings.
    case list(values: [String])
    /// Complete file names with the specified extensions.
    case file(extensions: [String])
    /// Complete directory names that match the specified pattern.
    case directory
    /// Call the given shell command to generate completions.
    case shellCommand(command: String)
    /// Generate completions using the given closure.
    case custom
  }

  /// Kind of argument the ArgumentInfo describes.
  public var kind: KindV0

  /// Argument should appear in help displays.
  public var shouldDisplay: Bool
  /// Custom name of argument's section.
  public var sectionTitle: String?

  /// Argument can be omitted.
  public var isOptional: Bool
  /// Argument can be specified multiple times.
  public var isRepeating: Bool

  /// All names of the argument.
  public var names: [NameInfoV0]?
  /// The best name to use when referring to the argument in help displays.
  public var preferredName: NameInfoV0?

  /// Name of argument's value.
  public var valueName: String?
  /// Default value of the argument is none is specified on the command line.
  public var defaultValue: String?
  // NOTE: this property will not be renamed to 'allValueStrings' to avoid
  // breaking compatibility with the current serialized format.
  //
  // This property is effectively deprecated.
  /// List of all valid values.
  public var allValues: [String]?
  /// List of all valid values.
  public var allValueStrings: [String]? {
    get { self.allValues }
    set { self.allValues = newValue }
  }
  /// Mapping of valid values to descriptions of the value.
  public var allValueDescriptions: [String: String]?

  /// The type of completion to use for an argument or option.
  ///
  /// `nil` if the tool use use the default completion kind.
  public var completionKind: CompletionKindV0?

  /// Short description of the argument's functionality.
  public var abstract: String?
  /// Extended description of the argument's functionality.
  public var discussion: String?

  public init(
    kind: KindV0,
    shouldDisplay: Bool,
    sectionTitle: String?,
    isOptional: Bool,
    isRepeating: Bool,
    names: [NameInfoV0]?,
    preferredName: NameInfoV0?,
    valueName: String?,
    defaultValue: String?,
    allValueStrings: [String]?,
    allValueDescriptions: [String: String]?,
    completionKind: CompletionKindV0?,
    abstract: String?,
    discussion: String?
  ) {
    self.kind = kind

    self.shouldDisplay = shouldDisplay
    self.sectionTitle = sectionTitle

    self.isOptional = isOptional
    self.isRepeating = isRepeating

    self.names = names?.nonEmpty
    self.preferredName = preferredName

    self.valueName = valueName?.nonEmpty
    self.defaultValue = defaultValue?.nonEmpty
    self.allValueStrings = allValueStrings?.nonEmpty
    self.allValueDescriptions = allValueDescriptions?.nonEmpty

    self.completionKind = completionKind

    self.abstract = abstract?.nonEmpty
    self.discussion = discussion?.nonEmpty
  }
}
