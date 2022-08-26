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

/// A property wrapper that represents a command-line option.
///
/// Use the `@Option` wrapper to define a property of your custom command as a
/// command-line option. An *option* is a named value passed to a command-line
/// tool, like `--configuration debug`. Options can be specified in any order.
///
/// An option can have a default value specified as part of its
/// declaration; options with optional `Value` types implicitly have `nil` as
/// their default value. Options that are neither declared as `Optional` nor
/// given a default value are required for users of your command-line tool.
///
/// For example, the following program defines three options:
///
///     @main
///     struct Greet: ParsableCommand {
///         @Option var greeting = "Hello"
///         @Option var age: Int? = nil
///         @Option var name: String
///
///         mutating func run() {
///             print("\(greeting) \(name)!")
///             if let age = age {
///                 print("Congrats on making it to the ripe old age of \(age)!")
///             }
///         }
///     }
///
/// `greeting` has a default value of `"Hello"`, which can be overridden by
/// providing a different string as an argument, while `age` defaults to `nil`.
/// `name` is a required option because it is non-`nil` and has no default
/// value.
///
///     $ greet --name Alicia
///     Hello Alicia!
///     $ greet --age 28 --name Seungchin --greeting Hi
///     Hi Seungchin!
///     Congrats on making it to the ripe old age of 28!
@propertyWrapper
public struct Option<Value>: Decodable, ParsedWrapper {
  internal var _parsedValue: Parsed<Value>
  
  internal init(_parsedValue: Parsed<Value>) {
    self._parsedValue = _parsedValue
  }
  
  public init(from decoder: Decoder) throws {
    try self.init(_decoder: decoder)
  }

