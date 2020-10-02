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
  var commandName: String
  var arguments: [String]
  var parserError: ParserError
  
  func run() throws {
    guard let path = Process.findExecutable(commandName),
          localFileSystem.exists(path) else {
      throw parserError
    }
    try exec(path: path.pathString, args: arguments)
  }
}

extension CustomCommand {
  /// CustomCommand does not confirm Decodable
  /// - Throws: ValidationError
  init(from decoder: Decoder) throws {
    throw ValidationError("UserCustomCommand does not confirm Decodable")
  }
}

extension CustomCommand {
  init() {
    commandName = ""
    arguments = []
    parserError = .invalidState
  }
}
