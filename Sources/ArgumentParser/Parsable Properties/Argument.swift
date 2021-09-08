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

extension Argument: DecodableParsedWrapper where Value: Decodable {}

// MARK: Property Wrapper Initializers

extension Argument where Value: ExpressibleByArgument {
  /// Creates a property with an optional default value, intended to be called by other constructors to centralize logic.
  ///
  /// This private `init` allows us to expose multiple other similar constructors to allow for standard default property initialization while reducing code duplication.
  private init(
    initial: Value?,
    help: ArgumentHelp?,
    completion: CompletionKind?
  ) {
    self.init(_parsedValue: .init { key in
      ArgumentSet(key: key, kind: .positional, parseType: Value.self, name: NameSpecification.long, default: initial, help: help, completion: completion ?? Value.defaultCompletionKind)
      })
  }

  /// Creates a property with a default value provided by standard Swift default value syntax.
  ///
  /// This method is called to initialize an `Argument` with a default value such as:
  /// ```swift
  /// @Argument var foo: String = "bar"
  /// ```
  ///
  /// - Parameters:
  ///   - wrappedValue: A default value to use for this property, provided implicitly by the compiler during propery wrapper initialization.
  ///   - help: Information about how to use this argument.
  public init(
    wrappedValue: Value,
    help: ArgumentHelp? = nil,
    completion: CompletionKind? = nil
  ) {
    self.init(
      initial: wrappedValue,
      help: help,
      completion: completion
    )
  }

  /// Creates a property with no default value.
  ///
  /// This method is called to initialize an `Argument` without a default value such as:
  /// ```swift
  /// @Argument var foo: String
  /// ```
  ///
  /// - Parameters:
  ///   - help: Information about how to use this argument.
  public init(
    help: ArgumentHelp? = nil,
    completion: CompletionKind? = nil
  ) {
    self.init(
      initial: nil,
      help: help,
      completion: completion
    )
  }
}

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

extension Argument {
  /// Creates an optional property that reads its value from an argument.
  ///
  /// The argument is optional for the caller of the command and defaults to 
  /// `nil`.
  ///
  /// - Parameter help: Information about how to use this argument.
  public init<T: ExpressibleByArgument>(
    help: ArgumentHelp? = nil,
    completion: CompletionKind? = nil
  ) where Value == T? {
    self.init(_parsedValue: .init { key in
      var arg = ArgumentDefinition(
        key: key,
        kind: .positional,
        parsingStrategy: .default,
        parser: T.init(argument:),
        default: nil,
        completion: completion ?? T.defaultCompletionKind)
      arg.help.updateArgumentHelp(help: help)
      return ArgumentSet(arg.optional)
    })
  }
  
  /// Creates a property with an optional default value, intended to be called by other constructors to centralize logic.
  ///
  /// This private `init` allows us to expose multiple other similar constructors to allow for standard default property initialization while reducing code duplication.
  private init(
    initial: Value?,
    help: ArgumentHelp?,
    completion: CompletionKind?,
    transform: @escaping (String) throws -> Value
  ) {
    self.init(_parsedValue: .init { key in
      let help = ArgumentDefinition.Help(options: [], help: help, key: key)
      let arg = ArgumentDefinition(kind: .positional, help: help, completion: completion ?? .default, update: .unary({
        (origin, name, valueString, parsedValues) in
        do {
          let transformedValue = try transform(valueString)
          parsedValues.set(transformedValue, forKey: key, inputOrigin: origin)
        } catch {
          throw ParserError.unableToParseValue(origin, name, valueString, forKey: key, originalError: error)
        }
      }), initial: { origin, values in
        if let v = initial {
          values.set(v, forKey: key, inputOrigin: origin)
        }
      })
      return ArgumentSet(arg)
    })
  }

