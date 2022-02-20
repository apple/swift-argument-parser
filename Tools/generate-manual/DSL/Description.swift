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

struct Description: MDocComponent {
  var multipage: Bool
  var command: CommandInfoV0

  var body: MDocComponent {
    Section(title: "description") {
      core
    }
  }

  @MDocBuilder
  var core: MDocComponent {
    if let discussion = command.discussion {
      discussion
    }

    if command.discussion != nil, command.supplementalDiscussion != nil {
      MDocMacro.ParagraphBreak()
    }

    if let supplementalDiscussion = command.supplementalDiscussion {
      supplementalDiscussion
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

        if argument.discussion != nil, argument.supplementalDiscussion != nil {
          MDocMacro.ParagraphBreak()
        }

        if let supplementalDiscussion = argument.supplementalDiscussion {
          supplementalDiscussion
        }
      }

      if !multipage {
        for subcommand in command.subcommands ?? [] {
          MDocMacro.ListItem(title: MDocMacro.Emphasis(arguments: [subcommand.commandName]))
          Description(
            multipage: multipage,
            command: subcommand).core
        }
      }
    }
  }
}
