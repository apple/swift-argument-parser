//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// A validator that ensures the subcommands of a `ParsableCommand` have
/// unique names, including their aliases.
struct UniqueSubcommandNamesValidator: ParsableArgumentsValidator {
  struct Error: ParsableArgumentsValidatorError, CustomStringConvertible {
    var duplicateNames: [(name: String, count: Int)] = []

    var description: String {
      duplicateNames.map { entry in
        """
        Multiple (\(entry.count)) subcommands are named or aliased \
        "\(entry.name)".
        """
      }.joined(separator: "\n")
    }

    var kind: ValidatorErrorKind { .failure }
  }

  static func validate(_ type: ParsableArguments.Type, parent: InputKey?)
    -> ParsableArgumentsValidatorError?
  {
    guard let command = type as? ParsableCommand.Type else { return nil }

    var orderedNames: [String] = []
    var countedNames: [String: Int] = [:]
    for subcommand in command.configuration.subcommands {
      // Deduplicate within a single subcommand so that an alias repeating
      // the command's own name isn't reported here.
      var seen: Set<String> = []
      let names = [subcommand._commandName] + subcommand.configuration.aliases
      for name in names where seen.insert(name).inserted {
        if countedNames[name] == nil { orderedNames.append(name) }
        countedNames[name, default: 0] += 1
      }
    }

    let duplicateNames = orderedNames.compactMap { name in
      countedNames[name].flatMap { $0 > 1 ? (name, $0) : nil }
    }
    return duplicateNames.isEmpty
      ? nil
      : Error(duplicateNames: duplicateNames)
  }
}
