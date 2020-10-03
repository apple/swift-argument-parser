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

struct CustomCommand: ParsableCommand {
  var commandPath: AbsolutePath
  var arguments: [String]
  
  func run() throws {
    try exec(path: commandPath.pathString, args: arguments)
  }
}

extension CustomCommand {
  /// CustomCommand does not confirm Decodable
  init(from decoder: Decoder) {
    fatalError("CustomCommand does not confirm Decodable")
  }
}

extension CustomCommand {
  init() {
    fatalError("CustomCommand can't initialize")
  }
}

extension CustomCommand {
  init?(commandName: String, arguments: [String]) {
    guard let path = Process.findExecutable(commandName),
          localFileSystem.exists(path) else {
      return nil
    }
    self.commandPath = path
    self.arguments = arguments
  }
}
