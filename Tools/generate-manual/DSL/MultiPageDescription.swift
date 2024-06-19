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
        if case let .staticText(text) = discussion {
          text
        } else if case let .enumerated(preamble, values) = discussion {
          if let preamble {
            preamble
          }
          for value in values {
            MDocMacro.ListItem(title: value.value)
            value.description
          }
        }
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
            if case let .staticText(text) = discussion {
              text
            } else if case let .enumerated(preamble, values) = discussion {
              if let preamble {
                preamble
              }
              List {
                for value in values {
                  MDocMacro.ListItem(title: value.value)
                  value.description
                }
              }
            }
          }
        }
      }
    }
  }
}
