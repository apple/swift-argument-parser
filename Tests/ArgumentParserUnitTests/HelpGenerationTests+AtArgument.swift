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
// valid combinations of @Argument.

// swift-format-ignore: AlwaysUseLowerCamelCase
// https://github.com/apple/swift-argument-parser/issues/710
extension HelpGenerationTests {
  enum AtArgumentTransform {
    // Not ExpressibleByArgument
    struct A {}

    struct BareNoDefault: ParsableCommand {
      @Argument(help: "example", transform: { _ in A() })
      var arg0: A
    }

    struct BareDefault: ParsableCommand {
      @Argument(help: "example", transform: { _ in A() })
      var arg0: A = A()
    }

    struct OptionalNoDefault: ParsableCommand {
      @Argument(help: "example", transform: { _ in A() })
      var arg0: A?
    }

    struct OptionalDefaultNil: ParsableCommand {
      @Argument(help: "example", transform: { _ in A() })
      var arg0: A? = nil
    }

    struct OptionalDefault: ParsableCommand {
      @Argument(help: "example", transform: { _ in A() })
      var arg0: A? = A()
    }

    struct ArrayNoDefault: ParsableCommand {
      @Argument(help: "example", transform: { _ in A() })
      var arg0: [A]
    }

    struct ArrayDefaultEmpty: ParsableCommand {
      @Argument(help: "example", transform: { _ in A() })
      var arg0: [A] = []
    }

    struct ArrayDefault: ParsableCommand {
      @Argument(help: "example", transform: { _ in A() })
      var arg0: [A] = [A()]
    }
  }

  @Test func atArgumentTransform_BareNoDefault() async throws {
    try requireHelp(
      .default,
      for: AtArgumentTransform.BareNoDefault.self,
      equals: """
        USAGE: bare-no-default <arg0>

        ARGUMENTS:
          <arg0>                  example

        OPTIONS:
          -h, --help              Show help information.

        """)
  }

  @Test func atArgumentTransform_BareDefault() async throws {
    try requireHelp(
      .default,
      for: AtArgumentTransform.BareDefault.self,
      equals: """
        USAGE: bare-default [<arg0>]

        ARGUMENTS:
          <arg0>                  example

        OPTIONS:
          -h, --help              Show help information.

        """)
  }

  @Test func atArgumentTransform_OptionalNoDefault() async throws {
    try requireHelp(
      .default,
      for: AtArgumentTransform.OptionalNoDefault.self,
      equals: """
        USAGE: optional-no-default [<arg0>]

        ARGUMENTS:
          <arg0>                  example

        OPTIONS:
          -h, --help              Show help information.

        """)
  }

  @Test func atArgumentTransform_OptionalDefaultNil() async throws {
    try requireHelp(
      .default,
      for: AtArgumentTransform.OptionalDefaultNil.self,
      equals: """
        USAGE: optional-default-nil [<arg0>]

        ARGUMENTS:
          <arg0>                  example

        OPTIONS:
          -h, --help              Show help information.

        """)
  }

  @Test func atArgumentTransform_OptionalDefault() async throws {
    try requireHelp(
      .default,
      for: AtArgumentTransform.OptionalDefault.self,
      equals: """
        USAGE: optional-default [<arg0>]

        ARGUMENTS:
          <arg0>                  example

        OPTIONS:
          -h, --help              Show help information.

        """)
  }

  @Test func atArgumentTransform_ArrayNoDefault() async throws {
    try requireHelp(
      .default,
      for: AtArgumentTransform.ArrayNoDefault.self,
      equals: """
        USAGE: array-no-default <arg0> ...

        ARGUMENTS:
          <arg0>                  example

        OPTIONS:
          -h, --help              Show help information.

        """)
  }

  @Test func atArgumentTransform_ArrayDefaultEmpty() async throws {
    try requireHelp(
      .default,
      for: AtArgumentTransform.ArrayDefaultEmpty.self,
      equals: """
        USAGE: array-default-empty [<arg0> ...]

        ARGUMENTS:
          <arg0>                  example

        OPTIONS:
          -h, --help              Show help information.

        """)
  }

  @Test func atArgumentTransform_ArrayDefault() async throws {
    try requireHelp(
      .default,
      for: AtArgumentTransform.ArrayDefault.self,
      equals: """
        USAGE: array-default [<arg0> ...]

        ARGUMENTS:
          <arg0>                  example

        OPTIONS:
          -h, --help              Show help information.

        """)
  }
}

