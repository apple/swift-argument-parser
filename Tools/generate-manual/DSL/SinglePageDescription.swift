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

struct SinglePageDescription: MDocComponent {
  var command: CommandInfoV0
  var root: Bool

  var body: MDocComponent {
    Section(title: "description") {
      core
    }
  }

  @MDocBuilder
  var core: MDocComponent {
    if !root, let abstract = command.abstract {
      abstract
    }

    if !root, command.abstract != nil, command.discussion2 != nil {
      MDocMacro.ParagraphBreak()
    }

    if let discussion = command.discussion2 {
      DiscussionText(discussion: discussion)
    }

    List {
      for argument in command.arguments ?? [] {
        if argument.shouldDisplay {
          MDocMacro.ListItem(title: argument.manualPageDescription)

          if let abstract = argument.abstract {
            abstract
          }

          if argument.abstract != nil, argument.discussion2 != nil {
            MDocMacro.ParagraphBreak()
          }

          if let discussion = argument.discussion2 {
            DiscussionText(discussion: discussion)
          }
        }
      }

      for subcommand in command.subcommands ?? [] {
        MDocMacro.ListItem(title: MDocMacro.Emphasis(arguments: [subcommand.commandName]))
        SinglePageDescription(command: subcommand, root: false).core
      }
    }
  }
}
