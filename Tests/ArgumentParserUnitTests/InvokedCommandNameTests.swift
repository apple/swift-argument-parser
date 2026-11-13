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

import Testing

@testable import ArgumentParser

@Suite struct InvokedCommandNameTests {}

// MARK: - _executableName(fromInvokedPath:)

extension InvokedCommandNameTests {
  @Test func plainName() {
    #expect(_executableName(fromInvokedPath: "tool") == "tool")
  }

  @Test func unixAbsolutePath() {
    #expect(
      _executableName(fromInvokedPath: "/usr/local/bin/tool") == "tool")
  }

  @Test func unixRelativePath() {
    #expect(_executableName(fromInvokedPath: "./build/tool") == "tool")
  }

  @Test func windowsBackslashPath() {
    #if os(Windows)
      #expect(_executableName(fromInvokedPath: #"C:\tools\tool.exe"#) == "tool")
    #else
      // The `.exe`-stripping only applies on Windows; the backslash is still
      // treated as a path separator everywhere, since a `CommandLine.arguments[0]`
      // value can be copied from a Windows shell regardless of host platform.
      #expect(
        _executableName(fromInvokedPath: #"C:\tools\tool.exe"#) == "tool.exe")
    #endif
  }

  @Test func emptyPath() {
    #expect(_executableName(fromInvokedPath: "") == nil)
  }

  @Test func trailingSeparator() {
    #expect(_executableName(fromInvokedPath: "/usr/local/bin/") == nil)
  }
}

// MARK: - Array<ParsableCommand.Type>.invocationCommandNames

extension InvokedCommandNameTests {
  struct Named: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "explicit-name")
  }
  struct Unnamed: ParsableCommand {
    static let configuration = CommandConfiguration(subcommands: [Sub.self])
    struct Sub: ParsableCommand {}
  }

  @Test func substitutesWhenUnset() {
    #expect(
      [Unnamed.self].invocationCommandNames(invokedAs: "my-tool")
        == ["my-tool"])
  }

  @Test func doesNotSubstituteWhenExplicitlyNamed() {
    #expect(
      [Named.self].invocationCommandNames(invokedAs: "my-tool")
        == ["explicit-name"])
  }

  @Test func doesNotSubstituteWhenInvokedNameIsNil() {
    #expect(
      [Unnamed.self].invocationCommandNames(invokedAs: nil) == ["unnamed"])
  }

  @Test func doesNotSubstituteWhenInvokedNameIsEmpty() {
    #expect(
      [Unnamed.self].invocationCommandNames(invokedAs: "") == ["unnamed"])
  }

  @Test func onlySubstitutesRootInSubcommandStack() {
    #expect(
      [Unnamed.self, Unnamed.Sub.self]
        .invocationCommandNames(invokedAs: "my-tool") == ["my-tool", "sub"])
  }
}
