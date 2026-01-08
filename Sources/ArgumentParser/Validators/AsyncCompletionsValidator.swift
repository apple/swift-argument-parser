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

/// A validator that ensures async custom completion functions are used only for
/// `AsyncParsableCommand`s.
@available(macOS 10.15, macCatalyst 13, iOS 13, tvOS 13, watchOS 6, *)
struct AsyncCompletionsValidator: ParsableArgumentsValidator {
  struct Error: ParsableArgumentsValidatorError, CustomStringConvertible {
    var invalidAsyncCompletions: [String] = []

    var description: String {
      """
      The following properties of synchronous ParsableCommands have \
      asynchronous custom completion functions:

      \(invalidAsyncCompletions.joined(separator: "\n"))

      Fix this by either:

       - conforming to AsyncParsableCommand
       - using synchronous custom completion functions
      """
    }

    var kind: ValidatorErrorKind { .failure }
  }

  static func validate(_ type: ParsableArguments.Type, parent: InputKey?)
    -> ParsableArgumentsValidatorError?
  {
    guard
      type is ParsableCommand.Type,
      !(type is AsyncParsableCommand.Type)
    else { return nil }

    let invalidAsyncCompletions = type.invalidAsyncCompletions(
      parent: parent,
      propertyPath: String(describing: type)
    )

    return invalidAsyncCompletions.isEmpty
      ? nil
      : Error(invalidAsyncCompletions: invalidAsyncCompletions)
  }
}

private protocol AnyOptionGroup {
  static var wrappedType: ParsableArguments.Type { get }
}

extension OptionGroup: AnyOptionGroup {
  static var wrappedType: ParsableArguments.Type { Value.self }
}

extension ParsableArguments {
  static func invalidAsyncCompletions(
    parent: InputKey?,
    propertyPath: String
  ) -> [String] {
    Mirror(reflecting: self.init())
      .children
      .flatMap { child in
        child.label
          .map { $0.hasPrefix("_") ? String($0.dropFirst()) : $0 }
          .flatMap { label in
            (type(of: child.value) as? AnyOptionGroup.Type)?
              .wrappedType.invalidAsyncCompletions(
                parent: InputKey(name: label, parent: parent),
                propertyPath: "\(propertyPath).\(label)"
              )
              ?? (child.value as? ArgumentSetProvider)?
              .argumentSet(for: InputKey(name: label, parent: parent))
              .content
              .compactMap { arg in
                guard case .customAsync = arg.completion.kind else {
                  return nil
                }
                return "\(propertyPath).\(label)"
              }
          }
          ?? []
      }
  }
}
