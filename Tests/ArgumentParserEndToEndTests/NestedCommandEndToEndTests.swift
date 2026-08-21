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

import ArgumentParser
import ArgumentParserTestHelpers
import Testing

@Suite struct NestedCommandEndToEndTests {}

// MARK: Single value String

private struct Foo: ParsableCommand {
  static let configuration =
    CommandConfiguration(subcommands: [Build.self, Package.self])

  @Flag(name: .short)
  var verbose: Bool = false

  struct Build: ParsableCommand {
    @OptionGroup() var foo: Foo

    @Argument()
    var input: String
  }

  struct Package: ParsableCommand {
    static let configuration =
      CommandConfiguration(
        subcommands: [Clean.self, Config.self],
        aliases: ["pkg"])

    @Flag(name: .short)
    var force: Bool = false

    struct Clean: ParsableCommand {
      @OptionGroup() var foo: Foo
      @OptionGroup() var package: Package
    }

    struct Config: ParsableCommand {
      static let configuration = CommandConfiguration(aliases: ["cfg"])
      @OptionGroup() var foo: Foo
      @OptionGroup() var package: Package
    }
  }
}

private func expectParseFooCommand<A>(
  _ type: A.Type, _ arguments: [String],
  sourceLocation: SourceLocation = #_sourceLocation,
  closure: (A) throws -> Void
) where A: ParsableCommand {
  expectParseCommand(
    Foo.self, type, arguments, sourceLocation: sourceLocation, closure: closure)
}

// swift-format-ignore: AlwaysUseLowerCamelCase
// https://github.com/apple/swift-argument-parser/issues/710
extension NestedCommandEndToEndTests {
  @Test func parsing_package() throws {
    expectParseFooCommand(Foo.Package.self, ["package"]) { package in
      #expect(package.force == false)
    }

    expectParseFooCommand(Foo.Package.self, ["pkg"]) { package in
      #expect(package.force == false)
    }

    expectParseFooCommand(Foo.Package.Clean.self, ["package", "clean"]) {
      clean in
      #expect(clean.foo.verbose == false)
      #expect(clean.package.force == false)
    }

    expectParseFooCommand(Foo.Package.Clean.self, ["pkg", "clean"]) { clean in
      #expect(clean.foo.verbose == false)
      #expect(clean.package.force == false)
    }

    expectParseFooCommand(Foo.Package.Clean.self, ["package", "-f", "clean"]) {
      clean in
      #expect(clean.foo.verbose == false)
      #expect(clean.package.force == true)
    }

    expectParseFooCommand(Foo.Package.Clean.self, ["pkg", "-f", "clean"]) {
      clean in
      #expect(clean.foo.verbose == false)
      #expect(clean.package.force == true)
    }

    expectParseFooCommand(Foo.Package.Config.self, ["package", "-v", "config"])
    { config in
      #expect(config.foo.verbose == true)
      #expect(config.package.force == false)
    }

    expectParseFooCommand(Foo.Package.Config.self, ["pkg", "-v", "cfg"]) {
      config in
      #expect(config.foo.verbose == true)
      #expect(config.package.force == false)
    }

    expectParseFooCommand(Foo.Package.Config.self, ["package", "config", "-v"])
    { config in
      #expect(config.foo.verbose == true)
      #expect(config.package.force == false)
    }

    expectParseFooCommand(Foo.Package.Config.self, ["pkg", "cfg", "-v"]) {
      config in
      #expect(config.foo.verbose == true)
      #expect(config.package.force == false)
    }

    expectParseFooCommand(Foo.Package.Config.self, ["-v", "package", "config"])
    { config in
      #expect(config.foo.verbose == true)
      #expect(config.package.force == false)
    }

    expectParseFooCommand(Foo.Package.Config.self, ["-v", "pkg", "cfg"]) {
      config in
      #expect(config.foo.verbose == true)
      #expect(config.package.force == false)
    }

    expectParseFooCommand(Foo.Package.Config.self, ["package", "-f", "config"])
    { config in
      #expect(config.foo.verbose == false)
      #expect(config.package.force == true)
    }

    expectParseFooCommand(Foo.Package.Config.self, ["pkg", "-f", "cfg"]) {
      config in
      #expect(config.foo.verbose == false)
      #expect(config.package.force == true)
    }

    expectParseFooCommand(Foo.Package.Config.self, ["package", "config", "-f"])
    { config in
      #expect(config.foo.verbose == false)
      #expect(config.package.force == true)
    }

    expectParseFooCommand(Foo.Package.Config.self, ["pkg", "cfg", "-f"]) {
      config in
      #expect(config.foo.verbose == false)
      #expect(config.package.force == true)
    }

    expectParseFooCommand(
      Foo.Package.Config.self, ["package", "-v", "config", "-f"]
    ) { config in
      #expect(config.foo.verbose == true)
      #expect(config.package.force == true)
    }

    expectParseFooCommand(Foo.Package.Config.self, ["pkg", "-v", "cfg", "-f"]) {
      config in
      #expect(config.foo.verbose == true)
      #expect(config.package.force == true)
    }

    expectParseFooCommand(
      Foo.Package.Config.self, ["package", "-f", "config", "-v"]
    ) { config in
      #expect(config.foo.verbose == true)
      #expect(config.package.force == true)
    }

    expectParseFooCommand(Foo.Package.Config.self, ["pkg", "-f", "cfg", "-v"]) {
      config in
      #expect(config.foo.verbose == true)
      #expect(config.package.force == true)
    }

    expectParseFooCommand(
      Foo.Package.Config.self, ["package", "-vf", "config"]
    ) { config in
      #expect(config.foo.verbose == true)
      #expect(config.package.force == true)
    }

    expectParseFooCommand(Foo.Package.Config.self, ["pkg", "-vf", "cfg"]) {
      config in
      #expect(config.foo.verbose == true)
      #expect(config.package.force == true)
    }

    expectParseFooCommand(
      Foo.Package.Config.self, ["package", "-fv", "config"]
    ) { config in
      #expect(config.foo.verbose == true)
      #expect(config.package.force == true)
    }

    expectParseFooCommand(Foo.Package.Config.self, ["pkg", "-fv", "cfg"]) {
      config in
      #expect(config.foo.verbose == true)
      #expect(config.package.force == true)
    }
  }

