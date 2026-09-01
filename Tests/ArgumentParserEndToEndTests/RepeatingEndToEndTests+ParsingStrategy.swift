//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2022-2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import ArgumentParserTestHelpers
import Testing

@testable import ArgumentParser

// MARK: - allUnrecognized

private struct AllUnrecognizedArgs: ParsableCommand {
  static var configuration: CommandConfiguration {
    .init(version: "1.0")
  }

  @Flag var verbose: Bool = false
  @Flag(name: .customShort("f")) var useFiles: Bool = false
  @Flag(name: .customShort("i")) var useStandardInput: Bool = false
  @Flag(name: .customShort("h")) var hoopla: Bool = false
  @Option var config = "debug"
  @Argument(parsing: .allUnrecognized) var names: [String] = []
}

// swift-format-ignore: AlwaysUseLowerCamelCase
// https://github.com/apple/swift-argument-parser/issues/710
extension RepeatingEndToEndTests {
  @Test func parsing_repeatingAllUnrecognized() throws {
    expectParse(AllUnrecognizedArgs.self, []) { cmd in
      #expect(cmd.verbose == false)
      #expect(cmd.hoopla == false)
      #expect(cmd.names == [])
    }
    expectParse(
      AllUnrecognizedArgs.self,
      ["foo", "--verbose", "-fi", "bar", "-z", "--other"]
    ) { cmd in
      #expect(cmd.verbose)
      #expect(cmd.useFiles)
      #expect(cmd.useStandardInput)
      #expect(cmd.hoopla == false)
      #expect(cmd.names == ["foo", "bar", "-z", "--other"])
    }
  }

  @Test func parsing_repeatingAllUnrecognized_Builtin() throws {
    expectParse(
      AllUnrecognizedArgs.self, ["foo", "--verbose", "bar", "-z", "-h"]
    ) { cmd in
      #expect(cmd.verbose)
      #expect(cmd.useFiles == false)
      #expect(cmd.useStandardInput == false)
      #expect(cmd.hoopla)
      #expect(cmd.names == ["foo", "bar", "-z"])
    }

    expectParseCommand(
      AllUnrecognizedArgs.self, HelpCommand.self,
      ["foo", "--verbose", "bar", "-z", "--help"]
    ) { cmd in
      // No need to test HelpCommand properties
    }
    #expect(throws: (any Error).self) {
      try AllUnrecognizedArgs.parse(["foo", "--verbose", "--version"])
    }
  }

  @Test func parsing_repeatingAllUnrecognized_Fails() throws {
    // Only partially matches the `-fib` argument
    #expect(throws: (any Error).self) { try PassthroughArgs.parse(["-fib"]) }
  }
}

private struct AllUnrecognizedRoot: ParsableCommand {
  static var configuration: CommandConfiguration {
    .init(subcommands: [Child.self])
  }

  @Flag var verbose: Bool = false

  struct Child: ParsableCommand {
    @Flag var includeExtras: Bool = false
    @Option var config = "debug"
    @Argument(parsing: .allUnrecognized) var extras: [String] = []
    @OptionGroup var root: AllUnrecognizedRoot
  }
}

// swift-format-ignore: AlwaysUseLowerCamelCase
// https://github.com/apple/swift-argument-parser/issues/710
extension RepeatingEndToEndTests {
  @Test func parsing_repeatingAllUnrecognized_Nested() throws {
    expectParseCommand(
      AllUnrecognizedRoot.self, AllUnrecognizedRoot.Child.self,
      ["child"]
    ) { cmd in
      #expect(cmd.root.verbose == false)
      #expect(cmd.includeExtras == false)
      #expect(cmd.config == "debug")
      #expect(cmd.extras == [])
    }
    expectParseCommand(
      AllUnrecognizedRoot.self, AllUnrecognizedRoot.Child.self,
      ["child", "--verbose", "--other", "one", "two", "--config", "prod"]
    ) { cmd in
      #expect(cmd.root.verbose)
      #expect(cmd.includeExtras == false)
      #expect(cmd.config == "prod")
      #expect(cmd.extras == ["--other", "one", "two"])
    }
  }

  @Test func parsing_repeatingAllUnrecognized_Nested_Fails() throws {
    // Extra arguments need to make it to the child
    #expect(throws: (any Error).self) {
      try AllUnrecognizedRoot.parse(["--verbose", "--other"])
    }
  }
}

// MARK: - postTerminator

private struct PostTerminatorArgs: ParsableArguments {
  @Flag(name: .customShort("f")) var useFiles: Bool = false
  @Flag(name: .customShort("i")) var useStandardInput: Bool = false
  @Option var config = "debug"
  @Argument var title: String?
  @Argument(parsing: .postTerminator)
  var names: [String] = []
}

// swift-format-ignore: AlwaysUseLowerCamelCase
// https://github.com/apple/swift-argument-parser/issues/710
extension RepeatingEndToEndTests {
  @Test func parsing_repeatingPostTerminator() throws {
    expectParse(PostTerminatorArgs.self, []) { cmd in
      #expect(cmd.title == nil)
      #expect(cmd.names == [])
    }
    expectParse(PostTerminatorArgs.self, ["--", "-fi"]) { cmd in
      #expect(cmd.title == nil)
      #expect(cmd.names == ["-fi"])
    }
    expectParse(PostTerminatorArgs.self, ["-fi", "--", "-fi", "--"]) { cmd in
      #expect(cmd.useFiles)
      #expect(cmd.useStandardInput)
      #expect(cmd.title == nil)
      #expect(cmd.names == ["-fi", "--"])
    }
    expectParse(PostTerminatorArgs.self, ["-fi", "title", "--", "title"]) {
      cmd in
      #expect(cmd.useFiles)
      #expect(cmd.useStandardInput)
      #expect(cmd.title == "title")
      #expect(cmd.names == ["title"])
    }
    expectParse(
      PostTerminatorArgs.self, ["--config", "config", "--", "--config", "post"]
    ) { cmd in
      #expect(cmd.config == "config")
      #expect(cmd.title == nil)
      #expect(cmd.names == ["--config", "post"])
    }
  }

