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

/// A shell for which the parser can generate a completion script.
public struct CompletionShell: RawRepresentable, Hashable, CaseIterable {
  public var rawValue: String

  /// Creates a new instance from the given string.
  public init?(rawValue: String) {
    switch rawValue {
    case "zsh", "bash", "fish":
      self.rawValue = rawValue
    default:
      return nil
    }
  }

  /// An instance representing `zsh`.
  public static var zsh: CompletionShell {
    // swift-format-ignore: NeverForceUnwrap
    // Statically known valid raw value.
    CompletionShell(rawValue: "zsh")!
  }

  /// An instance representing `bash`.
  public static var bash: CompletionShell {
    // swift-format-ignore: NeverForceUnwrap
    // Statically known valid raw value.
    CompletionShell(rawValue: "bash")!
  }

  /// An instance representing `fish`.
  public static var fish: CompletionShell {
    // swift-format-ignore: NeverForceUnwrap
    // Statically known valid raw value.
    CompletionShell(rawValue: "fish")!
  }

  /// Returns an instance representing the current shell, if recognized.
  public static func autodetected() -> CompletionShell? {
    Platform.shellName.flatMap(CompletionShell.init(rawValue:))
  }

  /// An array of all supported shells for completion scripts.
  public static var allCases: [CompletionShell] {
    [.zsh, .bash, .fish]
  }

  static let _requesting = Mutex<CompletionShell?>(nil)

  // swift-format-ignore: BeginDocumentationCommentWithOneLineSummary
  // https://github.com/swiftlang/swift-format/issues/924
  /// While generating a shell completion script or while a Swift custom
  /// completion function is executing to offer completions for a word from a
  /// command line (e.g., while `customCompletion` from
  /// `@Option(completion: .custom(customCompletion))` executes), an instance
  /// representing the shell for which completions will be or are being
  /// requested, respectively.
  ///
  /// Otherwise `nil`.
  public static var requesting: CompletionShell? {
    Self._requesting.withLock { $0 }
  }

  static let _requestingVersion = Mutex<String?>(nil)

  // swift-format-ignore: BeginDocumentationCommentWithOneLineSummary
  // https://github.com/swiftlang/swift-format/issues/924
  /// While a Swift custom completion function is executing to offer completions
  /// for a word from a command line (e.g., while `customCompletion` from
  /// `@Option(completion: .custom(customCompletion))` executes), a `String`
  /// representing the version of the shell for which completions are being
  /// requested.
  ///
  /// Otherwise `nil`.
  public static var requestingVersion: String? {
    Self._requestingVersion.withLock { $0 }
  }

  /// The name of the environment variable whose value is the name of the shell
  /// for which completions are being requested from a custom completion
  /// handler.
  ///
  /// The environment variable is set in generated completion scripts.
  static let shellEnvironmentVariableName = "SAP_SHELL"

  /// The name of the environment variable whose value is the version of the
  /// shell for which completions are being requested from a custom completion
  /// handler.
  ///
  /// The environment variable is set in generated completion scripts.
  static let shellVersionEnvironmentVariableName = "SAP_SHELL_VERSION"

  public func format(completions: [String]) -> String {
    var completions = completions
    if self == .zsh {
      completions.append("END_MARKER")
    }
    return completions.joined(separator: "\n")
  }
}

struct CompletionsGenerator {
  var shell: CompletionShell
  var command: ParsableCommand.Type

  init(command: ParsableCommand.Type, shell: CompletionShell?) throws {
    guard let _shell = shell ?? .autodetected() else {
      throw ParserError.unsupportedShell()
    }

    self.shell = _shell
    self.command = command
  }

  init(command: ParsableCommand.Type, shellName: String?) throws {
    if let shellName = shellName {
      guard let shell = CompletionShell(rawValue: shellName) else {
        throw ParserError.unsupportedShell(shellName)
      }
      try self.init(command: command, shell: shell)
    } else {
      try self.init(command: command, shell: nil)
    }
  }

  /// Generates a shell completion script for this generator's shell and command.
  func generateCompletionScript() -> String {
    CompletionShell._requesting.withLock { $0 = shell }
    switch shell {
    case .zsh:
      return ZshCompletionsGenerator.generateCompletionScript(command)
    case .bash:
      return BashCompletionsGenerator.generateCompletionScript(command)
    case .fish:
      return FishCompletionsGenerator.generateCompletionScript(command)
    default:
      fatalError("Invalid CompletionShell: \(shell)")
    }
  }
}

extension ArgumentDefinition {
  /// Returns a string with the arguments for the callback to generate custom completions for
  /// this argument.
  func customCompletionCall(_ commands: [ParsableCommand.Type]) -> String {
    let subcommandNames = commands.dropFirst().map { $0._commandName }.joined(
      separator: " ")
    let argumentName =
      names.preferredName?.synopsisString
      ?? self.help.keys.first?.fullPathString ?? "---"
    return "---completion \(subcommandNames) -- \(argumentName)"
  }
}

extension ParsableCommand {
  fileprivate static var compositeCommandName: [String] {
    if let superCommandName = configuration._superCommandName {
      return [superCommandName]
        + _commandName.split(separator: " ").map(String.init)
    } else {
      return _commandName.split(separator: " ").map(String.init)
    }
  }
}

extension Sequence where Element == ParsableCommand.Type {
  func completionFunctionName() -> String {
    "_"
      + self.flatMap { $0.compositeCommandName }
      .uniquingAdjacentElements()
      .joined(separator: "_")
  }
}
