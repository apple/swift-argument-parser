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

@Suite struct JoinedEndToEndTests {}

// MARK: -

private struct Foo: ParsableArguments {
  @Option(name: .customShort("f"))
  var file = ""

  @Option(name: .customShort("d", allowingJoined: true))
  var debug = ""

  @Flag(name: .customLong("fdi", withSingleDash: true))
  var fdi = false
}

// swift-format-ignore: AlwaysUseLowerCamelCase
// https://github.com/apple/swift-argument-parser/issues/710
extension JoinedEndToEndTests {
  @Test func singleValueParsing() throws {
    expectParse(Foo.self, []) { foo in
      #expect(foo.file == "")
      #expect(foo.debug == "")
      #expect(foo.fdi == false)
    }

    expectParse(Foo.self, ["-f", "file", "-d=Debug"]) { foo in
      #expect(foo.file == "file")
      #expect(foo.debug == "Debug")
      #expect(foo.fdi == false)
    }

    expectParse(Foo.self, ["-f", "file", "-d", "Debug"]) { foo in
      #expect(foo.file == "file")
      #expect(foo.debug == "Debug")
      #expect(foo.fdi == false)
    }

    expectParse(Foo.self, ["-f", "file", "-dDebug"]) { foo in
      #expect(foo.file == "file")
      #expect(foo.debug == "Debug")
      #expect(foo.fdi == false)
    }

    expectParse(Foo.self, ["-dDebug", "-f", "file"]) { foo in
      #expect(foo.file == "file")
      #expect(foo.debug == "Debug")
      #expect(foo.fdi == false)
    }

    expectParse(Foo.self, ["-dDebug"]) { foo in
      #expect(foo.file == "")
      #expect(foo.debug == "Debug")
      #expect(foo.fdi == false)
    }

    expectParse(Foo.self, ["-fd", "file", "Debug"]) { foo in
      #expect(foo.file == "file")
      #expect(foo.debug == "Debug")
      #expect(foo.fdi == false)
    }

    expectParse(Foo.self, ["-fd", "file", "Debug", "-fdi"]) { foo in
      #expect(foo.file == "file")
      #expect(foo.debug == "Debug")
      #expect(foo.fdi == true)
    }

    expectParse(Foo.self, ["-fdi"]) { foo in
      #expect(foo.file == "")
      #expect(foo.debug == "")
      #expect(foo.fdi == true)
    }
  }

  @Test func singleValueParsing_Fails() throws {
    #expect(throws: (any Error).self) { try Foo.parse(["-f", "-d"]) }
    #expect(throws: (any Error).self) { try Foo.parse(["-f", "file", "-d"]) }
    #expect(throws: (any Error).self) { try Foo.parse(["-fd", "file"]) }
    #expect(throws: (any Error).self) { try Foo.parse(["-fdDebug", "file"]) }
    #expect(throws: (any Error).self) { try Foo.parse(["-fFile"]) }
  }
}

// MARK: -

private struct Bar: ParsableArguments {
  @Option(name: .customShort("D", allowingJoined: true))
  var debug: [String] = []
}

// swift-format-ignore: AlwaysUseLowerCamelCase
// https://github.com/apple/swift-argument-parser/issues/710
extension JoinedEndToEndTests {
  @Test func arrayValueParsing() throws {
    expectParse(Bar.self, []) { bar in
      #expect(bar.debug == [])
    }

    expectParse(Bar.self, ["-Ddebug1"]) { bar in
      #expect(bar.debug == ["debug1"])
    }

    expectParse(Bar.self, ["-Ddebug1", "-Ddebug2", "-Ddebug3"]) { bar in
      #expect(bar.debug == ["debug1", "debug2", "debug3"])
    }

    expectParse(Bar.self, ["-D", "debug1", "-Ddebug2", "-D", "debug3"]) { bar in
      #expect(bar.debug == ["debug1", "debug2", "debug3"])
    }
  }

  @Test func arrayValueParsing_Fails() throws {
    #expect(throws: (any Error).self) { try Bar.parse(["-D"]) }
    #expect(throws: (any Error).self) { try Bar.parse(["-Ddebug1", "debug2"]) }
  }
}

// MARK: -

private struct Baz: ParsableArguments {
  @Option(
    name: .customShort("D", allowingJoined: true), parsing: .upToNextOption)
  var debug: [String] = []

  @Flag var verbose = false
}

// swift-format-ignore: AlwaysUseLowerCamelCase
// https://github.com/apple/swift-argument-parser/issues/710
extension JoinedEndToEndTests {
  @Test func arrayUpToNextParsing() throws {
    expectParse(Baz.self, []) { baz in
      #expect(baz.debug == [])
    }

    expectParse(Baz.self, ["-Ddebug1", "debug2"]) { baz in
      #expect(baz.debug == ["debug1", "debug2"])
      #expect(baz.verbose == false)
    }

    expectParse(Baz.self, ["-Ddebug1", "debug2", "--verbose"]) { baz in
      #expect(baz.debug == ["debug1", "debug2"])
      #expect(baz.verbose == true)
    }

    expectParse(Baz.self, ["-Ddebug1", "debug2", "-Ddebug3", "debug4"]) { baz in
      #expect(baz.debug == ["debug1", "debug2", "debug3", "debug4"])
    }
  }

  @Test func arrayUpToNextParsing_Fails() throws {
    #expect(throws: (any Error).self) { try Baz.parse(["-D", "--other"]) }
    #expect(throws: (any Error).self) { try Baz.parse(["-Ddebug", "--other"]) }
    #expect(throws: (any Error).self) { try Baz.parse(["-Ddebug", "--other"]) }
    #expect(throws: (any Error).self) {
      try Baz.parse(["-Ddebug", "debug", "--other"])
    }
  }
}

// MARK: -

private struct Qux: ParsableArguments {
  @Option(name: .customShort("D", allowingJoined: true), parsing: .remaining)
  var debug: [String] = []
}

// swift-format-ignore: AlwaysUseLowerCamelCase
// https://github.com/apple/swift-argument-parser/issues/710
extension JoinedEndToEndTests {
  @Test func arrayRemainingParsing() throws {
    expectParse(Qux.self, []) { qux in
      #expect(qux.debug == [])
    }

    expectParse(Qux.self, ["-Ddebug1", "debug2"]) { qux in
      #expect(qux.debug == ["debug1", "debug2"])
    }

    expectParse(
      Qux.self, ["-Ddebug1", "debug2", "-Ddebug3", "debug4", "--other"]
    ) { qux in
      #expect(
        qux.debug == ["debug1", "debug2", "-Ddebug3", "debug4", "--other"])
    }
  }

  @Test func arrayRemainingParsing_Fails() throws {
    #expect(throws: (any Error).self) {
      try Baz.parse(["--other", "-Ddebug", "debug"])
    }
  }
}