  @Test func parsing_repeatingPostTerminator_Fails() throws {
    // Only partially matches the `-fib` argument
    #expect(throws: (any Error).self) {
      try PostTerminatorArgs.parse(["-fib"])
    }
    // The post-terminator input can't provide the option's value
    #expect(throws: (any Error).self) {
      try PostTerminatorArgs.parse(["--config", "--", "config"])
    }
  }
}

// MARK: - captureForPassthrough

private struct PassthroughArgs: ParsableCommand {
  @Flag var verbose: Bool = false
  @Flag(name: .customShort("f")) var useFiles: Bool = false
  @Flag(name: .customShort("i")) var useStandardInput: Bool = false
  @Option var config = "debug"
  @Argument(parsing: .captureForPassthrough) var names: [String] = []
}

// swift-format-ignore: AlwaysUseLowerCamelCase
// https://github.com/apple/swift-argument-parser/issues/710
extension RepeatingEndToEndTests {
  @Test func parsing_repeatingCaptureForPassthrough() throws {
    expectParse(PassthroughArgs.self, []) { cmd in
      #expect(cmd.verbose == false)
      #expect(cmd.names == [])
    }

    expectParse(PassthroughArgs.self, ["--other"]) { cmd in
      #expect(cmd.verbose == false)
      #expect(cmd.names == ["--other"])
    }

    expectParse(PassthroughArgs.self, ["--verbose", "one", "two", "three"]) {
      cmd in
      #expect(cmd.verbose)
      #expect(cmd.names == ["one", "two", "three"])
    }

    expectParse(
      PassthroughArgs.self, ["one", "two", "three", "--other", "--verbose"]
    ) { cmd in
      #expect(cmd.verbose == false)
      #expect(cmd.names == ["one", "two", "three", "--other", "--verbose"])
    }

    expectParse(
      PassthroughArgs.self, ["--verbose", "--other", "one", "two", "three"]
    ) { cmd in
      #expect(cmd.verbose)
      #expect(cmd.names == ["--other", "one", "two", "three"])
    }

    expectParse(
      PassthroughArgs.self,
      ["--verbose", "--other", "one", "--", "two", "three"]
    ) { cmd in
      #expect(cmd.verbose)
      #expect(cmd.names == ["--other", "one", "--", "two", "three"])
    }

    expectParse(
      PassthroughArgs.self,
      ["--other", "one", "--", "two", "three", "--verbose"]
    ) { cmd in
      #expect(cmd.verbose == false)
      #expect(
        cmd.names == ["--other", "one", "--", "two", "three", "--verbose"])
    }

    expectParse(
      PassthroughArgs.self,
      ["--", "--verbose", "--other", "one", "two", "three"]
    ) { cmd in
      #expect(cmd.verbose == false)
      #expect(
        cmd.names == ["--", "--verbose", "--other", "one", "two", "three"])
    }

    expectParse(PassthroughArgs.self, ["-one", "-two", "three"]) { cmd in
      #expect(cmd.verbose == false)
      #expect(cmd.useFiles == false)
      #expect(cmd.useStandardInput == false)
      #expect(cmd.names == ["-one", "-two", "three"])
    }

    expectParse(
      PassthroughArgs.self,
      ["--config", "release", "one", "two", "--config", "debug"]
    ) { cmd in
      #expect(cmd.config == "release")
      #expect(cmd.names == ["one", "two", "--config", "debug"])
    }

    expectParse(
      PassthroughArgs.self,
      ["--config", "release", "--config", "debug", "one", "two"]
    ) { cmd in
      #expect(cmd.config == "debug")
      #expect(cmd.names == ["one", "two"])
    }

    expectParse(PassthroughArgs.self, ["-if", "-one", "-two", "three"]) { cmd in
      #expect(cmd.verbose == false)
      #expect(cmd.useFiles)
      #expect(cmd.useStandardInput)
      #expect(cmd.names == ["-one", "-two", "three"])
    }

    expectParse(PassthroughArgs.self, ["-one", "-two", "-three", "-if"]) {
      cmd in
      #expect(cmd.verbose == false)
      #expect(cmd.useFiles == false)
      #expect(cmd.useStandardInput == false)
      #expect(cmd.names == ["-one", "-two", "-three", "-if"])
    }

    expectParse(
      PassthroughArgs.self, ["-one", "-two", "-three", "-if", "--help"]
    ) { cmd in
      #expect(cmd.verbose == false)
      #expect(cmd.useFiles == false)
      #expect(cmd.useStandardInput == false)
      #expect(cmd.names == ["-one", "-two", "-three", "-if", "--help"])
    }

    expectParse(PassthroughArgs.self, ["-one", "-two", "-three", "-if", "-h"]) {
      cmd in
      #expect(cmd.verbose == false)
      #expect(cmd.useFiles == false)
      #expect(cmd.useStandardInput == false)
      #expect(cmd.names == ["-one", "-two", "-three", "-if", "-h"])
    }
  }

  @Test func parsing_repeatingCaptureForPassthrough_Fails() throws {
    // Only partially matches the `-fib` argument
    #expect(throws: (any Error).self) { try PassthroughArgs.parse(["-fib"]) }
  }
}
