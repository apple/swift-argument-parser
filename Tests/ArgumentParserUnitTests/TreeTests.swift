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

import Testing

@testable import ArgumentParser

@Suite struct TreeTests {}

// MARK: -

func generateTree() -> Tree<Int> {
  let tree = Tree(1)
  for x in 11...13 {
    let node = Tree(x)
    tree.addChild(node)
    for y in 1...3 {
      let subnode = Tree(x * 10 + y)
      node.addChild(subnode)
    }
  }
  return tree
}

extension TreeTests {
  @Test func hierarchy() {
    let tree = generateTree()
    #expect(tree.element == 1)
    #expect(tree.children.map { $0.element } == [11, 12, 13])
    #expect(
      tree.children.flatMap { $0.children.map { $0.element } }
        == [111, 112, 113, 121, 122, 123, 131, 132, 133])
  }

  @Test func search() {
    let tree = generateTree()
    #expect(
      tree.path(toFirstWhere: { $0 == 1 }).map { $0.element } == [1])
    #expect(
      tree.path(toFirstWhere: { $0 == 13 }).map { $0.element } == [1, 13])
    #expect(
      tree.path(toFirstWhere: { $0 == 133 }).map { $0.element }
        == [1, 13, 133])

    #expect(tree.path(toFirstWhere: { $0 < 0 }).isEmpty)
  }
}

extension TreeTests {
  struct A: ParsableCommand {
    static let configuration = CommandConfiguration(subcommands: [A.self])
  }
  struct Root: ParsableCommand {
    static let configuration = CommandConfiguration(subcommands: [Sub.self])
  }
  struct Sub: ParsableCommand {
    static let configuration = CommandConfiguration(subcommands: [Sub.self])
  }

  struct RootWithNamedNestedSub: ParsableCommand {
    static let configuration = CommandConfiguration(subcommands: [
      NestedSub.self
    ])

    struct NestedSub: ParsableCommand {
      static let configuration = CommandConfiguration(
        commandName: "sub", aliases: ["sub"])
    }
  }

  struct RootWithNestedSub: ParsableCommand {
    static let configuration = CommandConfiguration(subcommands: [
      NestedSub.self
    ])

    struct NestedSub: ParsableCommand {
      static let configuration = CommandConfiguration(aliases: ["nested-sub"])
    }
  }

  @Test func initializationWithRecursiveSubcommand() {
    #expect(throws: (any Error).self) { try Tree(root: A.asCommand) }
    #expect(throws: (any Error).self) { try Tree(root: Root.asCommand) }
  }

  @Test func initializationWithMatchingAliases() {
    #expect(throws: (any Error).self) {
      try Tree(root: RootWithNamedNestedSub.asCommand)
    }
    #expect(throws: (any Error).self) {
      try Tree(root: RootWithNestedSub.asCommand)
    }
  }
}
