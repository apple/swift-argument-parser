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

@Suite struct ShortNameEndToEndTests {}

// MARK: -

private struct Bar: ParsableArguments {
  @Flag(name: [.long, .short])
  var verbose: Bool = false

  @Option(name: [.long, .short])
  var file: String?

  @Argument()
  var name: String
}

// swift-format-ignore: AlwaysUseLowerCamelCase
extension ShortNameEndToEndTests {
  @Test func parsing_withLongNames() throws {
    expectParse(Bar.self, ["foo"]) { options in
      #expect(options.verbose == false)
      #expect(options.file == nil)
      #expect(options.name == "foo")
    }

    expectParse(Bar.self, ["--verbose", "--file", "myfile", "foo"]) { options in
      #expect(options.verbose == true)
      #expect(options.file == "myfile")
      #expect(options.name == "foo")
    }
  }

  @Test func parsing_simple() throws {
    expectParse(Bar.self, ["-v", "foo"]) { options in
      #expect(options.verbose == true)
      #expect(options.file == nil)
      #expect(options.name == "foo")
    }

    expectParse(Bar.self, ["-f", "myfile", "foo"]) { options in
      #expect(options.verbose == false)
      #expect(options.file == "myfile")
      #expect(options.name == "foo")
    }

    expectParse(Bar.self, ["-v", "-f", "myfile", "foo"]) { options in
      #expect(options.verbose == true)
      #expect(options.file == "myfile")
      #expect(options.name == "foo")
    }
  }

  @Test func parsing_combined() throws {
    expectParse(Bar.self, ["-vf", "myfile", "foo"]) { options in
      #expect(options.verbose == true)
      #expect(options.file == "myfile")
      #expect(options.name == "foo")
    }

    expectParse(Bar.self, ["-fv", "myfile", "foo"]) { options in
      #expect(options.verbose == true)
      #expect(options.file == "myfile")
      #expect(options.name == "foo")
    }

    expectParse(Bar.self, ["foo", "-fv", "myfile"]) { options in
      #expect(options.verbose == true)
      #expect(options.file == "myfile")
      #expect(options.name == "foo")
    }
  }
}

// MARK: -

private struct Foo: ParsableArguments {
  @Option(name: [.long, .short])
  var name: String

  @Option(name: [.long, .short])
  var file: String

  @Option(name: [.long, .short])
  var city: String
}

// swift-format-ignore: AlwaysUseLowerCamelCase
extension ShortNameEndToEndTests {
  @Test func parsing_combinedShortNames() throws {
    expectParse(Foo.self, ["-nfc", "name", "file", "city"]) { options in
      #expect(options.name == "name")
      #expect(options.file == "file")
      #expect(options.city == "city")
    }

    expectParse(Foo.self, ["-ncf", "name", "city", "file"]) { options in
      #expect(options.name == "name")
      #expect(options.file == "file")
      #expect(options.city == "city")
    }

    expectParse(Foo.self, ["-fnc", "file", "name", "city"]) { options in
      #expect(options.name == "name")
      #expect(options.file == "file")
      #expect(options.city == "city")
    }

    expectParse(Foo.self, ["-fcn", "file", "city", "name"]) { options in
      #expect(options.name == "name")
      #expect(options.file == "file")
      #expect(options.city == "city")
    }

    expectParse(Foo.self, ["-cnf", "city", "name", "file"]) { options in
      #expect(options.name == "name")
      #expect(options.file == "file")
      #expect(options.city == "city")
    }

    expectParse(Foo.self, ["-cfn", "city", "file", "name"]) { options in
      #expect(options.name == "name")
      #expect(options.file == "file")
      #expect(options.city == "city")
    }
  }
}

// MARK: - Built-in help names inside short option packs

private struct PackedHelp: ParsableCommand {
  @Flag(name: .short) var verbose = false
  @Option(name: .short) var output: String?
  @Argument var input: String
}

private struct PackedCustomHelp: ParsableCommand {
  static let configuration = CommandConfiguration(
    helpNames: [.customShort("?")])

