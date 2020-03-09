//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import XCTest
import ArgumentParserTestHelpers
import ArgumentParser

final class SubcommandEndToEndTests: XCTestCase {
}

// MARK: Single value String

fileprivate struct Foo: ParsableCommand {
  static var configuration =
    CommandConfiguration(subcommands: [CommandA.self, CommandB.self])
  
  @Option() var name: String
}

fileprivate struct CommandA: ParsableCommand {
  static var configuration = CommandConfiguration(commandName: "a")
  
  @OptionGroup() var foo: Foo
  
  @Option() var bar: Int
}

fileprivate struct CommandB: ParsableCommand {
  static var configuration = CommandConfiguration(commandName: "b")
  
  @OptionGroup() var foo: Foo
  
  @Option() var baz: String
}

extension SubcommandEndToEndTests {
  func testParsing_SubCommand() throws {
    AssertParseCommand(Foo.self, CommandA.self, ["--name", "Foo", "a", "--bar", "42"]) { a in
      XCTAssertEqual(a.bar, 42)
      XCTAssertEqual(a.foo.name, "Foo")
    }
    
    AssertParseCommand(Foo.self, CommandB.self, ["--name", "A", "b", "--baz", "abc"]) { b in
      XCTAssertEqual(b.baz, "abc")
      XCTAssertEqual(b.foo.name, "A")
    }
  }
  
  func testParsing_SubCommand_manual() throws {
    AssertParseCommand(Foo.self, CommandA.self, ["--name", "Foo", "a", "--bar", "42"]) { a in
      XCTAssertEqual(a.bar, 42)
      XCTAssertEqual(a.foo.name, "Foo")
    }
    
    AssertParseCommand(Foo.self, Foo.self, ["--name", "Foo"]) { foo in
      XCTAssertEqual(foo.name, "Foo")
    }
  }
  
  func testParsing_SubCommand_help() throws {
    let helpFoo = Foo.message(for: CleanExit.helpRequest())
    let helpA = Foo.message(for: CleanExit.helpRequest(CommandA.self))
    let helpB = Foo.message(for: CleanExit.helpRequest(CommandB.self))
    
    AssertEqualStringsIgnoringTrailingWhitespace("""
            USAGE: foo --name <name> <subcommand>

            OPTIONS:
              --name <name>
              -h, --help              Show help information.

            SUBCOMMANDS:
              a
              b

            """, helpFoo)
    AssertEqualStringsIgnoringTrailingWhitespace("""
            USAGE: foo a --name <name> --bar <bar>

            OPTIONS:
              --name <name>
              --bar <bar>
              -h, --help              Show help information.

            """, helpA)
    AssertEqualStringsIgnoringTrailingWhitespace("""
            USAGE: foo b --name <name> --baz <baz>

            OPTIONS:
              --name <name>
              --baz <baz>
              -h, --help              Show help information.

            """, helpB)
  }
  
  
  func testParsing_SubCommand_fails() throws {
    XCTAssertThrowsError(try Foo.parse(["--name", "Foo", "a", "--baz", "42"]), "'baz' is not an option for the 'a' subcommand.")
    XCTAssertThrowsError(try Foo.parse(["--name", "Foo", "b", "--bar", "42"]), "'bar' is not an option for the 'b' subcommand.")
  }
}

fileprivate var mathDidRun = false

fileprivate struct Math: ParsableCommand {
  enum Operation: String, ExpressibleByArgument {
    case add
    case multiply
  }
  
  @Option(default: .add, help: "The operation to perform")
  var operation: Operation
  
  @Flag(name: [.short, .long])
  var verbose: Bool
  
  @Argument(help: "The first operand")
  var operands: [Int]
  
  func run() {
    XCTAssertEqual(operation, .multiply)
    XCTAssertTrue(verbose)
    XCTAssertEqual(operands, [5, 11])
    mathDidRun = true
  }
}

extension SubcommandEndToEndTests {
  func testParsing_SingleCommand() throws {
    let mathCommand = try Math.parseAsRoot(["--operation", "multiply", "-v", "5", "11"])
    XCTAssertFalse(mathDidRun)
    try mathCommand.run()
    XCTAssertTrue(mathDidRun)
  }
}

