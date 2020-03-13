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
@testable import ArgumentParser

final class UsageGenerationTests: XCTestCase {
}

// MARK: -

extension UsageGenerationTests {
  func testNameSynopsis() {
    XCTAssertEqual(Name.long("foo").synopsisString, "--foo")
    XCTAssertEqual(Name.short("f").synopsisString, "-f")
    XCTAssertEqual(Name.longWithSingleDash("foo").synopsisString, "-foo")
  }
}

extension UsageGenerationTests {
  struct A: ParsableArguments {
    @Option() var firstName: String
    @Option() var title: String
  }
  
  func testSynopsis() {
    let help = UsageGenerator(toolName: "bar", parsable: A())
    XCTAssertEqual(help.synopsis, "bar --first-name <first-name> --title <title>")
  }
  
  struct B: ParsableArguments {
    @Option() var firstName: String?
    @Option() var title: String?
  }
  
  func testSynopsisWithOptional() {
    let help = UsageGenerator(toolName: "bar", parsable: B())
    XCTAssertEqual(help.synopsis, "bar [--first-name <first-name>] [--title <title>]")
  }
  
  struct C: ParsableArguments {
    @Flag() var log: Bool
    @Flag() var verbose: Int
  }
  
  func testFlagSynopsis() {
    let help = UsageGenerator(toolName: "bar", parsable: C())
    XCTAssertEqual(help.synopsis, "bar [--log] [--verbose ...]")
  }
  
  struct D: ParsableArguments {
    @Argument() var firstName: String
    @Argument() var title: String?
  }
  
  func testPositionalSynopsis() {
    let help = UsageGenerator(toolName: "bar", parsable: D())
    XCTAssertEqual(help.synopsis, "bar <first-name> [<title>]")
  }
  
  struct E: ParsableArguments {
    @Option(default: "no-name")
    var name: String
    
    @Option(default: 0)
    var count: Int

    @Argument(default: "no-arg")
    var arg: String
  }
  
  func testSynopsisWithDefaults() {
    let help = UsageGenerator(toolName: "bar", parsable: E())
    XCTAssertEqual(help.synopsis, "bar [--name <name>] [--count <count>] [<arg>]")
  }
  
  struct F: ParsableArguments {
    @Option() var name: [String]
    @Argument() var nameCounts: [Int]
  }
  
  func testSynopsisWithRepeats() {
    let help = UsageGenerator(toolName: "bar", parsable: F())
    XCTAssertEqual(help.synopsis, "bar [--name <name> ...] [<name-counts> ...]")
  }
  
  struct G: ParsableArguments {
    @Option(help: ArgumentHelp(valueName: "path"))
    var filePath: String?
    
    @Argument(help: ArgumentHelp(valueName: "user-home-path"))
    var homePath: String
  }
  
  func testSynopsisWithCustomization() {
    let help = UsageGenerator(toolName: "bar", parsable: G())
    XCTAssertEqual(help.synopsis, "bar [--file-path <path>] <user-home-path>")
  }
  
  struct H: ParsableArguments {
    @Option(help: .hidden) var firstName: String?
    @Argument(help: .hidden) var title: String?
  }
  
  func testSynopsisWithHidden() {
    let help = UsageGenerator(toolName: "bar", parsable: H())
    XCTAssertEqual(help.synopsis, "bar")
  }

  struct I: ParsableArguments {
    enum Color {
        case red, blue
        static func transform(_ string: String) throws -> Color {
          switch string {
          case "red":
            return .red
          case "blue":
            return .blue
          default:
            throw ValidationError("Not a valid string for 'Color'")
          }
        }
    }

    @Option(default: .red, transform: Color.transform)
    var color: Color
  }

  func testSynopsisWithDefaultValueAndTransform() {
    let help = UsageGenerator(toolName: "bar", parsable: I())
    XCTAssertEqual(help.synopsis, "bar [--color <color>]")
  }
}
