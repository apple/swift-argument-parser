//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import ArgumentParserTestHelpers
import Testing

@testable import ArgumentParser

// This set of tests assert the help output matches the expected value for all
// valid combinations of @Option.

// swift-format-ignore: AlwaysUseLowerCamelCase
// https://github.com/apple/swift-argument-parser/issues/710
extension HelpGenerationTests {
  enum AtOptionTransform {
    // Not ExpressibleByArgument
    struct A {}

    struct BareNoDefault: ParsableCommand {
      @Option(help: "example", transform: { _ in A() })
      var arg0: A
    }

    struct BareDefault: ParsableCommand {
      @Option(help: "example", transform: { _ in A() })
      var arg0: A = A()
    }

    struct OptionalNoDefault: ParsableCommand {
      @Option(help: "example", transform: { _ in A() })
      var arg0: A?
    }

    struct OptionalDefaultNil: ParsableCommand {
      @Option(help: "example", transform: { _ in A() })
      var arg0: A? = nil
    }

    struct OptionalDefault: ParsableCommand {
      @Option(help: "example", transform: { _ in A() })
      var arg0: A? = A()
    }

    struct ArrayNoDefault: ParsableCommand {
      @Option(help: "example", transform: { _ in A() })
      var arg0: [A]
    }

    struct ArrayDefaultEmpty: ParsableCommand {
      @Option(help: "example", transform: { _ in A() })
      var arg0: [A] = []
    }

    struct ArrayDefault: ParsableCommand {
      @Option(help: "example", transform: { _ in A() })
      var arg0: [A] = [A()]
    }
  }

  @Test func atOptionTransform_BareNoDefault() async throws {
    try requireHelp(
      .default, for: AtOptionTransform.BareNoDefault.self,
      equals: """
        USAGE: bare-no-default --arg0 <arg0>

        OPTIONS:
          --arg0 <arg0>           example
          -h, --help              Show help information.

        """)
  }

  @Test func atOptionTransform_BareDefault() async throws {
    try requireHelp(
      .default, for: AtOptionTransform.BareDefault.self,
      equals: """
        USAGE: bare-default [--arg0 <arg0>]

        OPTIONS:
          --arg0 <arg0>           example
          -h, --help              Show help information.

        """)
  }

  @Test func atOptionTransform_OptionalNoDefault() async throws {
    try requireHelp(
      .default, for: AtOptionTransform.OptionalNoDefault.self,
      equals: """
        USAGE: optional-no-default [--arg0 <arg0>]

        OPTIONS:
          --arg0 <arg0>           example
          -h, --help              Show help information.

        """)
  }

  @Test func atOptionTransform_OptionalDefaultNil() async throws {
    try requireHelp(
      .default, for: AtOptionTransform.OptionalDefaultNil.self,
      equals: """
        USAGE: optional-default-nil [--arg0 <arg0>]

        OPTIONS:
          --arg0 <arg0>           example
          -h, --help              Show help information.

        """)
  }

  @Test func atOptionTransform_OptionalDefault() async throws {
    try requireHelp(
      .default, for: AtOptionTransform.OptionalDefault.self,
      equals: """
        USAGE: optional-default [--arg0 <arg0>]

        OPTIONS:
          --arg0 <arg0>           example
          -h, --help              Show help information.

        """)
  }

  @Test func atOptionTransform_ArrayNoDefault() async throws {
    try requireHelp(
      .default, for: AtOptionTransform.ArrayNoDefault.self,
      equals: """
        USAGE: array-no-default --arg0 <arg0> ...

        OPTIONS:
          --arg0 <arg0>           example
          -h, --help              Show help information.

        """)
  }

  @Test func atOptionTransform_ArrayDefaultEmpty() async throws {
    try requireHelp(
      .default, for: AtOptionTransform.ArrayDefaultEmpty.self,
      equals: """
        USAGE: array-default-empty [--arg0 <arg0> ...]

        OPTIONS:
          --arg0 <arg0>           example
          -h, --help              Show help information.

        """)
  }

  @Test func atOptionTransform_ArrayDefault() async throws {
    try requireHelp(
      .default, for: AtOptionTransform.ArrayDefault.self,
      equals: """
        USAGE: array-default [--arg0 <arg0> ...]

        OPTIONS:
          --arg0 <arg0>           example
          -h, --help              Show help information.

        """)
  }
}

