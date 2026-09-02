//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020-2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import ArgumentParserTestHelpers
import Testing

@testable import ArgumentParser

private func candidates(prefix: String) -> [String] {
  switch CompletionShell.requesting {
  case CompletionShell.bash:
    return ["\(prefix)1_bash", "\(prefix)2_bash", "\(prefix)3_bash"]
  case CompletionShell.fish:
    return ["\(prefix)1_fish", "\(prefix)2_fish", "\(prefix)3_fish"]
  case CompletionShell.zsh:
    return ["\(prefix)1_zsh", "\(prefix)2_zsh", "\(prefix)3_zsh"]
  default:
    return []
  }
}

private func candidatesAsync(prefix: String) async -> [String] {
  candidates(prefix: prefix)
}

extension SerializedTests {
  struct CompletionScriptTests {}
}

// swift-format-ignore: AlwaysUseLowerCamelCase
extension SerializedTests.CompletionScriptTests {
  struct Path: ExpressibleByArgument {
    var path: String

    init?(argument: String) {
      self.path = argument
    }

    static var defaultCompletionKind: CompletionKind {
      .file()
    }
  }

  enum Kind:
    String,
    ExpressibleByArgument,
    EnumerableFlag,
    CustomStringConvertible
  {
    case one, two
    case three = "custom-three"
  }

  struct NestedArguments: ParsableArguments {
    @Argument(completion: .custom { _, _, _ in candidates(prefix: "a") })
    var nestedArgument: String
  }

  struct Base: ParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "base-test",
      subcommands: [SubCommand.self, HiddenChild.self, EscapedCommand.self])

    @Option(help: "The user's name.") var name: String
    @Option() var kind: Kind
    @Option(completion: .list(candidates(prefix: "b"))) var otherKind: Kind

    @Option() var path1: Path
    @Option() var path2: Path?
    @Option(completion: .list(candidates(prefix: "c"))) var path3: Path

    @Flag(help: .hidden) var verbose = false
    @Flag var allowedKinds: [Kind] = []
    @Flag var kindCounter: Int

    @Option() var rep1: [String]
    @Option(name: [.short, .long]) var rep2: [String]

    @Argument(completion: .custom { _, _, _ in candidates(prefix: "d") })
    var argument: String
    @OptionGroup var nested: NestedArguments

    struct SubCommand: ParsableCommand {
      static let configuration = CommandConfiguration(
        commandName: "sub-command")
    }

    struct HiddenChild: ParsableCommand {
      static let configuration = CommandConfiguration(shouldDisplay: false)
    }

    struct EscapedCommand: ParsableCommand {
      @Option(
        name: .customLong("o:n[e"),
        help: ArgumentHelp(
          #"Escaped chars: '[]\."#, valueName: "path[:options]"
        )
      )
      var one: String

      @Argument(completion: .custom { _, _, _ in candidates(prefix: "i") })
      var two: String
    }
  }

  @Test func base_Zsh() throws {
    let script1 = try CompletionsGenerator(command: Base.self, shell: .zsh)
      .generateCompletionScript()
    try expectSnapshot(actual: script1, extension: "zsh")

    let script2 = try CompletionsGenerator(command: Base.self, shellName: "zsh")
      .generateCompletionScript()
    try expectSnapshot(actual: script2, extension: "zsh")

    let script3 = Base.completionScript(for: .zsh)
    try expectSnapshot(actual: script3, extension: "zsh")
  }

  @Test func base_Bash() throws {
    let script1 = try CompletionsGenerator(command: Base.self, shell: .bash)
      .generateCompletionScript()
    try expectSnapshot(actual: script1, extension: "bash")

    let script2 = try CompletionsGenerator(
      command: Base.self, shellName: "bash"
    )
    .generateCompletionScript()
    try expectSnapshot(actual: script2, extension: "bash")

    let script3 = Base.completionScript(for: .bash)
    try expectSnapshot(actual: script3, extension: "bash")
  }

  @Test func base_Fish() throws {
    let script1 = try CompletionsGenerator(command: Base.self, shell: .fish)
      .generateCompletionScript()
    try expectSnapshot(actual: script1, extension: "fish")

    let script2 = try CompletionsGenerator(
      command: Base.self, shellName: "fish"
    )
    .generateCompletionScript()
    try expectSnapshot(actual: script2, extension: "fish")

    let script3 = Base.completionScript(for: .fish)
    try expectSnapshot(actual: script3, extension: "fish")
  }
}