  @Test func parsing_build() throws {
    expectParseFooCommand(Foo.Build.self, ["build", "file"]) { build in
      #expect(build.foo.verbose == false)
      #expect(build.input == "file")
    }
  }

  @Test func parsing_fails() throws {
    #expect(throws: (any Error).self) {
      try Foo.parseAsRoot(["clean", "package"])
    }
    #expect(throws: (any Error).self) { try Foo.parseAsRoot(["clean", "pkg"]) }
    #expect(throws: (any Error).self) {
      try Foo.parseAsRoot(["config", "package"])
    }
    #expect(throws: (any Error).self) { try Foo.parseAsRoot(["cfg", "pkg"]) }
    #expect(throws: (any Error).self) { try Foo.parseAsRoot(["package", "c"]) }
    #expect(throws: (any Error).self) { try Foo.parseAsRoot(["pkg", "c"]) }
    #expect(throws: (any Error).self) {
      try Foo.parseAsRoot(["package", "build"])
    }
    #expect(throws: (any Error).self) { try Foo.parseAsRoot(["pkg", "build"]) }
    #expect(throws: (any Error).self) {
      try Foo.parseAsRoot(["package", "build", "clean"])
    }
    #expect(throws: (any Error).self) {
      try Foo.parseAsRoot(["pkg", "build", "clean"])
    }
    #expect(throws: (any Error).self) {
      try Foo.parseAsRoot(["package", "clean", "foo"])
    }
    #expect(throws: (any Error).self) {
      try Foo.parseAsRoot(["pkg", "clean", "foo"])
    }
    #expect(throws: (any Error).self) {
      try Foo.parseAsRoot(["package", "config", "bar"])
    }
    #expect(throws: (any Error).self) {
      try Foo.parseAsRoot(["pkg", "cfg", "bar"])
    }
    #expect(throws: (any Error).self) {
      try Foo.parseAsRoot(["package", "clean", "build"])
    }
    #expect(throws: (any Error).self) {
      try Foo.parseAsRoot(["pkg", "clean", "build"])
    }
    #expect(throws: (any Error).self) { try Foo.parseAsRoot(["build"]) }
    #expect(throws: (any Error).self) { try Foo.parseAsRoot(["build", "-f"]) }
    #expect(throws: (any Error).self) {
      try Foo.parseAsRoot(["build", "--build"])
    }
    #expect(throws: (any Error).self) {
      try Foo.parseAsRoot(["build", "--build", "12"])
    }
    #expect(throws: (any Error).self) {
      try Foo.parseAsRoot(["-f", "package", "clean"])
    }
    #expect(throws: (any Error).self) {
      try Foo.parseAsRoot(["-f", "pkg", "clean"])
    }
    #expect(throws: (any Error).self) {
      try Foo.parseAsRoot(["-f", "package", "config"])
    }
    #expect(throws: (any Error).self) {
      try Foo.parseAsRoot(["-f", "pkg", "config"])
    }
  }
}

private struct Options: ParsableArguments {
  @Option() var firstName: String?
}

private struct UniqueOptions: ParsableArguments {
  @Option() var lastName: String?
}

private struct Super: ParsableCommand {
  static var configuration: CommandConfiguration {
    .init(subcommands: [Sub1.self, Sub2.self])
  }

  @OptionGroup() var options: Options

  struct Sub1: ParsableCommand {
    @OptionGroup() var options: Options
  }

  struct Sub2: ParsableCommand {
    @OptionGroup() var options: UniqueOptions
  }
}

// swift-format-ignore: AlwaysUseLowerCamelCase
// https://github.com/apple/swift-argument-parser/issues/710
extension NestedCommandEndToEndTests {
  @Test func parsing_SharedOptions() throws {
    expectParseCommand(Super.self, Super.self, []) { sup in
      #expect(sup.options.firstName == nil)
    }

    expectParseCommand(Super.self, Super.self, ["--first-name", "Foo"]) { sup in
      #expect(sup.options.firstName == "Foo")
    }

    expectParseCommand(Super.self, Super.Sub1.self, ["sub1"]) { sub1 in
      #expect(sub1.options.firstName == nil)
    }

    expectParseCommand(
      Super.self, Super.Sub1.self, ["sub1", "--first-name", "Foo"]
    ) { sub1 in
      #expect(sub1.options.firstName == "Foo")
    }

    expectParseCommand(
      Super.self, Super.Sub2.self, ["sub2", "--last-name", "Foo"]
    ) { sub2 in
      #expect(sub2.options.lastName == "Foo")
    }
  }
}
