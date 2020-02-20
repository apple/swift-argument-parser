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

import ArgumentParser

struct Options: ParsableArguments {
  @Option(default: "./.build", help: "Specify build/cache directory")
  var buildPath: String
  
  enum Configuration: String, ExpressibleByArgument, Decodable {
    case debug
    case release
  }
  
  @Option(name: .shortAndLong, default: .debug,
          help: "Build with configuration")
  var configuration: Configuration
  
  @Flag(default: true, inversion: .prefixedEnableDisable,
        help: "Use automatic resolution if Package.resolved file is out-of-date")
  var automaticResolution: Bool
  
  @Flag(default: true, inversion: .prefixedEnableDisable,
        help: "Use indexing-while-building feature")
  var indexStore: Bool
  
  @Flag(default: true, inversion: .prefixedEnableDisable,
        help: "Cache Package.swift manifests")
  var packageManifestCaching: Bool
  
  @Flag(default: true, inversion: .prefixedEnableDisable)
  var prefetching: Bool
  
  @Flag(default: true, inversion: .prefixedEnableDisable,
        help: "Use sandbox when executing subprocesses")
  var sandbox: Bool
  
  @Flag(inversion: .prefixedEnableDisable,
        help: "[Experimental] Enable the new Pubgrub dependency resolver")
  var pubgrubResolver: Bool
  
  @Flag(inversion: .prefixedNo,
        help: "Link Swift stdlib statically")
  var staticSwiftStdlib: Bool
  
  @Option(default: ".",
          help: "Change working directory before any other operation")
  var packagePath: String
  
  @Flag(help: "Turn on runtime checks for erroneous behavior")
  var sanitize: Bool
  
  @Flag(help: "Skip updating dependencies from their remote during a resolution")
  var skipUpdate: Bool
  
  @Flag(name: .shortAndLong,
        help: "Increase verbosity of informational output")
  var verbose: Bool
  
  @Option(name: .customLong("Xcc", withSingleDash: true),
          parsing: .unconditionalSingleValue,
          help: ArgumentHelp("Pass flag through to all C compiler invocations",
                             valueName: "c-compiler-flag"))
  var cCompilerFlags: [String]
  
  @Option(name: .customLong("Xcxx", withSingleDash: true),
          parsing: .unconditionalSingleValue,
          help: ArgumentHelp("Pass flag through to all C++ compiler invocations",
                             valueName: "cxx-compiler-flag"))
  var cxxCompilerFlags: [String]
  
  @Option(name: .customLong("Xlinker", withSingleDash: true),
          parsing: .unconditionalSingleValue,
          help: ArgumentHelp("Pass flag through to all linker invocations",
                             valueName: "linker-flag"))
  var linkerFlags: [String]
  
  @Option(name: .customLong("Xswiftc", withSingleDash: true),
          parsing: .unconditionalSingleValue,
          help: ArgumentHelp("Pass flag through to all Swift compiler invocations",
                             valueName: "swift-compiler-flag"))
  var swiftCompilerFlags: [String]
}

struct Package: ParsableCommand {
  static var configuration = CommandConfiguration(
    subcommands: [Clean.self, Config.self, Describe.self, GenerateXcodeProject.self, Hidden.self])
}

extension Package {
  struct Hidden: ParsableCommand {
    static var configuration = CommandConfiguration(shouldDisplay: false)
  }
}
