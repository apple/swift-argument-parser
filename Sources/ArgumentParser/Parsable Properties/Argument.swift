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

/// A property wrapper that represents a positional command-line argument.
///
/// Use the `@Argument` wrapper to define a property of your custom command as
/// a positional argument. A *positional argument* for a command-line tool is
/// specified without a label and must appear in declaration order. `@Argument`
/// properties with `Optional` type or a default value are optional for the user
/// of your command-line tool.
///
/// For example, the following program has two positional arguments. The `name`
/// argument is required, while `greeting` is optional because it has a default
/// value.
///
///     @main
///     struct Greet: ParsableCommand {
///         @Argument var name: String
///         @Argument var greeting: String = "Hello"
///
///         mutating func run() {
///             print("\(greeting) \(name)!")
///         }
///     }
///
/// You can call this program with just a name or with a name and a
/// greeting. When you supply both arguments, the first argument is always
/// treated as the name, due to the order of the property declarations.
///
///     $ greet Nadia
///     Hello Nadia!
///     $ greet Tamara Hi
///     Hi Tamara!
@propertyWrapper
public struct Argument<Value>:
  Decodable, ParsedWrapper
{
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
  /// @Argument() var foo: String // Syntax without this initializer
  /// @Argument var foo: String   // Syntax with this initializer
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

extension Argument: CustomStringConvertible {
  public var description: String {
    switch _parsedValue {
    case .value(let v):
      return String(describing: v)
    case .definition:
      return "Argument(*definition*)"
    }
  }
}

extension Argument: DecodableParsedWrapper where Value: Decodable { }

/// The strategy to use when parsing multiple values from positional arguments
/// into an array.
public struct ArgumentArrayParsingStrategy: Hashable {
  internal var base: ArgumentDefinition.ParsingStrategy
  
  /// Parse only unprefixed values from the command-line input, ignoring
  /// any inputs that have a dash prefix. This is the default strategy.
  ///
  /// For example, for a parsable type defined as following:
  ///
  ///     struct Options: ParsableArguments {
  ///         @Flag var verbose: Bool
  ///         @Argument(parsing: .remaining) var words: [String]
  ///     }
  ///
  /// Parsing the input `--verbose one two` or `one two --verbose` would result
  /// in `Options(verbose: true, words: ["one", "two"])`. Parsing the input
  /// `one two --other` would result in an unknown option error for `--other`.
  ///
  /// This is the default strategy for parsing argument arrays.
  public static var remaining: ArgumentArrayParsingStrategy {
    self.init(base: .default)
  }
  
  /// Parse all remaining inputs after parsing any known options or flags,
  /// including dash-prefixed inputs and the `--` terminator.
  ///
  /// When you use the `unconditionalRemaining` parsing strategy, the parser
  /// stops parsing flags and options as soon as it encounters a positional
  /// argument or an unrecognized flag. For example, for a parsable type
  /// defined as following:
  ///
  ///     struct Options: ParsableArguments {
  ///         @Flag
  ///         var verbose: Bool = false
  ///
  ///         @Argument(parsing: .unconditionalRemaining)
  ///         var words: [String] = []
  ///     }
  ///
  /// Parsing the input `--verbose one two --verbose` includes the second
  /// `--verbose` flag in `words`, resulting in
  /// `Options(verbose: true, words: ["one", "two", "--verbose"])`.
  ///
  /// - Note: This parsing strategy can be surprising for users, particularly
  ///   when combined with options and flags. Prefer `remaining` whenever
  ///   possible, since users can always terminate options and flags with
  ///   the `--` terminator. With the `remaining` parsing strategy, the input
  ///   `--verbose -- one two --verbose` would have the same result as the above
  ///   example: `Options(verbose: true, words: ["one", "two", "--verbose"])`.
  public static var unconditionalRemaining: ArgumentArrayParsingStrategy {
    self.init(base: .allRemainingInput)
  }
}

// MARK: - @Argument T: ExpressibleByArgument Initializers
extension Argument {
  /// Creates a property with a default value provided by standard Swift default
  /// value syntax.
  ///
  /// This method is called to initialize an `Argument` with a default value
  /// such as:
  /// ```swift
  /// @Argument var foo: String = "bar"
  /// ```
  ///
  /// - Parameters:
  ///   - wrappedValue: A default value to use for this property, provided
  ///   implicitly by the compiler during property wrapper initialization.
  ///   - help: Information about how to use this argument.
  ///   - completion: Kind of completion provided to the user for this option.
  public init(
    wrappedValue: Value,
    help: ArgumentHelp? = nil,
    completion: CompletionKind? = nil
  ) where Value: ExpressibleByArgument {
    self.init(_parsedValue: .init { key in
      let arg = ArgumentDefinition(
        container: Bare<Value>.self,
        key: key,
        kind: .positional,
        help: help,
        parsingStrategy: .default,
        initial: wrappedValue,
        completion: completion)

      return ArgumentSet(arg)
    })
  }

  /// Creates a property with no default value.
  ///
  /// This method is called to initialize an `Argument` without a default value
  /// such as:
  /// ```swift
  /// @Argument var foo: String
  /// ```
  ///
  /// - Parameters:
  ///   - help: Information about how to use this argument.
  ///   - completion: Kind of completion provided to the user for this option.
  public init(
    help: ArgumentHelp? = nil,
    completion: CompletionKind? = nil
  ) where Value: ExpressibleByArgument {
    self.init(_parsedValue: .init { key in
      let arg = ArgumentDefinition(
        container: Bare<Value>.self,
        key: key,
        kind: .positional,
        help: help,
        parsingStrategy: .default,
        initial: nil,
        completion: completion)

      return ArgumentSet(arg)
    })
  }
}

// MARK: - @Argument T Initializers
extension Argument {
  /// Creates a property with a default value provided by standard Swift default
  /// value syntax, parsing with the given closure.
  ///
  /// This method is called to initialize an `Argument` with a default value
  /// such as:
  /// ```swift
  /// @Argument(transform: baz)
  /// var foo: String = "bar"
  /// ```
  ///
  /// - Parameters:
  ///   - wrappedValue: A default value to use for this property, provided
  ///     implicitly by the compiler during property wrapper initialization.
  ///   - help: Information about how to use this argument.
  ///   - completion: Kind of completion provided to the user for this option.
  ///   - transform: A closure that converts a string into this property's type
  ///     or throws an error.
  public init(
    wrappedValue: Value,
    help: ArgumentHelp? = nil,
    completion: CompletionKind? = nil,
    transform: @escaping (String) throws -> Value
  ) {
    self.init(_parsedValue: .init { key in
      let arg = ArgumentDefinition(
        container: Bare<Value>.self,
        key: key,
        kind: .positional,
        help: help,
        parsingStrategy: .default,
        transform: transform,
        initial: wrappedValue,
        completion: completion)

      return ArgumentSet(arg)
    })
  }

  /// Creates a property with no default value, parsing with the given closure.
  ///
  /// This method is called to initialize an `Argument` with no default value such as:
  /// ```swift
  /// @Argument(transform: baz)
  /// var foo: String
  /// ```
  ///
  /// - Parameters:
  ///   - help: Information about how to use this argument.
  ///   - completion: Kind of completion provided to the user for this option.
  ///   - transform: A closure that converts a string into this property's
  ///     element type or throws an error.
  public init(
    help: ArgumentHelp? = nil,
    completion: CompletionKind? = nil,
    transform: @escaping (String) throws -> Value
  ) {
    self.init(_parsedValue: .init { key in
      let arg = ArgumentDefinition(
        container: Bare<Value>.self,
        key: key,
        kind: .positional,
        help: help,
        parsingStrategy: .default,
        transform: transform,
        initial: nil,
        completion: completion)

      return ArgumentSet(arg)
    })
  }
}

// MARK: - @Argument Optional<T: ExpressibleByArgument> Initializers
extension Argument {
  /// This initializer allows a user to provide a `nil` default value for an
  /// optional `@Argument`-marked property without allowing a non-`nil` default
  /// value.
  ///
  /// - Parameters:
  ///   - help: Information about how to use this argument.
  ///   - completion: Kind of completion provided to the user for this option.
  public init<T>(
    wrappedValue _value: _OptionalNilComparisonType,
    help: ArgumentHelp? = nil,
    completion: CompletionKind? = nil
  ) where T: ExpressibleByArgument, Value == Optional<T> {
    self.init(_parsedValue: .init { key in
      let arg = ArgumentDefinition(
        container: Optional<T>.self,
        key: key,
        kind: .positional,
        help: help,
        parsingStrategy: .default,
        initial: nil,
        completion: completion)

      return ArgumentSet(arg)
    })
  }

  @available(*, deprecated, message: """
    Optional @Arguments with default values should be declared as non-Optional.
    """)
  public init<T>(
    wrappedValue: Optional<T>,
    help: ArgumentHelp? = nil,
    completion: CompletionKind? = nil
  ) where T: ExpressibleByArgument, Value == Optional<T> {
    self.init(_parsedValue: .init { key in
      let arg = ArgumentDefinition(
        container: Optional<T>.self,
        key: key,
        kind: .positional,
        help: help,
        parsingStrategy: .default,
        initial: wrappedValue,
        completion: completion)

      return ArgumentSet(arg)
    })
  }

  /// Creates an optional property that reads its value from an argument.
  ///
  /// The argument is optional for the caller of the command and defaults to
  /// `nil`.
  ///
  /// - Parameters:
  ///   - help: Information about how to use this argument.
  ///   - completion: Kind of completion provided to the user for this option.
  public init<T>(
    help: ArgumentHelp? = nil,
    completion: CompletionKind? = nil
  ) where T: ExpressibleByArgument, Value == Optional<T> {
    self.init(_parsedValue: .init { key in
      let arg = ArgumentDefinition(
        container: Optional<T>.self,
        key: key,
        kind: .positional,
        help: help,
        parsingStrategy: .default,
        initial: nil,
        completion: completion)

      return ArgumentSet(arg)
    })
  }
}

// MARK: - @Argument Optional<T> Initializers
extension Argument {
  /// This initializer allows a user to provide a `nil` default value for an
  /// optional `@Argument`-marked property without allowing a non-`nil` default
  /// value.
  ///
  /// - Parameters:
  ///   - help: Information about how to use this argument.
  ///   - completion: Kind of completion provided to the user for this option.
  ///   - transform: A closure that converts a string into this property's
  ///     element type or throws an error.
  public init<T>(
    wrappedValue _value: _OptionalNilComparisonType,
    help: ArgumentHelp? = nil,
    completion: CompletionKind? = nil,
    transform: @escaping (String) throws -> T
  ) where Value == Optional<T> {
    self.init(_parsedValue: .init { key in
      let arg = ArgumentDefinition(
        container: Optional<T>.self,
        key: key,
        kind: .positional,
        help: help,
        parsingStrategy: .default,
        transform: transform,
        initial: nil,
        completion: completion)

      return ArgumentSet(arg)
    })
  }

  @available(*, deprecated, message: """
    Optional @Arguments with default values should be declared as non-Optional.
    """)
  public init<T>(
    wrappedValue: Optional<T>,
    help: ArgumentHelp? = nil,
    completion: CompletionKind? = nil,
    transform: @escaping (String) throws -> T
  ) where Value == Optional<T> {
    self.init(_parsedValue: .init { key in
      let arg = ArgumentDefinition(
        container: Optional<T>.self,
        key: key,
        kind: .positional,
        help: help,
        parsingStrategy: .default,
        transform: transform,
        initial: wrappedValue,
        completion: completion)

      return ArgumentSet(arg)
    })
  }

  /// Creates an optional property that reads its value from an argument.
  ///
  /// The argument is optional for the caller of the command and defaults to
  /// `nil`.
  ///
  /// - Parameters:
  ///   - help: Information about how to use this argument.
  ///   - completion: Kind of completion provided to the user for this option.
  ///   - transform: A closure that converts a string into this property's
  ///     element type or throws an error.
  public init<T>(
    help: ArgumentHelp? = nil,
    completion: CompletionKind? = nil,
    transform: @escaping (String) throws -> T
  ) where Value == Optional<T> {
    self.init(_parsedValue: .init { key in
      let arg = ArgumentDefinition(
        container: Optional<T>.self,
        key: key,
        kind: .positional,
        help: help,
        parsingStrategy: .default,
        transform: transform,
        initial: nil,
        completion: completion)

      return ArgumentSet(arg)
    })
  }
}

// MARK: - @Argument Array<T: ExpressibleByArgument> Initializers
extension Argument {
  /// Creates a property that reads an array from zero or more arguments.
  ///
  /// - Parameters:
  ///   - initial: A default value to use for this property.
  ///   - parsingStrategy: The behavior to use when parsing multiple values from
  ///     the command-line arguments.
  ///   - help: Information about how to use this argument.
  ///   - completion: Kind of completion provided to the user for this option.
  public init<T>(
    wrappedValue: Array<T>,
    parsing parsingStrategy: ArgumentArrayParsingStrategy = .remaining,
    help: ArgumentHelp? = nil,
    completion: CompletionKind? = nil
  ) where T: ExpressibleByArgument, Value == Array<T> {
    self.init(_parsedValue: .init { key in
      let arg = ArgumentDefinition(
        container: Array<T>.self,
        key: key,
        kind: .positional,
        help: help,
        parsingStrategy: parsingStrategy.base,
        initial: wrappedValue,
        completion: completion)

      return ArgumentSet(arg)
    })
  }

  /// Creates a property with no default value that reads an array from zero or
  /// more arguments.
  ///
  /// This method is called to initialize an array `Argument` with no default
  /// value such as:
  /// ```swift
  /// @Argument()
  /// var foo: [String]
  /// ```
  ///
  /// - Parameters:
  ///   - parsingStrategy: The behavior to use when parsing multiple values from
  ///   the command-line arguments.
  ///   - help: Information about how to use this argument.
  ///   - completion: Kind of completion provided to the user for this option.
  public init<T>(
    parsing parsingStrategy: ArgumentArrayParsingStrategy = .remaining,
    help: ArgumentHelp? = nil,
    completion: CompletionKind? = nil
  ) where T: ExpressibleByArgument, Value == Array<T> {
    self.init(_parsedValue: .init { key in
      let arg = ArgumentDefinition(
        container: Array<T>.self,
        key: key,
        kind: .positional,
        help: help,
        parsingStrategy: parsingStrategy.base,
        initial: nil,
        completion: completion)

      return ArgumentSet(arg)
    })
  }
}

// MARK: - @Argument Array<T> Initializers
extension Argument {
  /// Creates a property that reads an array from zero or more arguments,
  /// parsing each element with the given closure.
  ///
  /// - Parameters:
  ///   - wrappedValue: A default value to use for this property.
  ///   - parsingStrategy: The behavior to use when parsing multiple values from
  ///     the command-line arguments.
  ///   - help: Information about how to use this argument.
  ///   - completion: Kind of completion provided to the user for this option.
  ///   - transform: A closure that converts a string into this property's
  ///     element type or throws an error.
  public init<T>(
    wrappedValue: Array<T>,
    parsing parsingStrategy: ArgumentArrayParsingStrategy = .remaining,
    help: ArgumentHelp? = nil,
    completion: CompletionKind? = nil,
    transform: @escaping (String) throws -> T
  ) where Value == Array<T> {
    self.init(_parsedValue: .init { key in
      let arg = ArgumentDefinition(
        container: Array<T>.self,
        key: key,
        kind: .positional,
        help: help,
        parsingStrategy: parsingStrategy.base,
        transform: transform,
        initial: wrappedValue,
        completion: completion)

      return ArgumentSet(arg)
    })
  }

  /// Creates a property with no default value that reads an array from zero or
  /// more arguments, parsing each element with the given closure.
  ///
  /// This method is called to initialize an array `Argument` with no default
  /// value such as:
  /// ```swift
  /// @Argument(transform: baz)
  /// var foo: [String]
  /// ```
  ///
  /// - Parameters:
  ///   - parsingStrategy: The behavior to use when parsing multiple values from
  ///     the command-line arguments.
  ///   - help: Information about how to use this argument.
  ///   - completion: Kind of completion provided to the user for this option.
  ///   - transform: A closure that converts a string into this property's
  ///     element type or throws an error.
  public init<T>(
    parsing parsingStrategy: ArgumentArrayParsingStrategy = .remaining,
    help: ArgumentHelp? = nil,
    completion: CompletionKind? = nil,
    transform: @escaping (String) throws -> T
  ) where Value == Array<T> {
    self.init(_parsedValue: .init { key in
      let arg = ArgumentDefinition(
        container: Array<T>.self,
        key: key,
        kind: .positional,
        help: help,
        parsingStrategy: parsingStrategy.base,
        transform: transform,
        initial: nil,
        completion: completion)

      return ArgumentSet(arg)
    })
  }
}
