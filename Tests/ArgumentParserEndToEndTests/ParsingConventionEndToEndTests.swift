//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import XCTest
import ArgumentParserTestHelpers
import ArgumentParser

final class ParsingConventionEndToEndTests: XCTestCase {
}

fileprivate struct Foo: ParsableCommand {
  @Flag
  var ABCHelloWorld = false
  @Flag
  var defHelloWorld = false
  @Flag
  var ABC123HelloWorld = false
  @Flag
  var ABC123HelloWorldDEF456 = false
  @Flag
  var abc123HelloWorld456def = false
  @Flag
  var URL = false

  @Flag(name: .short)
  var a = false
  @Flag(name: .short)
  var b = false
  @Flag(name: .short)
  var c = false

  @Option
  var longNamedOption: String = ""
}

extension ParsingConventionEndToEndTests {
  func testParsingConventions() throws {
    let oldConvention = ParsingConvention.current
    defer {
      ParsingConvention.current = oldConvention
    }

    ParsingConvention.current = .posix
    AssertParse(Foo.self, ["--abc-hello-world", "--def-hello-world", "--abc123-hello-world-def456", "--abc123-hello-world456def", "--url", "-abc", "--long-named-option=value"]) { _ in }
    AssertParse(Foo.self, ["-a", "-b", "-c"]) { _ in }

    ParsingConvention.current = .dos
    AssertParse(Foo.self, ["/ABCHelloWorld", "/DefHelloWorld", "/ABC123HelloWorldDEF456", "/Abc123HelloWorld456def", "/URL", "+abc", "/LongNamedOption=value"]) { _ in }
    AssertParse(Foo.self, ["+a", "+b", "+c"]) { _ in }
    AssertParse(Foo.self, ["/LongNamedOption:value"]) { _ in }
  }
}

fileprivate struct Bar: ParsableCommand {
  @Flag
  var hello = false

  @Flag(name: .long)
  var goodbye = false

  @Flag(name: .customLong("mac-intosh"))
  var macIntosh = false

  @Flag(name: .short)
  var a = false

  @Option
  var longNamedOption: String
}

extension ParsingConventionEndToEndTests {
  func testParsingHelp() throws {
    let oldConvention = ParsingConvention.current
    defer {
      ParsingConvention.current = oldConvention
    }

    ParsingConvention.current = .posix
    AssertHelp(for: Bar.self, usingArgumentName: "-h", equals: """
    USAGE: bar [--hello] [--goodbye] [--mac-intosh] [-a] --long-named-option <long-named-option>

    OPTIONS:
      --hello
      --goodbye
      --mac-intosh
      -a
      --long-named-option <long-named-option>
      -h, --help              Show help information.

    """)

    ParsingConvention.current = .dos
    AssertHelp(for: Bar.self, usingArgumentName: "/?", equals: """
    USAGE: Bar [/Hello] [/Goodbye] [/mac-intosh] [+a] /LongNamedOption <LongNamedOption>

    OPTIONS:
      /Hello
      /Goodbye
      /mac-intosh
      +a
      /LongNamedOption <LongNamedOption>
      /h, /Help, /?           Show help information.

    """)
  }
}
