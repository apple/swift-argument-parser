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
import ArgumentParserToolInfo
import Testing

@testable import ArgumentParser

@Suite struct DefaultSubcommandEndToEndTests {}

// MARK: -

private struct Main: ParsableCommand {
  static let configuration = CommandConfiguration(
    subcommands: [Default.self, Foo.self, Bar.self],
    defaultSubcommand: Default.self
  )
}

private struct Default: ParsableCommand {
  enum Mode: String, CaseIterable, ExpressibleByArgument {
    case foo, bar, baz
  }

  @Option var mode: Mode = .foo
}

private struct Foo: ParsableCommand {}
private struct Bar: ParsableCommand {}

extension DefaultSubcommandEndToEndTests {
  @Test func defaultSubcommand() {
    expectParseCommand(Main.self, Default.self, []) { def in
      #expect(def.mode == .foo)
    }

    expectParseCommand(Main.self, Default.self, ["--mode=bar"]) { def in
      #expect(def.mode == .bar)
    }

    expectParseCommand(Main.self, Default.self, ["--mode", "bar"]) { def in
      #expect(def.mode == .bar)
    }

    expectParseCommand(Main.self, Default.self, ["--mode", "baz"]) { def in
      #expect(def.mode == .baz)
    }
  }

  @Test func nonDefaultSubcommand() {
    expectParseCommand(Main.self, Foo.self, ["foo"]) { _ in }
    expectParseCommand(Main.self, Bar.self, ["bar"]) { _ in }

    expectParseCommand(Main.self, Default.self, ["default", "--mode", "bar"]) {
      def in
      #expect(def.mode == .bar)
    }
  }

  @Test func parsingFailure() {
    #expect(throws: (any Error).self) {
      try Main.parseAsRoot(["--mode", "qux"])
    }
    #expect(throws: (any Error).self) { try Main.parseAsRoot(["qux"]) }
  }
}

