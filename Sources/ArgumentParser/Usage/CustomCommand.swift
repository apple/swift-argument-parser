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

struct UserCustomCommand: ParsableCommand {
  var commandName: String
  var arguments: [String]
  var parserError: ParserError
  
  func run() throws {
    print(commandName, "is called")
  }
}

extension UserCustomCommand {
  /// UserCustomCommand does not confirm Decodable
  /// - Throws: ValidationError
  init(from decoder: Decoder) throws {
    throw ValidationError("UserCustomCommand does not confirm Decodable")
  }
}

extension UserCustomCommand {
  init() {
    commandName = ""
    arguments = []
    parserError = .invalidState
  }
}
