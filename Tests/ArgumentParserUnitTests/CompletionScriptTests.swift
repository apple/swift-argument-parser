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
@testable import ArgumentParser

final class CompletionScriptTests: XCTestCase {
}

extension CompletionScriptTests {
  struct Path: ExpressibleByArgument {
    var path: String
    
    init?(argument: String) {
      self.path = argument
    }
    
    static var defaultCompletionKind: CompletionKind {
      .file()
    }
  }
    
  enum Kind: String, ExpressibleByArgument, EnumerableFlag {
    case one, two, three = "custom-three"
  }
  
  struct NestedArguments: ParsableArguments {
    @Argument(completion: .custom { _ in ["t", "u", "v"] })
    var nestedArgument: String
  }
  
  struct Base: ParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "base-test",
      subcommands: [SubCommand.self]
    )

    @Option(help: "The user's name.") var name: String
    @Option() var kind: Kind
    @Option(completion: .list(["1", "2", "3"])) var otherKind: Kind
    
    @Option() var path1: Path
    @Option() var path2: Path?
    @Option(completion: .list(["a", "b", "c"])) var path3: Path
    
    @Flag(help: .hidden) var verbose = false
    @Flag var allowedKinds: [Kind] = []
    @Flag var kindCounter: Int
    
    @Option() var rep1: [String]
    @Option(name: [.short, .long]) var rep2: [String]
    
    @Argument(completion: .custom { _ in ["q", "r", "s"] }) var argument: String
    @OptionGroup var nested: NestedArguments
    
    struct SubCommand: ParsableCommand {
      static let configuration = CommandConfiguration(
        commandName: "sub-command"
      )
    }
  }

  func testBase_Zsh() throws {
    let script1 = try CompletionsGenerator(command: Base.self, shell: .zsh)
          .generateCompletionScript()
    try assertSnapshot(actual: script1, extension: "zsh")

    let script2 = try CompletionsGenerator(command: Base.self, shellName: "zsh")
          .generateCompletionScript()
    try assertSnapshot(actual: script2, extension: "zsh")

    let script3 = Base.completionScript(for: .zsh)
    try assertSnapshot(actual: script3, extension: "zsh")
  }

  func testBase_Bash() throws {
    let script1 = try CompletionsGenerator(command: Base.self, shell: .bash)
          .generateCompletionScript()
    try assertSnapshot(actual: script1, extension: "bash")

    let script2 = try CompletionsGenerator(command: Base.self, shellName: "bash")
          .generateCompletionScript()
    try assertSnapshot(actual: script2, extension: "bash")

    let script3 = Base.completionScript(for: .bash)
    try assertSnapshot(actual: script3, extension: "bash")
  }

  func testBase_Fish() throws {
    let script1 = try CompletionsGenerator(command: Base.self, shell: .fish)
          .generateCompletionScript()
    try assertSnapshot(actual: script1, extension: "fish")

    let script2 = try CompletionsGenerator(command: Base.self, shellName: "fish")
          .generateCompletionScript()
    try assertSnapshot(actual: script2, extension: "fish")

    let script3 = Base.completionScript(for: .fish)
    try assertSnapshot(actual: script3, extension: "fish")
  }
}

extension CompletionScriptTests {
  struct Custom: ParsableCommand {
    @Option(name: .shortAndLong, completion: .custom { _ in ["a", "b", "c"] })
    var one: String

    @Argument(completion: .custom { _ in ["d", "e", "f"] })
    var two: String

    @Option(name: .customShort("z"), completion: .custom { _ in ["x", "y", "z"] })
    var three: String
    
    @OptionGroup var nested: NestedArguments
    
    struct NestedArguments: ParsableArguments {
      @Argument(completion: .custom { _ in ["g", "h", "i"] })
      var four: String
    }
  }
  
  func verifyCustomOutput(
    _ arg: String,
    expectedOutput: String,
    file: StaticString = #filePath, line: UInt = #line
  ) throws {
    do {
      _ = try Custom.parse(["---completion", "--", arg])
      XCTFail("Didn't error as expected", file: (file), line: line)
    } catch let error as CommandError {
      guard case .completionScriptCustomResponse(let output) = error.parserError else {
        throw error
      }
      XCTAssertEqual(expectedOutput, output, file: (file), line: line)
    }
  }
  
  func testCustomCompletions() throws {
    try verifyCustomOutput("-o", expectedOutput: "a\nb\nc")
    try verifyCustomOutput("--one", expectedOutput: "a\nb\nc")
    try verifyCustomOutput("two", expectedOutput: "d\ne\nf")
    try verifyCustomOutput("-z", expectedOutput: "x\ny\nz")
    try verifyCustomOutput("nested.four", expectedOutput: "g\nh\ni")
    
    XCTAssertThrowsError(try verifyCustomOutput("--bad", expectedOutput: ""))
    XCTAssertThrowsError(try verifyCustomOutput("four", expectedOutput: ""))
  }
}

extension CompletionScriptTests {
  struct EscapedCommand: ParsableCommand {
    @Option(help: #"Escaped chars: '[]\."#)
    var one: String
    
    @Argument(completion: .custom { _ in ["d", "e", "f"] })
    var two: String
  }

  func testEscaped_Zsh() throws {
    let script1 = EscapedCommand.completionScript(for: .zsh)
    try assertSnapshot(actual: script1, extension: "zsh")
  }
}

// MARK: - Test Hidden Subcommand
struct Parent: ParsableCommand {
    static let configuration = CommandConfiguration(subcommands: [HiddenChild.self])
}

struct HiddenChild: ParsableCommand {
    static let configuration = CommandConfiguration(shouldDisplay: false)
}

extension CompletionScriptTests {
  func testHiddenSubcommand_Zsh() throws {
    let script1 = try CompletionsGenerator(command: Parent.self, shell: .zsh)
          .generateCompletionScript()
    try assertSnapshot(actual: script1, extension: "zsh")

    let script2 = try CompletionsGenerator(command: Parent.self, shellName: "zsh")
          .generateCompletionScript()
    try assertSnapshot(actual: script2, extension: "zsh")

    let script3 = Parent.completionScript(for: .zsh)
    try assertSnapshot(actual: script3, extension: "zsh")
  }

  func testHiddenSubcommand_Bash() throws {
    let script1 = try CompletionsGenerator(command: Parent.self, shell: .bash)
          .generateCompletionScript()
    try assertSnapshot(actual: script1, extension: "bash")

    let script2 = try CompletionsGenerator(command: Parent.self, shellName: "bash")
          .generateCompletionScript()
    try assertSnapshot(actual: script2, extension: "bash")

    let script3 = Parent.completionScript(for: .bash)
    try assertSnapshot(actual: script3, extension: "bash")
  }

  func testHiddenSubcommand_Fish() throws {
    let script1 = try CompletionsGenerator(command: Parent.self, shell: .fish)
          .generateCompletionScript()
    try assertSnapshot(actual: script1, extension: "fish")

    let script2 = try CompletionsGenerator(command: Parent.self, shellName: "fish")
          .generateCompletionScript()
    try assertSnapshot(actual: script2, extension: "fish")

    let script3 = Parent.completionScript(for: .fish)
    try assertSnapshot(actual: script3, extension: "fish")
  }
}
