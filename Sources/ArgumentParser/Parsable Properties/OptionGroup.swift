//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// A wrapper that transparently includes a parsable type.
///
/// Use an option group to include a group of options, flags, or arguments
/// declared in a parsable type.
///
///     struct GlobalOptions: ParsableArguments {
///         @Flag(name: .shortAndLong)
///         var verbose: Bool
///
///         @Argument var values: [Int]
///     }
///
///     struct Options: ParsableArguments {
///         @Option var name: String
///         @OptionGroup var globals: GlobalOptions
///     }
///
/// The flag and positional arguments declared as part of `GlobalOptions` are
/// included when parsing `Options`.
@propertyWrapper
public struct OptionGroup<Value: ParsableArguments>: Decodable, ParsedWrapper {
  internal var _parsedValue: Parsed<Value>
  internal var _visibility: ArgumentVisibility

  // FIXME: Adding this property works around the crasher described in
  // https://github.com/apple/swift-argument-parser/issues/338
  internal var _dummy: Bool = false

  internal init(_parsedValue: Parsed<Value>) {
    self._parsedValue = _parsedValue
    self._visibility = .default
  }
  
  public init(from decoder: Decoder) throws {
    if let d = decoder as? SingleValueDecoder,
      let value = try? d.previousValue(Value.self)
    {
      self.init(_parsedValue: .value(value))
    } else {
      try self.init(_decoder: decoder)
      if let d = decoder as? SingleValueDecoder {
        d.saveValue(wrappedValue)
      }
    }
    
    do {
      try wrappedValue.validate()
    } catch {
      throw ParserError.userValidationError(error)
    }
  }

  /// Creates a property that represents another parsable type, using the
  /// specified visibility.
  public init(visibility: ArgumentVisibility = .default) {
    self.init(_parsedValue: .init { _ in
      ArgumentSet(Value.self, visibility: .private)
    })
    self._visibility = visibility
  }

  /// The value presented by this property wrapper.
  public var wrappedValue: Value {
    get {
      switch _parsedValue {
      case .value(let v):
        return v
      case .definition:
        fatalError(directlyInitializedError)
      }
    }
    set {
      _parsedValue = .value(newValue)
    }
  }
}

extension OptionGroup: CustomStringConvertible {
  public var description: String {
    switch _parsedValue {
    case .value(let v):
      return String(describing: v)
    case .definition:
      return "OptionGroup(*definition*)"
    }
  }
}

// Experimental use with caution
extension OptionGroup {
  @available(*, deprecated, renamed: "init(visibility:)")
  public init(_hiddenFromHelp: Bool) {
    self.init(visibility: .hidden)
  }
  
  /// Creates a property that represents another parsable type.
  @available(*, deprecated, renamed: "init(visibility:)")
  @_disfavoredOverload
  public init() {
    self.init(visibility: .default)
  }
}