// swift-format-ignore: AlwaysUseLowerCamelCase
// https://github.com/apple/swift-argument-parser/issues/710
extension HelpGenerationTests {
  enum AtOptionEBA {
    // ExpressibleByArgument
    struct A: ExpressibleByArgument {
      static var allValueStrings: [String] { ["A()"] }
      var defaultValueDescription: String { "A()" }
      init() {}
      init?(argument: String) { self.init() }
    }

    struct BareNoDefault: ParsableCommand {
      @Option(help: "example")
      var arg0: A
    }

    struct BareDefault: ParsableCommand {
      @Option(help: "example")
      var arg0: A = A()
    }

    struct OptionalNoDefault: ParsableCommand {
      @Option(help: "example")
      var arg0: A?
    }

    struct OptionalDefaultNil: ParsableCommand {
      @Option(help: "example")
      var arg0: A? = nil
    }

    @available(*, deprecated, message: "Included for test coverage")
    struct OptionalDefault: ParsableCommand {
      @Option(help: "example")
      var arg0: A? = A()
    }

    struct ArrayNoDefault: ParsableCommand {
      @Option(help: "example")
      var arg0: [A]
    }

    struct ArrayDefaultEmpty: ParsableCommand {
      @Option(help: "example")
      var arg0: [A] = []
    }

    struct ArrayDefault: ParsableCommand {
      @Option(help: "example")
      var arg0: [A] = [A()]
    }
  }

  @Test func atOptionEBA_BareNoDefault() async throws {
    try requireHelp(
      .default, for: AtOptionEBA.BareNoDefault.self,
      equals: """
        USAGE: bare-no-default --arg0 <arg0>

        OPTIONS:
          --arg0 <arg0>           example (values: A())
          -h, --help              Show help information.

        """)
  }

  @Test func atOptionEBA_BareDefault() async throws {
    try requireHelp(
      .default, for: AtOptionEBA.BareDefault.self,
      equals: """
        USAGE: bare-default [--arg0 <arg0>]

        OPTIONS:
          --arg0 <arg0>           example (values: A(); default: A())
          -h, --help              Show help information.

        """)
  }

  @Test func atOptionEBA_OptionalNoDefault() async throws {
    try requireHelp(
      .default, for: AtOptionEBA.OptionalNoDefault.self,
      equals: """
        USAGE: optional-no-default [--arg0 <arg0>]

        OPTIONS:
          --arg0 <arg0>           example (values: A())
          -h, --help              Show help information.

        """)
  }

  @Test func atOptionEBA_OptionalDefaultNil() async throws {
    try requireHelp(
      .default, for: AtOptionEBA.OptionalDefaultNil.self,
      equals: """
        USAGE: optional-default-nil [--arg0 <arg0>]

        OPTIONS:
          --arg0 <arg0>           example (values: A())
          -h, --help              Show help information.

        """)
  }

  @Test func atOptionEBA_ArrayNoDefault() async throws {
    try requireHelp(
      .default, for: AtOptionEBA.ArrayNoDefault.self,
      equals: """
        USAGE: array-no-default --arg0 <arg0> ...

        OPTIONS:
          --arg0 <arg0>           example (values: A())
          -h, --help              Show help information.

        """)
  }

  @Test func atOptionEBA_ArrayDefaultEmpty() async throws {
    try requireHelp(
      .default, for: AtOptionEBA.ArrayDefaultEmpty.self,
      equals: """
        USAGE: array-default-empty [--arg0 <arg0> ...]

        OPTIONS:
          --arg0 <arg0>           example (values: A())
          -h, --help              Show help information.

        """)
  }

  @Test func atOptionEBA_ArrayDefault() async throws {
    try requireHelp(
      .default, for: AtOptionEBA.ArrayDefault.self,
      equals: """
        USAGE: array-default [--arg0 <arg0> ...]

        OPTIONS:
          --arg0 <arg0>           example (values: A(); default: A())
          -h, --help              Show help information.

        """)
  }
}

