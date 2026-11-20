//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// A validator for the ordering of optional and required positional arguments.
struct OptionalPositionalArgumentsValidator: ParsableArgumentsValidator {
  struct Error: ParsableArgumentsValidatorError, CustomStringConvertible {
    let optionalPositionalArgument: String
    let requiredPositionalArgument: String

    var description: String {
      """
      Can't have a required positional argument \
      `\(requiredPositionalArgument)` following an optional positional \
      argument `\(optionalPositionalArgument)`.
      """
    }

    var kind: ValidatorErrorKind { .failure }
  }

  static func validate(
    _ type: ParsableArguments.Type, parent: InputKey?
  ) -> ParsableArgumentsValidatorError? {
    let arguments: [ArgumentDefinition] = Mirror(reflecting: type.init())
      .children
      .compactMap { child -> ArgumentSet? in
        guard
          let codingKey = child.label,
          let parsed = child.value as? ArgumentSetProvider
        else { return nil }

        let key = InputKey(name: codingKey, parent: parent)
        return parsed.argumentSet(for: key)
      }
      .flatMap { $0.content }
      .filter { $0.isPositional }

    var optionalArgument: ArgumentDefinition?
    for argument in arguments {
      if argument.help.options.contains(.isOptional) {
        optionalArgument = optionalArgument ?? argument
      } else if let optionalArgument {
        // swift-format-ignore: NeverForceUnwrap
        return Error(
          optionalPositionalArgument: optionalArgument.help.keys.first!.name,
          requiredPositionalArgument: argument.help.keys.first!.name)
      }
    }
    return nil
  }
}
