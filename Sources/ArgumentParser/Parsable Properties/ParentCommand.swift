//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// A wrapper that adds a reference to a parent command.
///
/// Use the parent command wrapper to gain access to a parent command's state.
///
/// ```swift
/// struct SuperCommand: ParsableCommand {
///     static let configuration = CommandConfiguration(
///         subcommands: [SubCommand.self]
///     )
///
///     @Flag(name: .shortAndLong)
///     var verbose: Bool = false
/// }
///
/// struct SubCommand: ParsableCommand {
///     @ParentCommand var parent: SuperCommand
///
///     mutating func run() throws {
///         if self.parent.verbose {
///             print("Verbose")
///         }
///     }
/// }
/// ```
@propertyWrapper
public struct ParentCommand<Value: ParsableCommand>: Decodable, ParsedWrapper {
  internal var _parsedValue: Parsed<Value>
  internal var _visibility: ArgumentVisibility

  internal init(_parsedValue: Parsed<Value>) {
    self._parsedValue = _parsedValue
    self._visibility = .default
  }

  public init(from _decoder: Decoder) throws {
    if let d = _decoder as? SingleValueDecoder,
      let value = try? d.previousValue(Value.self)
    {
      self.init(_parsedValue: .value(value))
    } else {
      // TODO produce a specialized error in the case where the parent is not in fact a parent of this command
      throw ParserError.notParentCommand("\(Value.self)")
    }
  }

  public init() {
    self.init(
      _parsedValue: .init { _ in
        .init()
      }
    )
  }

  public var wrappedValue: Value {
    get {
      switch _parsedValue {
      case .value(let v):
        return v
      case .definition:
        configurationFailure(directlyInitializedError)
      }
    }
    set {
      _parsedValue = .value(newValue)
    }
  }
}

extension ParentCommand: Sendable where Value: Sendable {}

extension ParentCommand: CustomStringConvertible {
  public var description: String {
    switch _parsedValue {
    case .value(let v):
      return String(describing: v)
    case .definition:
      return "ParentCommand(*definition*)"
    }
  }
}
