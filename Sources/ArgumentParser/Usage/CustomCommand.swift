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

import TSCBasic

/// CustomCommand is for calling other executables.
struct CustomCommand: ParsableCommand {
  var commandPath: AbsolutePath
  var arguments: [String]
  
  func run() throws {
    try exec(path: commandPath.pathString, args: arguments)
  }
}

extension CustomCommand {
  /// **NOT SUPPORTED**
  init(from decoder: Decoder) {
    fatalError("CustomCommand does not confirm Decodable")
  }
  
  /// **NOT SUPPORTED**
  init() {
    fatalError("CustomCommand can't initialize")
  }
}

extension CustomCommand {
  /// Find executable command's path and if it not exist, return nil.
  /// - Parameters:
  ///   - commandName: command name to call
  ///   - arguments: arguments to provide to the command
  init?(commandName: String, arguments: [String]) {
    guard let path = Process.findExecutable(commandName),
          localFileSystem.exists(path) else {
      return nil
    }
    self.commandPath = path
    self.arguments = arguments
  }
}
