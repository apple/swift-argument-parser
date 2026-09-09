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

@Suite struct GenerateManualTests {
  #if os(macOS)
  @Test func countLinesSinglePageManual() throws {
    guard #available(macOS 12, *) else { return }
    try expectGenerateManual(multiPage: false, command: "count-lines")
  }

  @Test func countLinesMultiPageManual() throws {
    guard #available(macOS 12, *) else { return }
    try expectGenerateManual(multiPage: true, command: "count-lines")
  }
  #endif

  @Test func colorSinglePageManual() throws {
    try expectGenerateManual(multiPage: false, command: "color")
  }

  @Test func colorMultiPageManual() throws {
    try expectGenerateManual(multiPage: true, command: "color")
  }

  @Test func mathSinglePageManual() throws {
    try expectGenerateManual(multiPage: false, command: "math")
  }

  @Test func mathMultiPageManual() throws {
    try expectGenerateManual(multiPage: true, command: "math")
  }

  @Test func repeatSinglePageManual() throws {
    try expectGenerateManual(multiPage: false, command: "repeat")
  }

  @Test func repeatMultiPageManual() throws {
    try expectGenerateManual(multiPage: true, command: "repeat")
  }

  @Test func rollSinglePageManual() throws {
    try expectGenerateManual(multiPage: false, command: "roll")
  }

  @Test func rollMultiPageManual() throws {
    try expectGenerateManual(multiPage: true, command: "roll")
  }

  @Test func defaultAsFlagSinglePageManual() throws {
    try expectGenerateManual(multiPage: false, command: "default-as-flag")
  }

  @Test func defaultAsFlagMultiPageManual() throws {
    try expectGenerateManual(multiPage: true, command: "default-as-flag")
  }
}
