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

#if canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#elseif canImport(MSVCRT)
import MSVCRT
#endif

struct CompletionsGenerator {
  enum Shell: String, RawRepresentable, CaseIterable {
    case zsh
    case bash
    case fish
    
    static func autodetect() -> Shell? {
      guard let shellVar = getenv("SHELL") else { return nil }
      let shellParts = String(cString: shellVar).split(separator: "/")
      return Shell(rawValue: String(shellParts.last ?? ""))
    }
  }
  
  var shell: Shell
  var command: ParsableCommand.Type
  
  init(command: ParsableCommand.Type, shell str: String?) throws {
    if let str = str {
      guard let shell = Shell(rawValue: str) else {
        print("""
          Can't generate completion scripts for '\(str)'.
          Please use --generate-completions=<shell> with one of:
              \(Shell.allCases.map { $0.rawValue }.joined(separator: " "))
          """)
        throw ExitCode.failure
      }
      self.shell = shell
    } else {
      guard let shell = Shell.autodetect() else {
        print("""
          Can't autodetect a supported shell.
          Please use --generate-completions=<shell> with one of:
              \(Shell.allCases.map { $0.rawValue }.joined(separator: " "))
          """)
        throw ExitCode.failure
      }
      self.shell = shell
    }
    
    self.command = command
  }
  
  func generateCompletionScript() -> String {
    switch shell {
    case .zsh:
      return ZshCompletionsGenerator.generateCompletionScript(command)
    case .bash:
      return BashCompletionsGenerator.generateCompletionScript(command)
    case .fish:
      return FishCompletionsGenerator.generateCompletionScript(command)
    }
  }
}