extension DefaultSubcommandEndToEndTests {
  fileprivate struct MyCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
      subcommands: [
        Plugin.self, NonDefault.self, Other.self, Child.self, BadParent.self,
      ],
      defaultSubcommand: Plugin.self
    )

    @Option var foo: String?

    @OptionGroup
    var options: CommonOptions
  }

  fileprivate struct CommonOptions: ParsableArguments {
    @Flag(
      name: [.customLong("verbose"), .customShort("v")],
      help: "Enable verbose aoutput.")
    var verbose = false
  }

  fileprivate struct Plugin: ParsableCommand {
    @OptionGroup var options: CommonOptions
    @Argument var pluginName: String

    @Argument(parsing: .captureForPassthrough)
    var pluginArguments: [String] = []
  }

  fileprivate struct NonDefault: ParsableCommand {
    @OptionGroup var options: CommonOptions
    @Argument var pluginName: String

    @Argument(parsing: .captureForPassthrough)
    var pluginArguments: [String] = []
  }

  fileprivate struct Other: ParsableCommand {
    @OptionGroup var options: CommonOptions
  }

  fileprivate struct Child: ParsableCommand {
    @ParentCommand var parent: MyCommand
  }

  fileprivate struct BadParent: ParsableCommand {
    @ParentCommand var notMyParent: Other
  }

  @Test func accessToParent() throws {
    expectParseCommand(
      MyCommand.self, Child.self, ["--verbose", "--foo=bar", "child"]
    ) { child in
      #expect(child.parent.foo == "bar")
      #expect(child.parent.options.verbose == true)
    }
  }

  @Test func notMyParent() {
    // migrate to `#expect(throws:expression)`
    #expect {
      _ = try MyCommand.parseAsRoot(["--verbose", "bad-parent"])
    } throws: { error in
      let message = MyCommand.message(for: error)
      return message
        == "Command 'Other' is not a parent of the current command."
    }
    // do {
    //   _ = try MyCommand.parseAsRoot(["--verbose", "bad-parent"])
    //   Issue.record("Parsing should have failed.")
    // } catch {
    //   let message = MyCommand.message(for: error)
    //   #expect(
    //     message == "Command 'Other' is not a parent of the current command.")
    // }
  }

  @Test func notLeakingParentOptions() throws {
    // Verify that the help for the child command doesn't leak the parent command's options in the help
    let childHelp = MyCommand.message(for: CleanExit.helpRequest(Child.self))
    #expect(
      childHelp == """
        USAGE: my-command child

        OPTIONS:
          -h, --help              Show help information.

        """)

    // Now check that the foo option doesn't leak into the JSON dump
    let toolInfo = ToolInfoV0(commandStack: [MyCommand.self.asCommand])

    let arguments = try #require(
      toolInfo.command.arguments,
      "MyCommand is expected to have a top-level command arguments in its tool info"
    )

    let subcommands = try #require(
      toolInfo.command.subcommands,
      "MyCommand is expected to have a top-level command arguments in its tool info"
    )

    // The foo option is present int he parent
    #expect(arguments.first { $0.valueName == "foo" } != nil)

    let childInfo = try #require(
      subcommands.first { cmd in
        cmd.commandName == "child"
      },
      "The child subcommand is expected to be present in the tool info")

    let childArguments = try #require(
      childInfo.arguments,
      "The child subcommand is expected to have arguments in the tool info")

    // It's not there in the child subcommand
    #expect(childArguments.first { $0.valueName == "foo" } == nil)
  }

  @Test func remainingDefaultImplicit() throws {
    expectParseCommand(MyCommand.self, Plugin.self, ["my-plugin"]) { plugin in
      #expect(plugin.pluginName == "my-plugin")
      #expect(plugin.pluginArguments == [])
      #expect(plugin.options.verbose == false)
    }
    expectParseCommand(MyCommand.self, Plugin.self, ["my-plugin", "--verbose"])
    { plugin in
      #expect(plugin.pluginName == "my-plugin")
      #expect(plugin.pluginArguments == ["--verbose"])
      #expect(plugin.options.verbose == false)
    }
    expectParseCommand(
      MyCommand.self, Plugin.self, ["--verbose", "my-plugin", "--verbose"]
    ) { plugin in
      #expect(plugin.pluginName == "my-plugin")
      #expect(plugin.pluginArguments == ["--verbose"])
      #expect(plugin.options.verbose == true)
    }
    expectParseCommand(MyCommand.self, Plugin.self, ["my-plugin", "--help"]) {
      plugin in
      #expect(plugin.pluginName == "my-plugin")
      #expect(plugin.pluginArguments == ["--help"])
      #expect(plugin.options.verbose == false)
    }
  }

  @Test func remainingDefaultExplicit() throws {
    expectParseCommand(MyCommand.self, Plugin.self, ["plugin", "my-plugin"]) {
      plugin in
      #expect(plugin.pluginName == "my-plugin")
      #expect(plugin.pluginArguments == [])
      #expect(plugin.options.verbose == false)
    }
    expectParseCommand(
      MyCommand.self, Plugin.self, ["plugin", "my-plugin", "--verbose"]
    ) { plugin in
      #expect(plugin.pluginName == "my-plugin")
      #expect(plugin.pluginArguments == ["--verbose"])
      #expect(plugin.options.verbose == false)
    }
    expectParseCommand(
      MyCommand.self, Plugin.self,
      ["--verbose", "plugin", "my-plugin", "--verbose"]
    ) { plugin in
      #expect(plugin.pluginName == "my-plugin")
      #expect(plugin.pluginArguments == ["--verbose"])
      #expect(plugin.options.verbose == true)
    }
    expectParseCommand(
      MyCommand.self, Plugin.self,
      ["--verbose", "plugin", "my-plugin", "--help"]
    ) { plugin in
      #expect(plugin.pluginName == "my-plugin")
      #expect(plugin.pluginArguments == ["--help"])
      #expect(plugin.options.verbose == true)
    }
  }

  @Test func remainingNonDefault() throws {
    expectParseCommand(
      MyCommand.self, NonDefault.self, ["non-default", "my-plugin"]
    ) { nondef in
      #expect(nondef.pluginName == "my-plugin")
      #expect(nondef.pluginArguments == [])
      #expect(nondef.options.verbose == false)
    }
    expectParseCommand(
      MyCommand.self, NonDefault.self,
      ["non-default", "my-plugin", "--verbose"]
    ) { nondef in
      #expect(nondef.pluginName == "my-plugin")
      #expect(nondef.pluginArguments == ["--verbose"])
      #expect(nondef.options.verbose == false)
    }
    expectParseCommand(
      MyCommand.self, NonDefault.self,
      ["--verbose", "non-default", "my-plugin", "--verbose"]
    ) { nondef in
      #expect(nondef.pluginName == "my-plugin")
      #expect(nondef.pluginArguments == ["--verbose"])
      #expect(nondef.options.verbose == true)
    }
    expectParseCommand(
      MyCommand.self, NonDefault.self,
      ["--verbose", "non-default", "my-plugin", "--help"]
    ) { nondef in
      #expect(nondef.pluginName == "my-plugin")
      #expect(nondef.pluginArguments == ["--help"])
      #expect(nondef.options.verbose == true)
    }
  }

  @Test func remainingDefaultOther() throws {
    expectParseCommand(MyCommand.self, Other.self, ["other"]) { other in
      #expect(other.options.verbose == false)
    }
    expectParseCommand(MyCommand.self, Other.self, ["other", "--verbose"]) {
      other in
      #expect(other.options.verbose == true)
    }
  }

  @Test func remainingDefaultFailure() {
    #expect(throws: (any Error).self) { try MyCommand.parseAsRoot([]) }
    #expect(throws: (any Error).self) {
      try MyCommand.parseAsRoot(["--verbose"])
    }
    #expect(throws: (any Error).self) {
      try MyCommand.parseAsRoot(["plugin", "--verbose", "my-plugin"])
    }
  }
}

