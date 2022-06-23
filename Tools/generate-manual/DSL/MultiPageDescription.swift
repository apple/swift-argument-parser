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

struct MultiPageDescription: MDocComponent {
  var command: CommandInfoV0

  var body: MDocComponent {
    Section(title: "description") {
      if let discussion = command.discussion {
        discussion
      }

      List {
        for argument in command.arguments ?? [] {
          MDocMacro.ListItem(title: argument.manualPageDescription)

          if let abstract = argument.abstract {
            abstract
          }

          if argument.abstract != nil, argument.discussion != nil {
            MDocMacro.ParagraphBreak()
          }

          if let discussion = argument.discussion {
            discussion
          }
        }
      }
    }
  }
}
