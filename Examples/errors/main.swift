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

import Foundation
import ArgumentParser

enum MyCustomNSError: CustomNSError {
  case myFirstCase
  case mySecondCase

  var errorCode: Int {
    switch self {
    case .myFirstCase:
      return 101
    case .mySecondCase:
      return 102
    }
  }

  var errorUserInfo: [String : Any] {
    switch self {
    case .myFirstCase:
      return [NSLocalizedDescriptionKey: "My first case localized description"]
    case .mySecondCase:
      return [:]
    }
  }
}

struct CheckFirstCustomNSErrorCommand: ParsableCommand {

  @Option
  var errorCase: Int

  func run() throws {
    switch errorCase {
    case 101:
      throw MyCustomNSError.myFirstCase
    default:
      throw MyCustomNSError.mySecondCase
    }
  }
}

CheckFirstCustomNSErrorCommand.main()