extension DefaultSubcommandEndToEndTests {
  struct RootWithPassthroughDefault: ParsableCommand {
    static let configuration = CommandConfiguration(
      subcommands: [PassthroughDefault.self],
      defaultSubcommand: PassthroughDefault.self,
      helpNames: [.short, .long, .customLong("help", withSingleDash: true)]
    )
  }

  struct PassthroughDefault: ParsableCommand {
    @Argument(parsing: .captureForPassthrough)
    var remaining: [String] = []
  }

  // Test fix for https://github.com/apple/swift-package-manager/issues/7218
  @Test func helpWithPassthroughDefault() throws {
    expectParseCommand(
      RootWithPassthroughDefault.self, HelpCommand.self, ["-h"]
    ) { _ in }
    expectParseCommand(
      RootWithPassthroughDefault.self, HelpCommand.self, ["-help"]
    ) { _ in }
    expectParseCommand(
      RootWithPassthroughDefault.self, HelpCommand.self, ["--help"]
    ) { _ in }
  }
}

extension DefaultSubcommandEndToEndTests {
  struct NestedDefaultSubcommandHelp: ParsableCommand {
    static let configuration = CommandConfiguration(
      subcommands: [Default.self, Nested.self],
      defaultSubcommand: Default.self
    )

    struct Default: ParsableCommand {}

    struct Nested: ParsableCommand {
      static let configuration = CommandConfiguration(
        commandName: "nested",
        subcommands: [NestedDefault.self, NestedOther.self],
        defaultSubcommand: NestedDefault.self
      )
    }

    struct NestedDefault: ParsableCommand {}
    struct NestedOther: ParsableCommand {}
  }

  // Test fix for https://github.com/apple/swift-argument-parser/issues/865
  @Test func helpWithNestedDefaultSubcommand() throws {
    expectParseCommand(
      NestedDefaultSubcommandHelp.self, HelpCommand.self, ["--help"]
    ) { command in
      #expect(command.commandStack.count == 1)
      #expect(
        type(of: command.commandStack[0])
          == NestedDefaultSubcommandHelp.Type.self)
    }

    expectParseCommand(
      NestedDefaultSubcommandHelp.self, HelpCommand.self, ["nested", "--help"]
    ) { command in
      #expect(command.commandStack.count == 2)
      #expect(
        type(of: command.commandStack[0])
          == NestedDefaultSubcommandHelp.Type.self)
      #expect(
        type(of: command.commandStack[1])
          == NestedDefaultSubcommandHelp.Nested.Type.self)
    }
  }
}