// swift-format-ignore: AlwaysUseLowerCamelCase
// https://github.com/apple/swift-argument-parser/issues/710
extension HelpGenerationTests {
  enum AtArgumentEBA {
    // ExpressibleByArgument
    struct A: ExpressibleByArgument {
      static var allValueStrings: [String] { ["A()"] }
      var defaultValueDescription: String { "A()" }
      init() {}
      init?(argument: String) { self.init() }
    }

    struct BareNoDefault: ParsableCommand {
      @Argument(help: "example")
      var arg0: A
    }

    struct BareDefault: ParsableCommand {
      @Argument(help: "example")
      var arg0: A = A()
    }

    struct OptionalNoDefault: ParsableCommand {
      @Argument(help: "example")
      var arg0: A?
    }

    struct OptionalDefaultNil: ParsableCommand {
      @Argument(help: "example")
      var arg0: A? = nil
    }

    @available(*, deprecated, message: "Included for test coverage")
    struct OptionalDefault: ParsableCommand {
      @Argument(help: "example")
      var arg0: A? = A()
    }

    struct ArrayNoDefault: ParsableCommand {
      @Argument(help: "example")
      var arg0: [A]
    }

    struct ArrayDefaultEmpty: ParsableCommand {
      @Argument(help: "example")
      var arg0: [A] = []
    }

    struct ArrayDefault: ParsableCommand {
      @Argument(help: "example")
      var arg0: [A] = [A()]
    }
  }

  @Test func atArgumentEBA_BareNoDefault() async throws {
    try requireHelp(
      .default,
      for: AtArgumentEBA.BareNoDefault.self,
      equals: """
        USAGE: bare-no-default <arg0>

        ARGUMENTS:
          <arg0>                  example (values: A())

        OPTIONS:
          -h, --help              Show help information.

        """)
  }

  @Test func atArgumentEBA_BareDefault() async throws {
    try requireHelp(
      .default,
      for: AtArgumentEBA.BareDefault.self,
      equals: """
        USAGE: bare-default [<arg0>]

        ARGUMENTS:
          <arg0>                  example (values: A(); default: A())

        OPTIONS:
          -h, --help              Show help information.

        """)
  }

  @Test func atArgumentEBA_OptionalNoDefault() async throws {
    try requireHelp(
      .default,
      for: AtArgumentEBA.OptionalNoDefault.self,
      equals: """
        USAGE: optional-no-default [<arg0>]

        ARGUMENTS:
          <arg0>                  example (values: A())

        OPTIONS:
          -h, --help              Show help information.

        """)
  }

  @Test func atArgumentEBA_OptionalDefaultNil() async throws {
    try requireHelp(
      .default,
      for: AtArgumentEBA.OptionalDefaultNil.self,
      equals: """
        USAGE: optional-default-nil [<arg0>]

        ARGUMENTS:
          <arg0>                  example (values: A())

        OPTIONS:
          -h, --help              Show help information.

        """)
  }

  @Test func atArgumentEBA_ArrayNoDefault() async throws {
    try requireHelp(
      .default,
      for: AtArgumentEBA.ArrayNoDefault.self,
      equals: """
        USAGE: array-no-default <arg0> ...

        ARGUMENTS:
          <arg0>                  example (values: A())

        OPTIONS:
          -h, --help              Show help information.

        """)
  }

  @Test func atArgumentEBA_ArrayDefaultEmpty() async throws {
    try requireHelp(
      .default,
      for: AtArgumentEBA.ArrayDefaultEmpty.self,
      equals: """
        USAGE: array-default-empty [<arg0> ...]

        ARGUMENTS:
          <arg0>                  example (values: A())

        OPTIONS:
          -h, --help              Show help information.

        """)
  }

  @Test func atArgumentEBA_ArrayDefault() async throws {
    try requireHelp(
      .default,
      for: AtArgumentEBA.ArrayDefault.self,
      equals: """
        USAGE: array-default [<arg0> ...]

        ARGUMENTS:
          <arg0>                  example (values: A(); default: A())

        OPTIONS:
          -h, --help              Show help information.

        """)
  }
}

