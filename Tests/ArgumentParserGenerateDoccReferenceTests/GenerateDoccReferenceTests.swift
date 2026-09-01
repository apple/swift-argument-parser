//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2024-2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import ArgumentParserTestHelpers
import Testing

@Suite struct GenerateDoccReferenceTests {
  #if os(macOS)
  @Test func countLinesMarkdownReference() throws {
    guard #available(macOS 12, *) else { return }
    try expectGeneratedReference(command: "count-lines", doccFlavored: false)
  }

  @Test func countLinesDoccReference() throws {
    guard #available(macOS 12, *) else { return }
    try expectGeneratedReference(command: "count-lines", doccFlavored: true)
  }
  #endif

  @Test func colorMarkdownReference() throws {
    try expectGeneratedReference(command: "color", doccFlavored: false)
  }
  @Test func colorDoccReference() throws {
    try expectGeneratedReference(command: "color", doccFlavored: true)
  }

  @Test func mathMarkdownReference() throws {
    try expectGeneratedReference(command: "math", doccFlavored: false)
  }
  @Test func mathDoccReference() throws {
    try expectGeneratedReference(command: "math", doccFlavored: true)
  }

  @Test func repeatMarkdownReference() throws {
    try expectGeneratedReference(command: "repeat", doccFlavored: false)
  }
  @Test func repeatDoccReference() throws {
    try expectGeneratedReference(command: "repeat", doccFlavored: true)
  }

  @Test func rollMarkdownReference() throws {
    try expectGeneratedReference(command: "roll", doccFlavored: false)
  }
  @Test func rollDoccReference() throws {
    try expectGeneratedReference(command: "roll", doccFlavored: true)
  }
}
