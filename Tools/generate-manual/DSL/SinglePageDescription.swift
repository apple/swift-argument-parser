//===----------------------------------------------------------------------===//
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
  /// Arguments which an enclosing command's section already documents.
  ///
  /// A single page manual nests each subcommand's arguments within its super
  /// command's list. Repeating an argument that an ancestor already describes
  /// verbatim (most notably the synthesized `--version` and `--help` flags)
  /// only adds noise, so such arguments are documented once, by the outermost
  /// command which declares them. Multi page manuals are unaffected because
  /// each command gets a self contained page.
  var inheritedArguments: Set<ArgumentInfoV0> = []

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

    if !root, command.abstract != nil, command.discussion != nil {
      MDocMacro.ParagraphBreak()
    }

    let discussion = DiscussionText(
      discussion: command.discussion,
      allValueStrings: nil,
      allValueDescriptions: nil)

    if let discussion = discussion {
      discussion
    }

    List {
      for argument in command.arguments ?? [] {
        if argument.shouldDisplay, !inheritedArguments.contains(argument) {
          MDocMacro.ListItem(title: argument.manualPageDescription)

          let discussion = DiscussionText(
            discussion: argument.discussion,
            allValueStrings: argument.allValueStrings,
            allValueDescriptions: argument.allValueDescriptions)

          if let abstract = argument.abstract {
            abstract
          }

          if argument.abstract != nil, discussion != nil {
            MDocMacro.ParagraphBreak()
          }

          if let discussion = discussion {
            discussion
          }
        }
      }

      let subcommandInheritedArguments = inheritedArguments.union(
        command.arguments ?? [])
      for subcommand in command.subcommands ?? [] {
        MDocMacro.ListItem(
          title: MDocMacro.Emphasis(
            arguments: [subcommand.manualPageSubcommandLabel]))
        SinglePageDescription(
          command: subcommand,
          root: false,
          inheritedArguments: subcommandInheritedArguments
        ).core
      }
    }
  }
}
