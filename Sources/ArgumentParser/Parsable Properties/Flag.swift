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

/// A wrapper that represents a command-line flag.
///
/// A flag is a defaulted Boolean or integer value that can be changed by
/// specifying the flag on the command line. For example:
///
///     struct Options: ParsableArguments {
///         @Flag var verbose: Bool
///     }
///
/// `verbose` has a default value of `false`, but becomes `true` if `--verbose`
/// is provided on the command line.
///
/// A flag can have a value that is a `Bool`, an `Int`, or any `CaseIterable`
/// type. When using a `CaseIterable` type as a flag, the individual cases
/// form the flags that are used on the command line.
///
///     struct Options {
///         enum Operation: CaseIterable, ... {
///             case add
///             case multiply
///         }
///
///         @Flag var operation: Operation
///     }
///
///     // usage: command --add
///     //    or: command --multiply
@propertyWrapper
public struct Flag<Value>: Decodable, ParsedWrapper {
  internal var _parsedValue: Parsed<Value>
  
  internal init(_parsedValue: Parsed<Value>) {
    self._parsedValue = _parsedValue
  }
  
  public init(from decoder: Decoder) throws {
    try self.init(_decoder: decoder)
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

extension Flag: CustomStringConvertible {
  public var description: String {
    switch _parsedValue {
    case .value(let v):
      return String(describing: v)
    case .definition:
      return "Flag(*definition*)"
    }
  }
}

extension Flag: DecodableParsedWrapper where Value: Decodable {}

/// The options for converting a Boolean flag into a `true`/`false` pair.
public enum FlagInversion {
  /// Adds a matching flag with a `no-` prefix to represent `false`.
  ///
  /// For example, the `shouldRender` property in this declaration is set to
  /// `true` when a user provides `--render` and to `false` when the user
  /// provides `--no-render`:
  ///
  ///     @Flag(name: .customLong("render"), inversion: .prefixedNo)
  ///     var shouldRender: Bool
  case prefixedNo
  
  /// Uses matching flags with `enable-` and `disable-` prefixes.
  ///
  /// For example, the `extraOutput` property in this declaration is set to
  /// `true` when a user provides `--enable-extra-output` and to `false` when
  /// the user provides `--disable-extra-output`:
  ///
  ///     @Flag(inversion: .prefixedEnableDisable)
  ///     var extraOutput: Bool
  case prefixedEnableDisable
}

/// The options for treating enumeration-based flags as exclusive.
public enum FlagExclusivity {
  /// Only one of the enumeration cases may be provided.
  case exclusive
  
  /// The first enumeration case that is provided is used.
  case chooseFirst
  
  /// The last enumeration case that is provided is used.
  case chooseLast
}

extension Flag where Value == Optional<Bool> {
  /// Creates a Boolean property that reads its value from the presence of
  /// one or more inverted flags.
  ///
  /// Use this initializer to create an optional Boolean flag with an on/off
  /// pair. With the following declaration, for example, the user can specify
  /// either `--use-https` or `--no-use-https` to set the `useHTTPS` flag to
  /// `true` or `false`, respectively. If neither is specified, the resulting
  /// flag value would be `nil`.
  ///
  ///     @Flag(inversion: .prefixedNo)
  ///     var useHTTPS: Bool?
  ///
  /// - Parameters:
  ///   - name: A specification for what names are allowed for this flag.
  ///   - inversion: The method for converting this flags name into an on/off
  ///     pair.
  ///   - exclusivity: The behavior to use when an on/off pair of flags is
  ///     specified.
  ///   - help: Information about how to use this flag.
  public init(
    name: NameSpecification = .long,
    inversion: FlagInversion,
    exclusivity: FlagExclusivity = .chooseLast,
    help: ArgumentHelp? = nil
  ) {
    self.init(_parsedValue: .init { key in
      .flag(key: key, name: name, default: nil, inversion: inversion, exclusivity: exclusivity, help: help)
    })
  }
}

extension Flag where Value == Bool {
  /// Creates a Boolean property that reads its value from the presence of a
  /// flag.
  ///
  /// This property defaults to a value of `false`.
  ///
  /// - Parameters:
  ///   - name: A specification for what names are allowed for this flag.
  ///   - help: Information about how to use this flag.
  public init(
    name: NameSpecification = .long,
    help: ArgumentHelp? = nil
  ) {
    self.init(_parsedValue: .init { key in
      .flag(key: key, name: name, help: help)
      })
  }
  
  /// Creates a Boolean property that reads its value from the presence of
  /// one or more inverted flags.
  ///
  /// Use this initializer to create a Boolean flag with an on/off pair. With
  /// the following declaration, for example, the user can specify either
  /// `--use-https` or `--no-use-https` to set the `useHTTPS` flag to `true`
  /// or `false`, respectively.
  ///
  ///     @Flag(inversion: .prefixedNo)
  ///     var useHTTPS: Bool
  ///
  /// To customize the names of the two states further, define a
  /// `CaseIterable` enumeration with a case for each state, and use that
  /// as the type for your flag. In this case, the user can specify either
  /// `--use-production-server` or `--use-development-server` to set the
  /// flag's value.
  ///
  ///     enum ServerChoice {
  ///         case useProductionServer
  ///         case useDevelopmentServer
  ///     }
  ///
  ///     @Flag() var serverChoice: ServerChoice
  ///
  /// - Parameters:
  ///   - name: A specification for what names are allowed for this flag.
  ///   - initial: The default value for this flag.
  ///   - inversion: The method for converting this flag's name into an on/off
  ///     pair.
  ///   - exclusivity: The behavior to use when an on/off pair of flags is
  ///     specified.
  ///   - help: Information about how to use this flag.
  public init(
    name: NameSpecification = .long,
    default initial: Bool? = false,
    inversion: FlagInversion,
    exclusivity: FlagExclusivity = .chooseLast,
    help: ArgumentHelp? = nil
  ) {
    self.init(_parsedValue: .init { key in
      .flag(key: key, name: name, default: initial, inversion: inversion, exclusivity: exclusivity, help: help)
      })
  }
}

extension Flag where Value == Int {
  /// Creates an integer property that gets its value from the number of times
  /// a flag appears.
  ///
  /// This property defaults to a value of zero.
  ///
  /// - Parameters:
  ///   - name: A specification for what names are allowed for this flag.
  ///   - help: Information about how to use this flag.
  public init(
    name: NameSpecification = .long,
    help: ArgumentHelp? = nil
  ) {
    self.init(_parsedValue: .init { key in
      .counter(key: key, name: name, help: help)
      })
  }
}

extension Flag where Value: CaseIterable, Value: Equatable, Value: RawRepresentable, Value.RawValue == String {
  /// Creates a property that gets its value from the presence of a flag,
  /// where the allowed flags are defined by a `CaseIterable` type.
  ///
  /// - Parameters:
  ///   - name: A specification for what names are allowed for this flag.
  ///   - initial: A default value to use for this property. If `initial` is
  ///     `nil`, this flag is required.
  ///   - exclusivity: The behavior to use when multiple flags are specified.
  ///   - help: Information about how to use this flag.
  public init(
    name: NameSpecification = .long,
    default initial: Value? = nil,
    exclusivity: FlagExclusivity = .exclusive,
    help: ArgumentHelp? = nil
  ) {
    self.init(_parsedValue: .init { key in
      // This gets flipped to `true` the first time one of these flags is
      // encountered.
      var hasUpdated = false
      let defaultValue = initial.map(String.init(describing:))

      let args = Value.allCases.map { value -> ArgumentDefinition in
        let caseKey = InputKey(rawValue: value.rawValue)
        let help = ArgumentDefinition.Help(options: initial != nil ? .isOptional : [], help: help, defaultValue: defaultValue, key: key)
        return ArgumentDefinition.flag(name: name, key: key, caseKey: caseKey, help: help, parsingStrategy: .nextAsValue, initialValue: initial, update: .nullary({ (origin, name, values) in
          hasUpdated = try ArgumentSet.updateFlag(key: key, value: value, origin: origin, values: &values, hasUpdated: hasUpdated, exclusivity: exclusivity)
        }))
      }
      return exclusivity == .exclusive
        ? ArgumentSet(exclusive: args)
        : ArgumentSet(additive: args)
      })
  }
}

extension Flag {
  /// Creates a property that gets its value from the presence of a flag,
  /// where the allowed flags are defined by a `CaseIterable` type.
  ///
  /// This property has a default value of `nil`; specifying the flag in the
  /// command-line arguments is not required.
  ///
  /// - Parameters:
  ///   - name: A specification for what names are allowed for this flag.
  ///   - exclusivity: The behavior to use when multiple flags are specified.
  ///   - help: Information about how to use this flag.
  public init<Element>(
    name: NameSpecification = .long,
    exclusivity: FlagExclusivity = .exclusive,
    help: ArgumentHelp? = nil
  ) where Value == Element?, Element: CaseIterable, Element: Equatable, Element: RawRepresentable, Element.RawValue == String {
    self.init(_parsedValue: .init { key in
      // This gets flipped to `true` the first time one of these flags is
      // encountered.
      var hasUpdated = false
      
      let args = Element.allCases.map { value -> ArgumentDefinition in
        let caseKey = InputKey(rawValue: value.rawValue)
        let help = ArgumentDefinition.Help(options: .isOptional, help: help, key: key)
        return ArgumentDefinition.flag(name: name, key: key, caseKey: caseKey, help: help, parsingStrategy: .nextAsValue, initialValue: nil as Element?, update: .nullary({ (origin, name, values) in
          hasUpdated = try ArgumentSet.updateFlag(key: key, value: value, origin: origin, values: &values, hasUpdated: hasUpdated, exclusivity: exclusivity)
        }))
      }
      return exclusivity == .exclusive
        ? ArgumentSet(exclusive: args)
        : ArgumentSet(additive: args)
      })
  }
  
  /// Creates an array property that gets its values from the presence of
  /// zero or more flags, where the allowed flags are defined by a
  /// `CaseIterable` type.
  ///
  /// This property has an empty array as its default value.
  ///
  /// - Parameters:
  ///   - name: A specification for what names are allowed for this flag.
  ///   - help: Information about how to use this flag.
  public init<Element>(
    name: NameSpecification = .long,
    help: ArgumentHelp? = nil
  ) where Value == Array<Element>, Element: CaseIterable, Element: RawRepresentable, Element.RawValue == String {
    self.init(_parsedValue: .init { key in
      let args = Element.allCases.map { value -> ArgumentDefinition in
        let caseKey = InputKey(rawValue: value.rawValue)
        let help = ArgumentDefinition.Help(options: .isOptional, help: help, key: key)
        return ArgumentDefinition.flag(name: name, key: key, caseKey: caseKey, help: help, parsingStrategy: .nextAsValue, initialValue: [Element](), update: .nullary({ (origin, name, values) in
          values.update(forKey: key, inputOrigin: origin, initial: [Element](), closure: {
            $0.append(value)
          })
        }))
      }
      return ArgumentSet(additive: args)
      })
  }
}

extension ArgumentDefinition {
  static func flag<V>(name: NameSpecification, key: InputKey, caseKey: InputKey, help: Help, parsingStrategy: ArgumentDefinition.ParsingStrategy, initialValue: V?, update: Update) -> ArgumentDefinition {
    return ArgumentDefinition(kind: .name(key: caseKey, specification: name), help: help, parsingStrategy: parsingStrategy, update: update, initial: { origin, values in
      if let initial = initialValue {
        values.set(initial, forKey: key, inputOrigin: origin)
      }
    })
  }
}