  /// Creates a property with a default value provided by standard Swift default value syntax, parsing with the given closure.
  ///
  /// This method is called to initialize an `Argument` with a default value such as:
  /// ```swift
  /// @Argument(transform: baz)
  /// var foo: String = "bar"
  /// ```
  ///
  /// - Parameters:
  ///   - wrappedValue: A default value to use for this property, provided implicitly by the compiler during property wrapper initialization.
  ///   - help: Information about how to use this argument.
  ///   - transform: A closure that converts a string into this property's type or throws an error.
  public init(
    wrappedValue: Value,
    help: ArgumentHelp? = nil,
    completion: CompletionKind? = nil,
    transform: @escaping (String) throws -> Value
  ) {
    self.init(
      initial: wrappedValue,
      help: help,
      completion: completion,
      transform: transform
    )
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
  ///   - transform: A closure that converts a string into this property's type or throws an error.
  public init(
    help: ArgumentHelp? = nil,
    completion: CompletionKind? = nil,
    transform: @escaping (String) throws -> Value
  ) {
    self.init(
      initial: nil,
      help: help,
      completion: completion,
      transform: transform
    )
  }


  /// Creates an array property with an optional default value, intended to be called by other constructors to centralize logic.
  ///
  /// This private `init` allows us to expose multiple other similar constructors to allow for standard default property initialization while reducing code duplication.
  private init<Element>(
    initial: Value?,
    parsingStrategy: ArgumentArrayParsingStrategy,
    help: ArgumentHelp?,
    completion: CompletionKind?
  )
    where Element: ExpressibleByArgument, Value == Array<Element>
  {
    self.init(_parsedValue: .init { key in
      // Assign the initial-value setter and help text for default value based on if an initial value was provided.
      let setInitialValue: ArgumentDefinition.Initial
      let helpDefaultValue: String?
      if let initial = initial {
        setInitialValue = { origin, values in
          values.set(initial, forKey: key, inputOrigin: origin)
        }
        helpDefaultValue = !initial.isEmpty ? initial.defaultValueDescription : nil
      } else {
        setInitialValue = { _, _ in }
        helpDefaultValue = nil
      }

      let help = ArgumentDefinition.Help(options: [.isOptional, .isRepeating], help: help, key: key)
      var arg = ArgumentDefinition(
        kind: .positional,
        help: help,
        completion: completion ?? Element.defaultCompletionKind,
        parsingStrategy: parsingStrategy.base,
        update: .appendToArray(forType: Element.self, key: key),
        initial: setInitialValue)
      arg.help.defaultValue = helpDefaultValue
      return ArgumentSet(arg)
    })
  }

  /// Creates a property that reads an array from zero or more arguments.
  ///
  /// - Parameters:
  ///   - initial: A default value to use for this property.
  ///   - parsingStrategy: The behavior to use when parsing multiple values
  ///     from the command-line arguments.
  ///   - help: Information about how to use this argument.
  public init<Element>(
    wrappedValue: Value,
    parsing parsingStrategy: ArgumentArrayParsingStrategy = .remaining,
    help: ArgumentHelp? = nil,
    completion: CompletionKind? = nil
  )
    where Element: ExpressibleByArgument, Value == Array<Element>
  {
    self.init(
      initial: wrappedValue,
      parsingStrategy: parsingStrategy,
      help: help,
      completion: completion
    )
  }

  /// Creates a property with no default value that reads an array from zero or more arguments.
  ///
  /// This method is called to initialize an array `Argument` with no default value such as:
  /// ```swift
  /// @Argument()
  /// var foo: [String]
  /// ```
  ///
  /// - Parameters:
  ///   - parsingStrategy: The behavior to use when parsing multiple values from the command-line arguments.
  ///   - help: Information about how to use this argument.
  public init<Element>(
    parsing parsingStrategy: ArgumentArrayParsingStrategy = .remaining,
    help: ArgumentHelp? = nil,
    completion: CompletionKind? = nil
  )
    where Element: ExpressibleByArgument, Value == Array<Element>
  {
    self.init(
      initial: nil,
      parsingStrategy: parsingStrategy,
      help: help,
      completion: completion
    )
  }

  /// Creates an array property with an optional default value, intended to be called by other constructors to centralize logic.
  ///
  /// This private `init` allows us to expose multiple other similar constructors to allow for standard default property initialization while reducing code duplication.
  private init<Element>(
    initial: Value?,
    parsingStrategy: ArgumentArrayParsingStrategy,
    help: ArgumentHelp?,
    completion: CompletionKind?,
    transform: @escaping (String) throws -> Element
  )
    where Value == Array<Element>
  {
    self.init(_parsedValue: .init { key in
      // Assign the initial-value setter and help text for default value based on if an initial value was provided.
      let setInitialValue: ArgumentDefinition.Initial
      let helpDefaultValue: String?
      if let initial = initial {
        setInitialValue = { origin, values in
          values.set(initial, forKey: key, inputOrigin: origin)
        }
        helpDefaultValue = !initial.isEmpty ? "\(initial)" : nil
      } else {
        setInitialValue = { _, _ in }
        helpDefaultValue = nil
      }

      let help = ArgumentDefinition.Help(options: [.isOptional, .isRepeating], help: help, key: key)
      var arg = ArgumentDefinition(
        kind: .positional,
        help: help,
        completion: completion ?? .default,
        parsingStrategy: parsingStrategy.base,
        update: .unary({
          (origin, name, valueString, parsedValues) in
          do {
              let transformedElement = try transform(valueString)
              parsedValues.update(forKey: key, inputOrigin: origin, initial: [Element](), closure: {
                $0.append(transformedElement)
              })
            } catch {
              throw ParserError.unableToParseValue(origin, name, valueString, forKey: key, originalError: error)
          }
        }),
        initial: setInitialValue)
      arg.help.defaultValue = helpDefaultValue
      return ArgumentSet(arg)
    })
  }

  /// Creates a property that reads an array from zero or more arguments,
  /// parsing each element with the given closure.
  ///
  /// - Parameters:
  ///   - initial: A default value to use for this property.
  ///   - parsingStrategy: The behavior to use when parsing multiple values
  ///     from the command-line arguments.
  ///   - help: Information about how to use this argument.
  ///   - transform: A closure that converts a string into this property's
  ///     element type or throws an error.
  public init<Element>(
    wrappedValue: Value,
    parsing parsingStrategy: ArgumentArrayParsingStrategy = .remaining,
    help: ArgumentHelp? = nil,
    completion: CompletionKind? = nil,
    transform: @escaping (String) throws -> Element
  )
    where Value == Array<Element>
  {
    self.init(
      initial: wrappedValue,
      parsingStrategy: parsingStrategy,
      help: help,
      completion: completion,
      transform: transform
    )
  }

  /// Creates a property with no default value that reads an array from zero or more arguments, parsing each element with the given closure.
  ///
  /// This method is called to initialize an array `Argument` with no default value such as:
  /// ```swift
  /// @Argument(tranform: baz)
  /// var foo: [String]
  /// ```
  ///
  /// - Parameters:
  ///   - parsingStrategy: The behavior to use when parsing multiple values from the command-line arguments.
  ///   - help: Information about how to use this argument.
  ///   - transform: A closure that converts a string into this property's element type or throws an error.
  public init<Element>(
    parsing parsingStrategy: ArgumentArrayParsingStrategy = .remaining,
    help: ArgumentHelp? = nil,
    completion: CompletionKind? = nil,
    transform: @escaping (String) throws -> Element
  )
    where Value == Array<Element>
  {
    self.init(
      initial: nil,
      parsingStrategy: parsingStrategy,
      help: help,
      completion: completion,
      transform: transform
    )
  }
}
