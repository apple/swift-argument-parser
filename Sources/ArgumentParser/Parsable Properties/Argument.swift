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

/// A wrapper that represents a positional command-line argument.
///
/// Positional arguments are specified without a label and must appear in
/// the command-line arguments in declaration order.
///
///     struct Options: ParsableArguments {
///         @Argument var name: String
///         @Argument var greeting: String?
///     }
///
/// This program has two positional arguments; `name` is required, while
/// `greeting` is optional. It can be evoked as either `command Joseph Hello`
/// or simply `command Joseph`.
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
  
  /// The value presented by this property wrapper.
  public var wrappedValue: Value {
    get {
      switch _parsedValue {
      case .value(let v, _):
        return v
      case .definition:
        fatalError(directlyInitializedError)
      }
    }
    set {
      _parsedValue = .value(newValue, _parsedValue.source ?? ArgumentSource(source: []))
    }
  }
  
  public var projectedValue: ArgumentSource {
    switch _parsedValue {
    case .value(_, let source):
      return source
    case .definition:
      fatalError(directlyInitializedError)
    }
  }
}

extension Argument: CustomStringConvertible {
  public var description: String {
    switch _parsedValue {
    case .value(let v, _):
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
    help: ArgumentHelp?
  ) {
    self.init(_parsedValue: .init { key in
      ArgumentSet(key: key, kind: .positional, parseType: Value.self, name: NameSpecification.long, default: initial, help: help)
      })
  }

  /// Creates a property that reads its value from an argument.
  ///
  /// This method is deprecated, with usage split into two other methods below:
  /// - `init(wrappedValue:help:)` for properties with a default value
  /// - `init(help:)` for properties with no default value
  ///
  /// Existing usage of the `default` parameter should be replaced such as follows:
  /// ```diff
  /// -@Argument(default: "bar")
  /// -var foo: String
  /// +@Argument()
  /// +var foo: String = "bar"
  /// ```
  ///
  /// - Parameters:
  ///   - initial: A default value to use for this property. If `initial` is
  ///     `nil`, the user must supply a value for this argument.
  ///   - help: Information about how to use this argument.
  @available(*, deprecated, message: "Use regular property initialization for default values (`var foo: String = \"bar\"`)")
  public init(
    default initial: Value?,
    help: ArgumentHelp? = nil
  ) {
    self.init(
      initial: initial,
      help: help
    )
  }

  /// Creates a property with a default value provided by standard Swift default value syntax.
  ///
  /// This method is called to initialize an `Argument` with a default value such as:
  /// ```swift
  /// @Argument()
  /// var foo: String = "bar"
  /// ```
  ///
  /// - Parameters:
  ///   - wrappedValue: A default value to use for this property, provided implicitly by the compiler during propery wrapper initialization.
  ///   - help: Information about how to use this argument.
  public init(
    wrappedValue: Value,
    help: ArgumentHelp? = nil
  ) {
    self.init(
      initial: wrappedValue,
      help: help
    )
  }

  /// Creates a property with no default value.
  ///
  /// This method is called to initialize an `Argument` without a default value such as:
  /// ```swift
  /// @Argument()
  /// var foo: String
  /// ```
  ///
  /// - Parameters:
  ///   - help: Information about how to use this argument.
  public init(
    help: ArgumentHelp? = nil
  ) {
    self.init(
      initial: nil,
      help: help
    )
  }
}

/// The strategy to use when parsing multiple values from `@Option` arguments
/// into an array.
public enum ArgumentArrayParsingStrategy {
  /// Parse only unprefixed values from the command-line input, ignoring
  /// any inputs that have a dash prefix.
  ///
  /// For example, for a parsable type defined as following:
  ///
  ///     struct Options: ParsableArguments {
  ///         @Flag() var verbose: Bool
  ///         @Argument(parsing: .remaining) var words: [String]
  ///     }
  ///
  /// Parsing the input `--verbose one two` or `one two --verbose` would result
  /// in `Options(verbose: true, words: ["one", "two"])`. Parsing the input
  /// `one two --other` would result in an unknown option error for `--other`.
  ///
  /// This is the default strategy for parsing argument arrays.
  case remaining
  
  /// Parse all remaining inputs after parsing any known options or flags,
  /// including dash-prefixed inputs and the `--` terminator.
  ///
  /// For example, for a parsable type defined as following:
  ///
  ///     struct Options: ParsableArguments {
  ///         @Flag() var verbose: Bool
  ///         @Argument(parsing: .unconditionalRemaining) var words: [String]
  ///     }
  ///
  /// Parsing the input `--verbose one two --other` would include the `--other`
  /// flag in `words`, resulting in
  /// `Options(verbose: true, words: ["one", "two", "--other"])`.
  ///
  /// - Note: This parsing strategy can be surprising for users, particularly
  ///   when combined with options and flags. Prefer `remaining` whenever
  ///   possible, since users can always terminate options and flags with
  ///   the `--` terminator. With the `remaining` parsing strategy, the input
  ///   `--verbose -- one two --other` would have the same result as the above
  ///   example: `Options(verbose: true, words: ["one", "two", "--other"])`.
  case unconditionalRemaining
}

extension Argument {
  /// Creates an optional property that reads its value from an argument.
  ///
  /// The argument is optional for the caller of the command and defaults to 
  /// `nil`.
  ///
  /// - Parameter help: Information about how to use this argument.
  public init<T: ExpressibleByArgument>(
    help: ArgumentHelp? = nil
  ) where Value == T? {
    self.init(_parsedValue: .init { key in
      var arg = ArgumentDefinition(
        key: key,
        kind: .positional,
        parsingStrategy: .nextAsValue,
        parser: T.init(argument:),
        default: nil)
      arg.help.help = help
      return ArgumentSet(arg.optional)
    })
  }
  
