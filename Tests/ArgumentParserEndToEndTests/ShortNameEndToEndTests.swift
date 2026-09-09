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
