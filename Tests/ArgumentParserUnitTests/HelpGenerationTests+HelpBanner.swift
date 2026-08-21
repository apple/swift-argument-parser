//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import ArgumentParserTestHelpers
import Testing

@testable import ArgumentParser

// This set of tests asserts that a `helpBanner` declared on a command is
// rendered above the overview and is inherited by that command's subcommands.

extension HelpGenerationTests {
  fileprivate struct Root: ParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "root",
      abstract: "Does root things.",
      helpBanner: "Acme Corp. Copyright 1234",
      subcommands: [Inherits.self, Overrides.self, Suppresses.self])

    fileprivate struct Inherits: ParsableCommand {
      static let configuration = CommandConfiguration(
        abstract: "Inherits the banner.",
        subcommands: [Nested.self])

      fileprivate struct Nested: ParsableCommand {
        static let configuration = CommandConfiguration(
          abstract: "Inherits the banner from its grandparent.")
      }
    }

    fileprivate struct Overrides: ParsableCommand {
      static let configuration = CommandConfiguration(
        abstract: "Overrides the banner.",
        helpBanner: "Subsidiary Inc.",
        subcommands: [Nested.self])

      fileprivate struct Nested: ParsableCommand {
        static let configuration = CommandConfiguration(
          abstract: "Inherits the banner from its nearest ancestor.")
      }
    }

    fileprivate struct Suppresses: ParsableCommand {
      static let configuration = CommandConfiguration(
        abstract: "Suppresses the banner.",
        helpBanner: "")
    }
  }

  @Test func helpBannerOnRoot() async throws {
    try requireHelp(
      .default, for: Root.self,
      equals: """
        Acme Corp. Copyright 1234

        OVERVIEW: Does root things.

        USAGE: root <subcommand>

        OPTIONS:
          -h, --help              Show help information.

        SUBCOMMANDS:
          inherits                Inherits the banner.
          overrides               Overrides the banner.
          suppresses              Suppresses the banner.

          See 'root help <subcommand>' for detailed help.
          Use 'root help --search <term>' to search commands and options.
        """)
  }

  @Test func helpBannerIsInheritedByNestedSubcommand() async throws {
    try requireHelp(
      .default, for: Root.Inherits.Nested.self, root: Root.self,
      equals: """
        Acme Corp. Copyright 1234

        OVERVIEW: Inherits the banner from its grandparent.

        USAGE: root inherits nested

        OPTIONS:
          -h, --help              Show help information.

        """)
  }

  @Test func helpBannerCanBeOverriddenBySubcommand() async throws {
    try requireHelp(
      .default, for: Root.Overrides.self, root: Root.self,
      equals: """
        Subsidiary Inc.

        OVERVIEW: Overrides the banner.

        USAGE: root overrides <subcommand>

        OPTIONS:
          -h, --help              Show help information.

        SUBCOMMANDS:
          nested                  Inherits the banner from its nearest ancestor.

          See 'root help overrides <subcommand>' for detailed help.
          Use 'root help overrides --search <term>' to search commands and options.
        """)
  }

  /// The nearest ancestor that declares a banner wins, not the root.
  @Test func helpBannerIsInheritedFromNearestAncestor() async throws {
    try requireHelp(
      .default, for: Root.Overrides.Nested.self, root: Root.self,
      equals: """
        Subsidiary Inc.

        OVERVIEW: Inherits the banner from its nearest ancestor.

        USAGE: root overrides nested

        OPTIONS:
          -h, --help              Show help information.

        """)
  }

  @Test func helpBannerCanBeSuppressedBySubcommand() async throws {
    try requireHelp(
      .default, for: Root.Suppresses.self, root: Root.self,
      equals: """
        OVERVIEW: Suppresses the banner.

        USAGE: root suppresses

        OPTIONS:
          -h, --help              Show help information.

        """)
  }

  fileprivate struct NoBanner: ParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "no-banner",
      abstract: "Declares no banner.")
  }

  @Test func noHelpBannerLeavesHelpUnchanged() async throws {
    try requireHelp(
      .default, for: NoBanner.self,
      equals: """
        OVERVIEW: Declares no banner.

        USAGE: no-banner

        OPTIONS:
          -h, --help              Show help information.

        """)
  }

  fileprivate struct VerbatimBanner: ParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "verbatim-banner",
      abstract: "Declares a multi-line banner.",
      helpBanner: """
          _
         / \\  Acme
        /___\\ A banner line that is considerably longer than the eighty columns of the help screen
        """)
  }

  /// A banner is rendered verbatim, so multi-line banners and ASCII art are
  /// preserved and lines longer than the screen width are not wrapped.
  @Test func helpBannerIsNotWrapped() async throws {
    try requireHelp(
      .default, for: VerbatimBanner.self,
      equals: """
          _
         / \\  Acme
        /___\\ A banner line that is considerably longer than the eighty columns of the help screen

        OVERVIEW: Declares a multi-line banner.

        USAGE: verbatim-banner

        OPTIONS:
          -h, --help              Show help information.

        """)
  }

  fileprivate struct BannerNoAbstract: ParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "banner-no-abstract",
      helpBanner: "Acme Corp. Copyright 1234")
  }

  /// A banner does not introduce a stray blank line when the command has no
  /// abstract to follow it.
  @Test func helpBannerWithoutAbstract() async throws {
    try requireHelp(
      .default, for: BannerNoAbstract.self,
      equals: """
        Acme Corp. Copyright 1234

        USAGE: banner-no-abstract

        OPTIONS:
          -h, --help              Show help information.

        """)
  }
}