  /// This initializer works around a quirk of property wrappers, where the
  /// compiler will not see no-argument initializers in extensions. Explicitly
  /// marking this initializer unavailable means that when `Value` conforms to
  /// `ExpressibleByArgument`, that overload will be selected instead.
  ///
  /// ```swift
  /// @Option() var foo: String // Syntax without this initializer
  /// @Option var foo: String   // Syntax with this initializer
  /// ```
  @available(*, unavailable, message: "A default value must be provided unless the value type conforms to ExpressibleByArgument.")
  public init() {
    fatalError("unavailable")
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

extension Option: CustomStringConvertible {
  public var description: String {
    switch _parsedValue {
    case .value(let v):
      return String(describing: v)
    case .definition:
      return "Option(*definition*)"
    }
  }
}

extension Option: DecodableParsedWrapper where Value: Decodable {}

/// The strategy to use when parsing a single value from `@Option` arguments.
///
/// - SeeAlso: ``ArrayParsingStrategy``
public struct SingleValueParsingStrategy: Hashable {  
  internal var base: ArgumentDefinition.ParsingStrategy
  
  /// Parse the input after the option. Expect it to be a value.
  ///
  /// For inputs such as `--foo foo`, this would parse `foo` as the
  /// value. However, the input `--foo --bar foo bar` would
  /// result in an error. Even though two values are provided, they don’t
  /// succeed each option. Parsing would result in an error such as the following:
  ///
  ///     Error: Missing value for '--foo <foo>'
  ///     Usage: command [--foo <foo>]
  ///
  /// This is the **default behavior** for `@Option`-wrapped properties.
  public static var next: SingleValueParsingStrategy {
    self.init(base: .default)
  }
  
  /// Parse the next input, even if it could be interpreted as an option or
  /// flag.
  ///
  /// For inputs such as `--foo --bar baz`, if `.unconditional` is used for `foo`,
  /// this would read `--bar` as the value for `foo` and would use `baz` as
  /// the next positional argument.
  ///
  /// This allows reading negative numeric values or capturing flags to be
  /// passed through to another program since the leading hyphen is normally
  /// interpreted as the start of another option.
  ///
  /// - Note: This is usually *not* what users would expect. Use with caution.
  public static var unconditional: SingleValueParsingStrategy {
    self.init(base: .unconditional)
  }
  
  /// Parse the next input, as long as that input can't be interpreted as
  /// an option or flag.
  ///
  /// - Note: This will skip other options and _read ahead_ in the input
  /// to find the next available value. This may be *unexpected* for users.
  /// Use with caution.
  ///
  /// For example, if `--foo` takes a value, then the input `--foo --bar bar`
  /// would be parsed such that the value `bar` is used for `--foo`.
  public static var scanningForValue: SingleValueParsingStrategy {
    self.init(base: .scanningForValue)
  }
}

/// The strategy to use when parsing multiple values from `@Option` arguments into an
/// array.
public struct ArrayParsingStrategy: Hashable {
  internal var base: ArgumentDefinition.ParsingStrategy
  
  /// Parse one value per option, joining multiple into an array.
  ///
  /// For example, for a parsable type with a property defined as
  /// `@Option(parsing: .singleValue) var read: [String]`,
  /// the input `--read foo --read bar` would result in the array
  /// `["foo", "bar"]`. The same would be true for the input
  /// `--read=foo --read=bar`.
  ///
  /// - Note: This follows the default behavior of differentiating between values and options. As
  ///     such, the value for this option will be the next value (non-option) in the input. For the
  ///     above example, the input `--read --name Foo Bar` would parse `Foo` into
  ///     `read` (and `Bar` into `name`).
  public static var singleValue: ArrayParsingStrategy {
    self.init(base: .default)
  }
  
  /// Parse the value immediately after the option while allowing repeating options, joining multiple into an array.
  ///
  /// This is identical to `.singleValue` except that the value will be read
  /// from the input immediately after the option, even if it could be interpreted as an option.
  ///
  /// For example, for a parsable type with a property defined as
  /// `@Option(parsing: .unconditionalSingleValue) var read: [String]`,
  /// the input `--read foo --read bar` would result in the array
  /// `["foo", "bar"]` -- just as it would have been the case for `.singleValue`.
  ///
  /// - Note: However, the input `--read --name Foo Bar --read baz` would result in
  /// `read` being set to the array `["--name", "baz"]`. This is usually *not* what users
  /// would expect. Use with caution.
  public static var unconditionalSingleValue: ArrayParsingStrategy {
    self.init(base: .unconditional)
  }
  
  /// Parse all values up to the next option.
  ///
  /// For example, for a parsable type with a property defined as
  /// `@Option(parsing: .upToNextOption) var files: [String]`,
  /// the input `--files foo bar` would result in the array
  /// `["foo", "bar"]`.
  ///
  /// Parsing stops as soon as there’s another option in the input such that
  /// `--files foo bar --verbose` would also set `files` to the array
  /// `["foo", "bar"]`.
  public static var upToNextOption: ArrayParsingStrategy {
    self.init(base: .upToNextOption)
  }

  /// Parse all remaining arguments into an array.
  ///
  /// `.remaining` can be used for capturing pass-through flags. For example, for
  /// a parsable type defined as
  /// `@Option(parsing: .remaining) var passthrough: [String]`:
  ///
  ///     $ cmd --passthrough --foo 1 --bar 2 -xvf
  ///     ------------
  ///     options.passthrough == ["--foo", "1", "--bar", "2", "-xvf"]
  ///
  /// - Note: This will read all inputs following the option without attempting to do any parsing. This is
  /// usually *not* what users would expect. Use with caution.
  ///
  /// Consider using a trailing `@Argument` instead and letting users explicitly turn off parsing
  /// through the terminator `--`. That is the more common approach. For example:
  /// ```swift
  /// struct Options: ParsableArguments {
  ///     @Option var name: String
  ///     @Argument var remainder: [String]
  /// }
  /// ```
  /// would parse the input `--name Foo -- Bar --baz` such that the `remainder`
  /// would hold the value `["Bar", "--baz"]`.
  public static var remaining: ArrayParsingStrategy {
    self.init(base: .allRemainingInput)
  }
}

// MARK: - @Option T: ExpressibleByArgument Initializers
extension Option {
  /// Creates a property with a default value provided by standard Swift default value syntax.
  ///
  /// This method is called to initialize an `Option` with a default value such as:
  /// ```swift
  /// @Option var foo: String = "bar"
  /// ```
  ///
  /// - Parameters:
  ///   - wrappedValue: A default value to use for this property, provided
  ///   implicitly by the compiler during property wrapper initialization.
  ///   - name: A specification for what names are allowed for this flag.
  ///   - parsingStrategy: The behavior to use when looking for this option's value.
  ///   - help: Information about how to use this option.
  ///   - completion: Kind of completion provided to the user for this option.
  public init(
    wrappedValue: Value,
    name: NameSpecification = .long,
    parsing parsingStrategy: SingleValueParsingStrategy = .next,
    help: ArgumentHelp? = nil,
    completion: CompletionKind? = nil
  ) where Value: ExpressibleByArgument {
    self.init(_parsedValue: .init { key in
      let arg = ArgumentDefinition(
        container: Bare<Value>.self,
        key: key,
        kind: .name(key: key, specification: name),
        help: help,
        parsingStrategy: parsingStrategy.base,
        initial: wrappedValue,
        completion: completion)

      return ArgumentSet(arg)
    })
  }

  @available(*, deprecated, message: """
    Swap the order of the 'help' and 'completion' arguments.
    """)
  public init(
    wrappedValue: Value,
    name: NameSpecification = .long,
    parsing parsingStrategy: SingleValueParsingStrategy = .next,
    completion: CompletionKind?,
    help: ArgumentHelp?
  ) where Value: ExpressibleByArgument {
    self.init(
      wrappedValue: wrappedValue,
      name: name,
      parsing: parsingStrategy,
      help: help,
      completion: completion)
  }

  /// Creates a property with no default value.
  ///
  /// This method is called to initialize an `Option` without a default value such as:
  /// ```swift
  /// @Option var foo: String
  /// ```
  ///
  /// - Parameters:
  ///   - name: A specification for what names are allowed for this flag.
  ///   - parsingStrategy: The behavior to use when looking for this option's value.
  ///   - help: Information about how to use this option.
  ///   - completion: Kind of completion provided to the user for this option.
  public init(
    name: NameSpecification = .long,
    parsing parsingStrategy: SingleValueParsingStrategy = .next,
    help: ArgumentHelp? = nil,
    completion: CompletionKind? = nil
  ) where Value: ExpressibleByArgument {
    self.init(_parsedValue: .init { key in
      let arg = ArgumentDefinition(
        container: Bare<Value>.self,
        key: key,
        kind: .name(key: key, specification: name),
        help: help,
        parsingStrategy: parsingStrategy.base,
        initial: nil,
        completion: completion)

      return ArgumentSet(arg)
    })
  }
}

// MARK: - @Option T Initializers
extension Option {
  /// Creates a property with a default value provided by standard Swift default value syntax.
  ///
  /// This method is called to initialize an `Option` with a default value such as:
  /// ```swift
  /// @Option var foo: String = "bar"
  /// ```
  ///
  /// - Parameters:
  ///   - wrappedValue: A default value to use for this property, provided
  ///   implicitly by the compiler during property wrapper initialization.
  ///   - name: A specification for what names are allowed for this flag.
  ///   - parsingStrategy: The behavior to use when looking for this option's value.
  ///   - help: Information about how to use this option.
  ///   - completion: Kind of completion provided to the user for this option.
  ///   - transform: A closure that converts a string into this property's
  ///     element type or throws an error.
  public init(
    wrappedValue: Value,
    name: NameSpecification = .long,
    parsing parsingStrategy: SingleValueParsingStrategy = .next,
    help: ArgumentHelp? = nil,
    completion: CompletionKind? = nil,
    transform: @escaping (String) throws -> Value
  ) {
    self.init(_parsedValue: .init { key in
      let arg = ArgumentDefinition(
        container: Bare<Value>.self,
        key: key,
        kind: .name(key: key, specification: name),
        help: help,
        parsingStrategy: parsingStrategy.base,
        transform: transform,
        initial: wrappedValue,
        completion: completion)

      return ArgumentSet(arg)
    })
  }

  /// Creates a property with no default value.
  ///
  /// This method is called to initialize an `Option` without a default value such as:
  /// ```swift
  /// @Option var foo: String
  /// ```
  ///
  /// - Parameters:
  ///   - name: A specification for what names are allowed for this flag.
  ///   - parsingStrategy: The behavior to use when looking for this option's value.
  ///   - help: Information about how to use this option.
  ///   - completion: Kind of completion provided to the user for this option.
  public init(
    name: NameSpecification = .long,
    parsing parsingStrategy: SingleValueParsingStrategy = .next,
    help: ArgumentHelp? = nil,
    completion: CompletionKind? = nil,
    transform: @escaping (String) throws -> Value
  ) {
    self.init(_parsedValue: .init { key in
      let arg = ArgumentDefinition(
        container: Bare<Value>.self,
        key: key,
        kind: .name(key: key, specification: name),
        help: help,
        parsingStrategy: parsingStrategy.base,
        transform: transform,
        initial: nil,
        completion: completion)

      return ArgumentSet(arg)
    })
  }
}

// MARK: - @Option Optional<T: ExpressibleByArgument> Initializers
extension Option {
  /// This initializer allows a user to provide a `nil` default value for an
  /// optional `@Option`-marked property without allowing a non-`nil` default
  /// value.
  ///
  /// - Parameters:
  ///   - name: A specification for what names are allowed for this flag.
  ///   - parsingStrategy: The behavior to use when looking for this option's
  ///     value.
  ///   - help: Information about how to use this option.
  ///   - completion: Kind of completion provided to the user for this option.
  public init<T>(
    wrappedValue _value: _OptionalNilComparisonType,
    name: NameSpecification = .long,
    parsing parsingStrategy: SingleValueParsingStrategy = .next,
    help: ArgumentHelp? = nil,
    completion: CompletionKind? = nil
  ) where T: ExpressibleByArgument, Value == Optional<T> {
    self.init(_parsedValue: .init { key in
      let arg = ArgumentDefinition(
        container: Optional<T>.self,
        key: key,
        kind: .name(key: key, specification: name),
        help: help,
        parsingStrategy: parsingStrategy.base,
        initial: nil,
        completion: completion)

      return ArgumentSet(arg)
    })
  }

  @available(*, deprecated, message: """
    Optional @Options with default values should be declared as non-Optional.
    """)
  public init<T>(
    wrappedValue: Value,
    name: NameSpecification = .long,
    parsing parsingStrategy: SingleValueParsingStrategy = .next,
    help: ArgumentHelp? = nil,
    completion: CompletionKind? = nil
  ) where T: ExpressibleByArgument, Value == Optional<T> {
    self.init(_parsedValue: .init { key in
      let arg = ArgumentDefinition(
        container: Optional<T>.self,
        key: key,
        kind: .name(key: key, specification: name),
        help: help,
        parsingStrategy: parsingStrategy.base,
        initial: wrappedValue,
        completion: completion)

      return ArgumentSet(arg)
    })
  }

  /// Creates a property that reads its value from a labeled option.
  ///
  /// If the property has an `Optional` type, or you provide a non-`nil`
  /// value for the `initial` parameter, specifying this option is not
  /// required.
  ///
  /// - Parameters:
  ///   - name: A specification for what names are allowed for this flag.
  ///   - parsingStrategy: The behavior to use when looking for this option's
  ///     value.
  ///   - help: Information about how to use this option.
  ///   - completion: Kind of completion provided to the user for this option.
  public init<T>(
    name: NameSpecification = .long,
    parsing parsingStrategy: SingleValueParsingStrategy = .next,
    help: ArgumentHelp? = nil,
    completion: CompletionKind? = nil
  ) where T: ExpressibleByArgument, Value == Optional<T> {
    self.init(_parsedValue: .init { key in
      let arg = ArgumentDefinition(
        container: Optional<T>.self,
        key: key,
        kind: .name(key: key, specification: name),
        help: help,
        parsingStrategy: parsingStrategy.base,
        initial: nil,
        completion: completion)

      return ArgumentSet(arg)
    })
  }
}

// MARK: - @Option Optional<T> Initializers
extension Option {
  /// Creates a property with a default value provided by standard Swift default
  /// value syntax, parsing with the given closure.
  ///
  /// This method is called to initialize an `Option` with a default value such as:
  /// ```swift
  /// @Option(transform: baz)
  /// var foo: String = "bar"
  /// ```
  ///
  /// - Parameters:
  ///   - wrappedValue: A default value to use for this property, provided
  ///   implicitly by the compiler during property wrapper initialization.
  ///   - name: A specification for what names are allowed for this flag.
  ///   - parsingStrategy: The behavior to use when looking for this option's value.
  ///   - help: Information about how to use this option.
  ///   - completion: Kind of completion provided to the user for this option.
  ///   - transform: A closure that converts a string into this property's type
  ///   or throws an error.
  public init<T>(
    wrappedValue _value: _OptionalNilComparisonType,
    name: NameSpecification = .long,
    parsing parsingStrategy: SingleValueParsingStrategy = .next,
    help: ArgumentHelp? = nil,
    completion: CompletionKind? = nil,
    transform: @escaping (String) throws -> T
  ) where Value == Optional<T> {
    self.init(_parsedValue: .init { key in
      let arg = ArgumentDefinition(
        container: Optional<T>.self,
        key: key,
        kind: .name(key: key, specification: name),
        help: help,
        parsingStrategy: parsingStrategy.base,
        transform: transform,
        initial: nil,
        completion: completion)

      return ArgumentSet(arg)
    })
  }

  @available(*, deprecated, message: """
    Optional @Options with default values should be declared as non-Optional.
    """)
  public init<T>(
    wrappedValue: Value,
    name: NameSpecification = .long,
    parsing parsingStrategy: SingleValueParsingStrategy = .next,
    help: ArgumentHelp? = nil,
    completion: CompletionKind? = nil,
    transform: @escaping (String) throws -> T
  ) where Value == Optional<T> {
    self.init(_parsedValue: .init { key in
      let arg = ArgumentDefinition(
        container: Optional<T>.self,
        key: key,
        kind: .name(key: key, specification: name),
        help: help,
        parsingStrategy: parsingStrategy.base,
        transform: transform,
        initial: wrappedValue,
        completion: completion)

      return ArgumentSet(arg)
    })
  }

  /// Creates a property with no default value, parsing with the given closure.
  ///
  /// This method is called to initialize an `Option` with no default value such as:
  /// ```swift
  /// @Option(transform: baz)
  /// var foo: String
  /// ```
  ///
  /// - Parameters:
  ///   - name: A specification for what names are allowed for this flag.
  ///   - parsingStrategy: The behavior to use when looking for this option's value.
  ///   - help: Information about how to use this option.
  ///   - completion: Kind of completion provided to the user for this option.
  ///   - transform: A closure that converts a string into this property's type or throws an error.
  public init<T>(
    name: NameSpecification = .long,
    parsing parsingStrategy: SingleValueParsingStrategy = .next,
    help: ArgumentHelp? = nil,
    completion: CompletionKind? = nil,
    transform: @escaping (String) throws -> T
  ) where Value == Optional<T> {
    self.init(_parsedValue: .init { key in
      let arg = ArgumentDefinition(
        container: Optional<T>.self,
        key: key,
        kind: .name(key: key, specification: name),
        help: help,
        parsingStrategy: parsingStrategy.base,
        transform: transform,
        initial: nil,
        completion: completion)

      return ArgumentSet(arg)
    })
  }
}

// MARK: - @Option Array<T: ExpressibleByArgument> Initializers
extension Option {
  /// Creates an array property that reads its values from zero or more
  /// labeled options.
  ///
  /// - Parameters:
  ///   - name: A specification for what names are allowed for this flag.
  ///   - initial: A default value to use for this property.
  ///   - parsingStrategy: The behavior to use when parsing multiple values
  ///     from the command-line arguments.
  ///   - help: Information about how to use this option.
  ///   - completion: Kind of completion provided to the user for this option.
  public init<T>(
    wrappedValue: Value,
    name: NameSpecification = .long,
    parsing parsingStrategy: ArrayParsingStrategy = .singleValue,
    help: ArgumentHelp? = nil,
    completion: CompletionKind? = nil
  ) where T: ExpressibleByArgument, Value == Array<T> {
    self.init(_parsedValue: .init { key in
      let arg = ArgumentDefinition(
        container: Array<T>.self,
        key: key,
        kind: .name(key: key, specification: name),
        help: help,
        parsingStrategy: parsingStrategy.base,
        initial: wrappedValue,
        completion: completion)

      return ArgumentSet(arg)
    })
  }

  /// Creates an array property with no default value that reads its values from zero or more labeled options.
  ///
  /// This method is called to initialize an array `Option` with no default value such as:
  /// ```swift
  /// @Option()
  /// var foo: [String]
  /// ```
  ///
  /// - Parameters:
  ///   - name: A specification for what names are allowed for this flag.
  ///   - parsingStrategy: The behavior to use when parsing multiple values from the command-line arguments.
  ///   - help: Information about how to use this option.
  ///   - completion: Kind of completion provided to the user for this option.
  public init<T>(
    name: NameSpecification = .long,
    parsing parsingStrategy: ArrayParsingStrategy = .singleValue,
    help: ArgumentHelp? = nil,
    completion: CompletionKind? = nil
  ) where T: ExpressibleByArgument, Value == Array<T> {
    self.init(_parsedValue: .init { key in
      let arg = ArgumentDefinition(
        container: Array<T>.self,
        key: key,
        kind: .name(key: key, specification: name),
        help: help,
        parsingStrategy: parsingStrategy.base,
        initial: nil,
        completion: completion)

      return ArgumentSet(arg)
    })
  }
}

// MARK: - @Option Array<T> Initializers
extension Option {
  /// Creates an array property that reads its values from zero or more
  /// labeled options, parsing with the given closure.
  ///
  /// This property defaults to an empty array if the `initial` parameter
  /// is not specified.
  ///
  /// - Parameters:
  ///   - name: A specification for what names are allowed for this flag.
  ///   - initial: A default value to use for this property. If `initial` is
  ///     `nil`, this option defaults to an empty array.
  ///   - parsingStrategy: The behavior to use when parsing multiple values
  ///     from the command-line arguments.
  ///   - help: Information about how to use this option.
  ///   - completion: Kind of completion provided to the user for this option.
  ///   - transform: A closure that converts a string into this property's
  ///     element type or throws an error.
  public init<T>(
    wrappedValue: Value,
    name: NameSpecification = .long,
    parsing parsingStrategy: ArrayParsingStrategy = .singleValue,
    help: ArgumentHelp? = nil,
    completion: CompletionKind? = nil,
    transform: @escaping (String) throws -> T
  ) where Value == Array<T> {
    self.init(_parsedValue: .init { key in
      let arg = ArgumentDefinition(
        container: Array<T>.self,
        key: key,
        kind: .name(key: key, specification: name),
        help: help,
        parsingStrategy: parsingStrategy.base,
        transform: transform,
        initial: wrappedValue,
        completion: completion)

      return ArgumentSet(arg)
    })
  }

  /// Creates an array property with no default value that reads its values from
  /// zero or more labeled options, parsing each element with the given closure.
  ///
  /// This method is called to initialize an array `Option` with no default value such as:
  /// ```swift
  /// @Option(transform: baz)
  /// var foo: [String]
  /// ```
  ///
  /// - Parameters:
  ///   - name: A specification for what names are allowed for this flag.
  ///   - parsingStrategy: The behavior to use when parsing multiple values from
  ///   the command-line arguments.
  ///   - help: Information about how to use this option.
  ///   - completion: Kind of completion provided to the user for this option.
  ///   - transform: A closure that converts a string into this property's
  ///   element type or throws an error.
  public init<T>(
    name: NameSpecification = .long,
    parsing parsingStrategy: ArrayParsingStrategy = .singleValue,
    help: ArgumentHelp? = nil,
    completion: CompletionKind? = nil,
    transform: @escaping (String) throws -> T
  ) where Value == Array<T> {
    self.init(_parsedValue: .init { key in
      let arg = ArgumentDefinition(
        container: Array<T>.self,
        key: key,
        kind: .name(key: key, specification: name),
        help: help,
        parsingStrategy: parsingStrategy.base,
        transform: transform,
        initial: nil,
        completion: completion)

      return ArgumentSet(arg)
    })
  }
}
