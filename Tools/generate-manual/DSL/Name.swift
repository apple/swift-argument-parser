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

struct Name: MDocComponent {
  var command: CommandInfoV0

  var body: MDocComponent {
    let names = [command.manualPageName] + (command.aliases ?? [])
    Section(title: "name") {
      for (index, name) in names.enumerated() {
        if index < names.count - 1 {
          MDocMacro.DocumentName(name: name)
            .withUnsafeChildren(nodes: [","])
        } else {
          MDocMacro.DocumentName(name: name)
        }
      }
      if let abstract = command.abstract {
        MDocMacro.DocumentDescription(description: abstract)
      }
    }
  }
}