  @Flag(name: .short) var verbose = false
}

private struct PackedValidatedHelp: ParsableCommand {
  @Flag(name: .short) var verbose = false

  func validate() throws {
    throw ValidationError("Always invalid.")
  }
}

private struct PackedHelpRoot: ParsableCommand {
  static let configuration = CommandConfiguration(
    subcommands: [Child.self], defaultSubcommand: Child.self)

  struct Child: ParsableCommand {
    @Flag(name: .short) var verbose = false
  }
}

// swift-format-ignore: AlwaysUseLowerCamelCase
extension ShortNameEndToEndTests {
  @Test func packContainingHelpName_withUnknownName_isUnknownOption() throws {
    // Each of these contains an `h`, but none of them asks for help.
    expectErrorMessage(
      PackedHelp.self, ["-path", "input"], "Unknown option '-path'")
    expectErrorMessage(
      PackedHelp.self, ["-hey", "input"], "Unknown option '-hey'")
    expectErrorMessage(
      PackedHelp.self, ["-vzh", "input"], "Unknown option '-z'")

    // Without a value for `<input>` the missing argument is reported, just as
    // it is for the same input without an `h`.
    expectErrorMessage(
      PackedHelp.self, ["- [a](https://b)"],
      "Missing expected argument '<input>'")
    expectErrorMessage(
      PackedHelp.self, ["- [a](ftp://b)"],
      "Missing expected argument '<input>'")

    expectErrorMessage(
      PackedCustomHelp.self, ["-z?"], "Unknown option '-z?'")
  }

  @Test func packContainingHelpName_withUnknownName_defaultSubcommand() throws {
    expectErrorMessage(
      PackedHelpRoot.self, ["-path"], "Unknown option '-path'")
    expectErrorMessage(
      PackedHelpRoot.self, ["child", "-path"], "Unknown option '-path'")
  }

  @Test func helpName_alone_requestsHelp() throws {
    for arguments in [["-h"], ["--help"], ["-help"], ["input", "-h"]] {
      expectParseCommand(PackedHelp.self, HelpCommand.self, arguments) { _ in }
    }
    expectParseCommand(PackedCustomHelp.self, HelpCommand.self, ["-?"]) { _ in }
  }

  @Test func packContainingHelpName_withKnownNames_requestsHelp() throws {
    // `<input>` is missing here, so these are reached through the check that
    // runs after decoding fails, when `-v` hasn't been removed from the input.
    expectParseCommand(PackedHelp.self, HelpCommand.self, ["-vh"]) { _ in }
    expectParseCommand(PackedHelp.self, HelpCommand.self, ["-hv"]) { _ in }
    expectParseCommand(PackedHelp.self, HelpCommand.self, ["-hh"]) { _ in }

    // With decoding successful, `-v` has been consumed by this point.
    expectParseCommand(
      PackedHelp.self, HelpCommand.self, ["-vh", "input"]
    ) { _ in }
    expectParseCommand(
      PackedHelp.self, HelpCommand.self, ["-ho", "file", "input"]
    ) { _ in }

    expectParseCommand(
      PackedCustomHelp.self, HelpCommand.self, ["-v?"]
    ) { _ in }
    expectParseCommand(
      PackedValidatedHelp.self, HelpCommand.self, ["-vh"]
    ) { _ in }

    // `-v` belongs to the default subcommand, not to the root.
    expectParseCommand(PackedHelpRoot.self, HelpCommand.self, ["-vh"]) { _ in }
    expectParseCommand(
      PackedHelpRoot.self, HelpCommand.self, ["child", "-vh"]
    ) { _ in }
  }

  @Test func helpNameAsValue_isNotHelp() throws {
    expectParse(PackedHelp.self, ["--", "-path"]) { options in
      #expect(options.input == "-path")
    }
    expectParse(PackedHelp.self, ["-o=-path", "input"]) { options in
      #expect(options.output == "-path")
    }
  }
}
