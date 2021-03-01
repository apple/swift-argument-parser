//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import ArgumentParser
import ArgumentParserToolInfo
import Foundation

struct Document: MDocComponent {
  var singlePage: Bool
  var date: Date
  var section: Int
  var authors: [AuthorArgument]
  var command: CommandInfoV0

  var body: MDocComponent {
    Preamble(date: date, section: section, command: command)
    Name(command: command)
    Synopsis(command: command)
    if singlePage {
      SinglePageDescription(command: command)
    } else {
      MultiPageDescription(command: command)
    }
    Exit(section: section)
    if !singlePage {
      SeeAlso(section: section, command: command)
    }
    Authors(authors: authors)
  }
}
