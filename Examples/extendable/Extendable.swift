//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import ArgumentParser

// Build this with `swift build`, then you can run the executable in
// `.build/debug/` in these ways:
//
// $ extendable -h
// USAGE: extendable <subcommand>
//
// OPTIONS:
//   -h, --help              Show help information.
//
// SUBCOMMANDS:
//   concrete
//   extension (default)
//
//   See 'extendable help <subcommand>' for detailed help.
//
// $ extendable concrete --verbose
// Running a concrete command - verbose: true
//
// $ extendable my-plugin arg1 arg2 --flag1
// Running extension command named: my-plugin
// Arguments:
//    arg1
//    arg2
//    --flag1
//
// $ extendable my-plugin --help
// Running extension command named: my-plugin
// Arguments:
//    --help
//
// $ extendable --extension-option Hello my-plugin arg1 arg2
// Running extension command named: my-plugin
// Arguments:
//    arg1
//    arg2
// Extension option: Hello

@main
struct Extendable: ParsableCommand {
    static var configuration = CommandConfiguration(
        subcommands: [Concrete.self, Extension.self],
        defaultSubcommand: Extension.self)
}

struct Concrete: ParsableCommand {
    @Flag var verbose = false
    
    func run() throws {
        print("Running a concrete command - verbose: \(verbose)")
    }
}

struct Extension: ParsableCommand {
    @Argument
    var extensionName: String
    
    @Argument(parsing: .captureForPassthrough)
    var arguments: [String]
  
    @Option
    var extensionOption: String?
    
    func run() throws {
        print("""
            Running extension command named: \(extensionName)
            Arguments:
            \(arguments.map { "   " + $0 }.joined(separator: "\n"))
            """)
        if let extensionOption {
            print("Extension option: \(extensionOption)")
        }
    }
}