  @available(*, deprecated, message: """
    Default values don't make sense for optional properties.
    Remove the 'default' parameter if its value is nil,
    or make your property non-optional if it's non-nil.
    """)
  public init<T: ExpressibleByArgument>(
    default initial: T?,
    help: ArgumentHelp? = nil
  ) where Value == T? {
    self.init(_parsedValue: .init { key in
      ArgumentSet(
        key: key,
        kind: .positional,
        parsingStrategy: .nextAsValue,
        parseType: T.self,
        name: .long,
        default: initial,
        help: help)
    })
  }

  /// Creates a property with an optional default value, intended to be called by other constructors to centralize logic.
  ///
  /// This private `init` allows us to expose multiple other similar constructors to allow for standard default property initialization while reducing code duplication.
  private init(
    initial: Value?,
    help: ArgumentHelp?,
    transform: @escaping (String) throws -> Value
  ) {
    self.init(_parsedValue: .init { key in
      let help = ArgumentDefinition.Help(options: [], help: help, key: key)
      let arg = ArgumentDefinition(kind: .positional, help: help, update: .unary({
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
      return ArgumentSet(alternatives: [arg])
      })
  }

  /// Creates a property that reads its value from an argument, parsing with
  /// the given closure.
  ///
  /// This method is deprecated, with usage split into two other methods below:
  /// - `init(wrappedValue:help:transform:)` for properties with a default value
  /// - `init(help:transform:)` for properties with no default value
  ///
  /// Existing usage of the `default` parameter should be replaced such as follows:
  /// ```diff
  /// -@Argument(default: "bar", transform: baz)
  /// -var foo: String
  /// +@Argument(transform: baz)
  /// +var foo: String = "bar"
  /// ```
  ///
  /// - Parameters:
  ///   - initial: A default value to use for this property.
  ///   - help: Information about how to use this argument.
  ///   - transform: A closure that converts a string into this property's
  ///     type or throws an error.
  @available(*, deprecated, message: "Use regular property initialization for default values (`var foo: String = \"bar\"`)")
  public init(
    default initial: Value?,
    help: ArgumentHelp? = nil,
    transform: @escaping (String) throws -> Value
  ) {
    self.init(
      initial: initial,
      help: help,
      transform: transform
    )
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
    transform: @escaping (String) throws -> Value
  ) {
    self.init(
      initial: wrappedValue,
      help: help,
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
    transform: @escaping (String) throws -> Value
  ) {
    self.init(
      initial: nil,
      help: help,
      transform: transform
    )
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
    help: ArgumentHelp? = nil
  )
    where Element: ExpressibleByArgument, Value == Array<Element>
  {
    self.init(_parsedValue: .init { key in
      let help = ArgumentDefinition.Help(options: [.isOptional, .isRepeating], help: help, key: key)
      var arg = ArgumentDefinition(
        kind: .positional,
        help: help,
        parsingStrategy: parsingStrategy == .remaining ? .nextAsValue : .allRemainingInput,
        update: .appendToArray(forType: Element.self, key: key),
        initial: { origin, values in
          values.set(wrappedValue, forKey: key, inputOrigin: origin)
        })
      arg.help.defaultValue = !wrappedValue.isEmpty ? "\(wrappedValue)" : nil
      return ArgumentSet(alternatives: [arg])
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
    transform: @escaping (String) throws -> Element
  )
    where Value == Array<Element>
  {
    self.init(_parsedValue: .init { key in
      let help = ArgumentDefinition.Help(options: [.isOptional, .isRepeating], help: help, key: key)
      var arg = ArgumentDefinition(
        kind: .positional,
        help: help,
        parsingStrategy: parsingStrategy == .remaining ? .nextAsValue : .allRemainingInput,
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
        initial: { origin, values in
          values.set(wrappedValue, forKey: key, inputOrigin: origin)
        })
      arg.help.defaultValue = !wrappedValue.isEmpty ? "\(wrappedValue)" : nil
      return ArgumentSet(alternatives: [arg])
    })
  }
  
  @available(*, deprecated, message: "Provide an empty array literal as a default value.")
  public init<Element>(
    parsing parsingStrategy: ArgumentArrayParsingStrategy = .remaining,
    help: ArgumentHelp? = nil
  )
    where Element: ExpressibleByArgument, Value == Array<Element>
  {
    self.init(wrappedValue: [], parsing: parsingStrategy, help: help)
  }

  @available(*, deprecated, message: "Provide an empty array literal as a default value.")
  public init<Element>(
    parsing parsingStrategy: ArgumentArrayParsingStrategy = .remaining,
    help: ArgumentHelp? = nil,
    transform: @escaping (String) throws -> Element
  )
    where Value == Array<Element>
  {
    self.init(wrappedValue: [], parsing: parsingStrategy, help: help, transform: transform)
  }
}