// swift-format-ignore: AlwaysUseLowerCamelCase
// https://github.com/apple/swift-argument-parser/issues/710
extension HelpGenerationTests {
  enum AtOptionEBATransform {
    // ExpressibleByArgument with Transform
    struct A: ExpressibleByArgument {
      static var allValueStrings: [String] { ["A()"] }
      var defaultValueDescription: String { "A()" }
      init() {}
      init?(argument: String) { self.init() }
    }

    struct BareNoDefault: ParsableCommand {
      @Option(help: "example", transform: { _ in A() })
      var arg0: A
    }

    struct BareDefault: ParsableCommand {
      @Option(help: "example", transform: { _ in A() })
      var arg0: A = A()
    }

    struct OptionalNoDefault: ParsableCommand {
      @Option(help: "example", transform: { _ in A() })
      var arg0: A?
    }

    struct OptionalDefaultNil: ParsableCommand {
      @Option(help: "example", transform: { _ in A() })
      var arg0: A? = nil
    }

    struct OptionalDefault: ParsableCommand {
      @Option(help: "example", transform: { _ in A() })
      var arg0: A? = A()
    }

    struct ArrayNoDefault: ParsableCommand {
      @Option(help: "example", transform: { _ in A() })
      var arg0: [A]
    }

    struct ArrayDefaultEmpty: ParsableCommand {
      @Option(help: "example", transform: { _ in A() })
      var arg0: [A] = []
    }

    struct ArrayDefault: ParsableCommand {
      @Option(help: "example", transform: { _ in A() })
      var arg0: [A] = [A()]
    }
  }

  @Test func atOptionEBATransform_BareNoDefault() async throws {
    try requireHelp(
      .default, for: AtOptionEBATransform.BareNoDefault.self,
      equals: """
        USAGE: bare-no-default --arg0 <arg0>

        OPTIONS:
          --arg0 <arg0>           example
          -h, --help              Show help information.

        """)
  }

  @Test func atOptionEBATransform_BareDefault() async throws {
    try requireHelp(
      .default, for: AtOptionEBATransform.BareDefault.self,
      equals: """
        USAGE: bare-default [--arg0 <arg0>]

        OPTIONS:
          --arg0 <arg0>           example
          -h, --help              Show help information.

        """)
  }

  @Test func atOptionEBATransform_OptionalNoDefault() async throws {
    try requireHelp(
      .default, for: AtOptionEBATransform.OptionalNoDefault.self,
      equals: """
        USAGE: optional-no-default [--arg0 <arg0>]

        OPTIONS:
          --arg0 <arg0>           example
          -h, --help              Show help information.

        """)
  }

  @Test func atOptionEBATransform_OptionalDefaultNil() async throws {
    try requireHelp(
      .default, for: AtOptionEBATransform.OptionalDefaultNil.self,
      equals: """
        USAGE: optional-default-nil [--arg0 <arg0>]

        OPTIONS:
          --arg0 <arg0>           example
          -h, --help              Show help information.

        """)
  }

  @Test func atOptionEBATransform_OptionalDefault() async throws {
    try requireHelp(
      .default, for: AtOptionEBATransform.OptionalDefault.self,
      equals: """
        USAGE: optional-default [--arg0 <arg0>]

        OPTIONS:
          --arg0 <arg0>           example
          -h, --help              Show help information.

        """)
  }

  @Test func atOptionEBATransform_ArrayNoDefault() async throws {
    try requireHelp(
      .default, for: AtOptionEBATransform.ArrayNoDefault.self,
      equals: """
        USAGE: array-no-default --arg0 <arg0> ...

        OPTIONS:
          --arg0 <arg0>           example
          -h, --help              Show help information.

        """)
  }

  @Test func atOptionEBATransform_ArrayDefaultEmpty() async throws {
    try requireHelp(
      .default, for: AtOptionEBATransform.ArrayDefaultEmpty.self,
      equals: """
        USAGE: array-default-empty [--arg0 <arg0> ...]

        OPTIONS:
          --arg0 <arg0>           example
          -h, --help              Show help information.

        """)
  }

  @Test func atOptionEBATransform_ArrayDefault() async throws {
    try requireHelp(
      .default, for: AtOptionEBATransform.ArrayDefault.self,
      equals: """
        USAGE: array-default [--arg0 <arg0> ...]

        OPTIONS:
          --arg0 <arg0>           example
          -h, --help              Show help information.

        """)
  }
}