// swift-format-ignore: AlwaysUseLowerCamelCase
// https://github.com/apple/swift-argument-parser/issues/710
extension HelpGenerationTests {
  enum AtArgumentEBATransform {
    // ExpressibleByArgument with Transform
    struct A: ExpressibleByArgument {
      static var allValueStrings: [String] { ["A()"] }
      var defaultValueDescription: String { "A()" }
      init() {}
      init?(argument: String) { self.init() }
    }

    struct BareNoDefault: ParsableCommand {
      @Argument(help: "example", transform: { _ in A() })
      var arg0: A
    }

    struct BareDefault: ParsableCommand {
      @Argument(help: "example", transform: { _ in A() })
      var arg0: A = A()
    }

    struct OptionalNoDefault: ParsableCommand {
      @Argument(help: "example", transform: { _ in A() })
      var arg0: A?
    }

    struct OptionalDefaultNil: ParsableCommand {
      @Argument(help: "example", transform: { _ in A() })
      var arg0: A? = nil
    }

    struct OptionalDefault: ParsableCommand {
      @Argument(help: "example", transform: { _ in A() })
      var arg0: A? = A()
    }

    struct ArrayNoDefault: ParsableCommand {
      @Argument(help: "example", transform: { _ in A() })
      var arg0: [A]
    }

    struct ArrayDefaultEmpty: ParsableCommand {
      @Argument(help: "example", transform: { _ in A() })
      var arg0: [A] = []
    }

    struct ArrayDefault: ParsableCommand {
      @Argument(help: "example", transform: { _ in A() })
      var arg0: [A] = [A()]
    }
  }

  @Test func atArgumentEBATransform_BareNoDefault() async throws {
    try requireHelp(
      .default,
      for: AtArgumentEBATransform.BareNoDefault.self,
      equals: """
        USAGE: bare-no-default <arg0>

        ARGUMENTS:
          <arg0>                  example

        OPTIONS:
          -h, --help              Show help information.

        """)
  }

  @Test func atArgumentEBATransform_BareDefault() async throws {
    try requireHelp(
      .default,
      for: AtArgumentEBATransform.BareDefault.self,
      equals: """
        USAGE: bare-default [<arg0>]

        ARGUMENTS:
          <arg0>                  example

        OPTIONS:
          -h, --help              Show help information.

        """)
  }

  @Test func atArgumentEBATransform_OptionalNoDefault() async throws {
    try requireHelp(
      .default,
      for: AtArgumentEBATransform.OptionalNoDefault.self,
      equals: """
        USAGE: optional-no-default [<arg0>]

        ARGUMENTS:
          <arg0>                  example

        OPTIONS:
          -h, --help              Show help information.

        """)
  }

  @Test func atArgumentEBATransform_OptionalDefaultNil() async throws {
    try requireHelp(
      .default,
      for: AtArgumentEBATransform.OptionalDefaultNil.self,
      equals: """
        USAGE: optional-default-nil [<arg0>]

        ARGUMENTS:
          <arg0>                  example

        OPTIONS:
          -h, --help              Show help information.

        """)
  }

  @Test func atArgumentEBATransform_OptionalDefault() async throws {
    try requireHelp(
      .default,
      for: AtArgumentEBATransform.OptionalDefault.self,
      equals: """
        USAGE: optional-default [<arg0>]

        ARGUMENTS:
          <arg0>                  example

        OPTIONS:
          -h, --help              Show help information.

        """)
  }

  @Test func atArgumentEBATransform_ArrayNoDefault() async throws {
    try requireHelp(
      .default,
      for: AtArgumentEBATransform.ArrayNoDefault.self,
      equals: """
        USAGE: array-no-default <arg0> ...

        ARGUMENTS:
          <arg0>                  example

        OPTIONS:
          -h, --help              Show help information.

        """)
  }

  @Test func atArgumentEBATransform_ArrayDefaultEmpty() async throws {
    try requireHelp(
      .default,
      for: AtArgumentEBATransform.ArrayDefaultEmpty.self,
      equals: """
        USAGE: array-default-empty [<arg0> ...]

        ARGUMENTS:
          <arg0>                  example

        OPTIONS:
          -h, --help              Show help information.

        """)
  }

  @Test func atArgumentEBATransform_ArrayDefault() async throws {
    try requireHelp(
      .default,
      for: AtArgumentEBATransform.ArrayDefault.self,
      equals: """
        USAGE: array-default [<arg0> ...]

        ARGUMENTS:
          <arg0>                  example

        OPTIONS:
          -h, --help              Show help information.

        """)
  }
}
