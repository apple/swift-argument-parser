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

import ArgumentParserTestHelpers
import Testing

@testable import ArgumentParser

@Suite struct Tests {
  init() {
    Platform.Environment[.columns] = nil
  }
}

// https://github.com/apple/swift-argument-parser/issues/710
extension Tests {
  @Test func parsing() throws {
    expectParseCommand(Package.self, Package.Clean.self, ["clean"]) { clean in
      let options = clean.options
      #expect(options.buildPath == "./.build")
      #expect(options.configuration == .debug)
      #expect(options.automaticResolution == true)
      #expect(options.indexStore == true)
      #expect(options.packageManifestCaching == true)
      #expect(options.prefetching == true)
      #expect(options.sandbox == true)
      #expect(options.pubgrubResolver == false)
      #expect(options.staticSwiftStdlib == false)
      #expect(options.packagePath == ".")
      #expect(options.sanitize == false)
      #expect(options.skipUpdate == false)
      #expect(options.verbose == false)
      #expect(options.cCompilerFlags == [])
      #expect(options.cxxCompilerFlags == [])
      #expect(options.linkerFlags == [])
      #expect(options.swiftCompilerFlags == [])
    }
  }

  @Test func parsingWithGlobalOption_1() {
    expectParseCommand(
      Package.self, Package.GenerateXcodeProject.self,
      [
        "generate-xcodeproj", "--watch", "--output", "Foo",
        "--enable-automatic-resolution",
      ]
    ) { generate in
      #expect(generate.output == "Foo")
      #expect(!generate.enableCodeCoverage)
      #expect(generate.watch)

      let options = generate.options
      // Default global option
      #expect(options.configuration == .debug)
      // Customized global option
      #expect(options.automaticResolution == true)
    }
  }

  @Test func parsingWithGlobalOption_2() {
    expectParseCommand(
      Package.self, Package.GenerateXcodeProject.self,
      [
        "generate-xcodeproj", "--watch", "--output", "Foo",
        "--enable-automatic-resolution", "-Xcc", "-Ddebug",
      ]
    ) { generate in
      #expect(generate.output == "Foo")
      #expect(!generate.enableCodeCoverage)
      #expect(generate.watch)

      let options = generate.options
      // Default global option
      #expect(options.configuration == .debug)
      // Customized global option
      #expect(options.automaticResolution == true)
      #expect(options.cCompilerFlags == ["-Ddebug"])
    }
  }

  @Test func parsingWithGlobalOption_3() {
    expectParseCommand(
      Package.self, Package.GenerateXcodeProject.self,
      [
        "generate-xcodeproj", "--watch", "--output=Foo",
        "--enable-automatic-resolution", "-Xcc=-Ddebug",
      ]
    ) { generate in
      #expect(generate.output == "Foo")
      #expect(!generate.enableCodeCoverage)
      #expect(generate.watch)

      let options = generate.options
      // Default global option
      #expect(options.configuration == .debug)
      // Customized global option
      #expect(options.automaticResolution == true)
      #expect(options.cCompilerFlags == ["-Ddebug"])
    }
  }
}