extension SerializedTests.CompletionScriptTests {
  struct DefaultSubcommandRoot: ParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "default-completion",
      subcommands: [Default.self, Other.self],
      defaultSubcommand: Default.self)

    @Flag var rootFlag = false

    struct Default: ParsableCommand {
      @Option(completion: .list(["one", "two"]))
      var defaultOption: String

      @Option(completion: .custom { _, _, _ in [] })
      var customOption: String
    }

    struct Other: ParsableCommand {}
  }

  @Test func defaultSubcommandBashCompletions() throws {
    let script = try CompletionsGenerator(
      command: DefaultSubcommandRoot.self,
      shell: .bash
    ).generateCompletionScript()
    let childFunction = try #require(
      script.range(of: "_default-completion_default() {")
    )
    let rootFunction = script[..<childFunction.lowerBound]

    #expect(rootFunction.contains("--default-option"))
    #expect(
      rootFunction.contains("---completion default -- --custom-option"))
  }

  @Test func defaultSubcommandZshCompletions() throws {
    let script = try CompletionsGenerator(
      command: DefaultSubcommandRoot.self,
      shell: .zsh
    ).generateCompletionScript()
    let childFunction = try #require(
      script.range(of: "_default-completion_default() {")
    )
    let rootFunction = script[..<childFunction.lowerBound]

    #expect(rootFunction.contains("--default-option"))
    #expect(
      rootFunction.contains("---completion default -- --custom-option"))
  }

  @Test func defaultSubcommandFishCompletions() throws {
    let script = try CompletionsGenerator(
      command: DefaultSubcommandRoot.self,
      shell: .fish
    ).generateCompletionScript()

    #expect(
      script.contains(
        "flags_or_options \"default-completion\" default-option' -l 'default-option'"
      )
    )
    #expect(
      script.contains(
        "flags_or_options \"default-completion\" custom-option' -l 'custom-option' -rfka '(__default-completion_custom_completion ---completion default -- --custom-option"
      )
    )
  }

  struct Custom: ParsableCommand {
    @Option(
      name: .shortAndLong,
      completion: .custom { _, _, _ in candidates(prefix: "e") }
    )
    var one: String

    @Argument(completion: .custom { _, _, _ in candidates(prefix: "f") })
    var two: String

    @Option(
      name: .customShort("z"),
      completion: .custom { _, _, _ in candidates(prefix: "g") }
    )
    var three: String

    @OptionGroup var nested: NestedArguments

    struct NestedArguments: ParsableArguments {
      @Argument(completion: .custom { _, _, _ in candidates(prefix: "h") })
      var four: String
    }
  }

  struct CustomAsync: AsyncParsableCommand {
    @Argument(
      completion: .custom { _, _, _ in await candidatesAsync(prefix: "j") }
    )
    var five: String
  }

  func expectCustomCompletion(
    _ arg: String,
    shell: CompletionShell,
    prefix: String = "",
    sourceLocation: SourceLocation = #_sourceLocation,
    command: any ParsableCommand.Type = Custom.self
  ) async throws {
    #if !os(Windows) && !os(WASI)
    do {
      Platform.Environment[.shellName, as: CompletionShell.self] = shell
      defer { Platform.Environment[.shellName] = nil }
      if let command = command as? AsyncParsableCommand.Type {
        _ = try await command.asyncParse(["---completion", "--", arg, "0", "0"])
      } else {
        _ = try command.parse(["---completion", "--", arg, "0", "0"])
      }
      Issue.record("Didn't error as expected", sourceLocation: sourceLocation)
    } catch let error as CommandError {
      guard case .completionScriptCustomResponse(let output) = error.parserError
      else {
        throw error
      }
      expectEqualStrings(
        actual: output,
        expected: shell.format(completions: [
          "\(prefix)1_\(shell.rawValue)",
          "\(prefix)2_\(shell.rawValue)",
          "\(prefix)3_\(shell.rawValue)",
        ]),
        sourceLocation: sourceLocation)
    }
    #endif
  }

  func expectCustomCompletions(
    shell: CompletionShell,
    sourceLocation: SourceLocation = #_sourceLocation
  ) async throws {
    #if !os(Windows) && !os(WASI)
    try await expectCustomCompletion(
      "-o", shell: shell, prefix: "e", sourceLocation: sourceLocation)
    try await expectCustomCompletion(
      "--one", shell: shell, prefix: "e", sourceLocation: sourceLocation)
    try await expectCustomCompletion(
      "two", shell: shell, prefix: "f", sourceLocation: sourceLocation)
    try await expectCustomCompletion(
      "-z", shell: shell, prefix: "g", sourceLocation: sourceLocation)
    try await expectCustomCompletion(
      "nested.four", shell: shell, prefix: "h", sourceLocation: sourceLocation)
    try await expectCustomCompletion(
      "five", shell: shell, prefix: "j", sourceLocation: sourceLocation,
      command: CustomAsync.self
    )

    do {
      try await expectCustomCompletion(
        "--bad",
        shell: shell,
        sourceLocation: sourceLocation
      )
      Issue.record("Didn't error as expected", sourceLocation: sourceLocation)
    } catch {
      // Expected
    }
    do {
      try await expectCustomCompletion(
        "four",
        shell: shell,
        sourceLocation: sourceLocation
      )
      Issue.record("Didn't error as expected", sourceLocation: sourceLocation)
    } catch {
      // Expected
    }
    #endif
  }

  @Test func bashCustomCompletions() async throws {
    try await expectCustomCompletions(shell: .bash)
  }

  @Test func fishCustomCompletions() async throws {
    try await expectCustomCompletions(shell: .fish)
  }

  @Test func zshCustomCompletions() async throws {
    try await expectCustomCompletions(shell: .zsh)
  }
}
