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

/// A specification for how to represent a property as a command-line argument
/// label.
public struct NameSpecification: ExpressibleByArrayLiteral {
  /// An individual property name translation.
  public struct Element: Hashable, Sendable {
    internal enum Representation: Hashable {
      case long
      case customLong(_ name: String, withSingleDash: Bool)
      case short
      case customShort(_ char: Character, allowingJoined: Bool)
      case invalidLiteral(literal: String, message: String)
    }

    internal var base: Representation

    /// Use the property's name, converted to lowercase with words separated by
    /// hyphens.
    ///
    /// For example, a property named `allowLongNames` would be converted to the
    /// label `--allow-long-names`.
    public static var long: Element {
      self.init(base: .long)
    }

    /// Use the given string instead of the property's name.
    ///
    /// To create a single-dash argument, pass `true` as `withSingleDash`. Note
    /// that combining single-dash options and options with short,
    /// single-character names can lead to ambiguities for the user.
    ///
    /// - Parameters:
    ///   - name: The name of the option or flag.
    ///   - withSingleDash: A Boolean value indicating whether to use a single
    ///     dash as the prefix. If `false`, the name has a double-dash prefix.
    ///
    /// - Returns: A `long` name specification with the requested `name`.
    public static func customLong(
      _ name: String,
      withSingleDash: Bool = false
    ) -> Element {
      self.init(base: .customLong(name, withSingleDash: withSingleDash))
    }

    /// Use the first character of the property's name as a short option label.
    ///
    /// For example, a property named `verbose` would be converted to the
    /// label `-v`. Short labels can be combined into groups.
    public static var short: Element {
      self.init(base: .short)
    }

    /// Use the given character as a short option label.
    ///
    /// When passing `true` as `allowingJoined` in an `@Option` declaration,
    /// the user can join a value with the option name. For example, if an
    /// option is declared as `-D`, allowing joined values, a user could pass
    /// `-Ddebug` to specify `debug` as the value for that option.
    ///
    /// - Parameters:
    ///   - char: The name of the option or flag.
    ///   - allowingJoined: A Boolean value indicating whether this short name
    ///     allows a joined value.
    ///
    /// - Returns: A `short` name specification with the requested `char`.
    public static func customShort(
      _ char: Character,
      allowingJoined: Bool = false
    ) -> Element {
      self.init(base: .customShort(char, allowingJoined: allowingJoined))
    }

    /// An invalid literal, for a later diagnostic.
    internal static func invalidLiteral(
      literal str: String,
      message: String
    ) -> Element {
      self.init(base: .invalidLiteral(literal: str, message: message))
    }
  }

  var elements: [Element]

  public init<S>(_ sequence: S) where S: Sequence, Element == S.Element {
    self.elements = sequence.uniquing()
  }

  public init(arrayLiteral elements: Element...) {
    self.init(elements)
  }
}

extension NameSpecification: Sendable {}

extension NameSpecification.Element:
  ExpressibleByStringLiteral, ExpressibleByStringInterpolation
{
  public init(stringLiteral string: String) {
    // Check for spaces
    guard !string.contains(where: { $0 == " " }) else {
      self = .invalidLiteral(
        literal: string,
        message: "Can't use spaces in a name.")
      return
    }
    // Check for non-ascii chars
    guard string.allSatisfy({ $0.isValidForName }) else {
      self = .invalidLiteral(
        literal: string,
        message: "Must use only letters, numbers, underscores, or dashes.")
      return
    }

    let dashPrefixCount = string.prefix(while: { $0 == "-" }).count
    switch (dashPrefixCount, string.count) {
    case (0, _):
      self = .invalidLiteral(
        literal: string,
        message: "Need one or two prefix dashes.")
    case (1, 1), (2, 2):
      self = .invalidLiteral(
        literal: string,
        message: "Need at least one character after the dash prefix.")
    case (1, 2):
      // swift-format-ignore: NeverForceUnwrap
      // The case match validates the length.
      self = .customShort(string.dropFirst().first!)
    case (1, _):
      self = .customLong(String(string.dropFirst()), withSingleDash: true)
    case (2, _):
      self = .customLong(String(string.dropFirst(2)))
    default:
      self = .invalidLiteral(
        literal: string,
        message: "Can't have more than a two-dash prefix.")
    }
  }
}

extension NameSpecification:
  ExpressibleByStringLiteral, ExpressibleByStringInterpolation
{
  public init(stringLiteral string: String) {
    guard !string.isEmpty else {
      self = [
        .invalidLiteral(
          literal: string,
          message: "Can't use the empty string as a name.")
      ]
      return
    }

    self.elements = string.split(separator: " ").map {
      Element(stringLiteral: String($0))
    }
  }
}

extension NameSpecification {
  /// Use the property's name converted to lowercase with words separated by
  /// hyphens.
  ///
  /// For example, a property named `allowLongNames` would be converted to the
  /// label `--allow-long-names`.
  public static var long: NameSpecification { [.long] }

  /// Use the given string instead of the property's name.
  ///
  /// To create a single-dash argument, pass `true` as `withSingleDash`. Note
  /// that combining single-dash options and options with short,
  /// single-character names can lead to ambiguities for the user.
  ///
  /// - Parameters:
  ///   - name: The name of the option or flag.
  ///   - withSingleDash: A Boolean value indicating whether to use a single
  ///     dash as the prefix. If `false`, the name has a double-dash prefix.
  ///
  /// - Returns: A `long` name specification with the requested `name`.
  public static func customLong(
    _ name: String,
    withSingleDash: Bool = false
  ) -> NameSpecification {
    [.customLong(name, withSingleDash: withSingleDash)]
  }

  /// Use the first character of the property's name as a short option label.
  ///
  /// For example, a property named `verbose` would be converted to the
  /// label `-v`. Short labels can be combined into groups.
  public static var short: NameSpecification { [.short] }

  /// Use the given character as a short option label.
  ///
  /// When passing `true` as `allowingJoined` in an `@Option` declaration,
  /// the user can join a value with the option name. For example, if an
  /// option is declared as `-D`, allowing joined values, a user could pass
  /// `-Ddebug` to specify `debug` as the value for that option.
  ///
  /// - Parameters:
  ///   - char: The name of the option or flag.
  ///   - allowingJoined: A Boolean value indicating whether this short name
  ///     allows a joined value.
  ///
  /// - Returns: A `short` name specification with the requested `char`.
  public static func customShort(
    _ char: Character,
    allowingJoined: Bool = false
  ) -> NameSpecification {
    [.customShort(char, allowingJoined: allowingJoined)]
  }

  /// Combine the `.short` and `.long` specifications to allow both long
  /// and short labels.
  ///
  /// For example, a property named `verbose` would be converted to both the
  /// long `--verbose` and short `-v` labels.
  public static var shortAndLong: NameSpecification { [.long, .short] }
}

extension NameSpecification.Element {
  /// Creates the argument name for this specification element.
  internal func name(for key: InputKey) -> Name? {
    switch self.base {
    case .long:
      return .long(key.name.convertedToSnakeCase(separator: "-"))
    case .short:
      guard let c = key.name.first else {
        fatalError(
          "Key '\(key.name)' has not characters to form short option name.")
      }
      return .short(c)
    case .customLong(let name, let withSingleDash):
      return withSingleDash
        ? .longWithSingleDash(name)
        : .long(name)
    case .customShort(let name, let allowingJoined):
      return .short(name, allowingJoined: allowingJoined)
    case .invalidLiteral(let literal, let message):
      configurationFailure(
        "Invalid literal name '\(literal)' for property '\(key.name)': \(message)"
          .wrapped(to: 70))
    }
  }
}

extension NameSpecification {
  /// Creates the argument names for each element in the name specification.
  internal func makeNames(_ key: InputKey) -> [Name] {
    elements.compactMap { $0.name(for: key) }
  }
}

extension FlagInversion {
  /// Creates the enable and disable name(s) for the given flag.
  internal func enableDisableNamePair(
    for key: InputKey, name: NameSpecification
  ) -> ([Name], [Name]) {

    func makeNames(withPrefix prefix: String, includingShort: Bool) -> [Name] {
      name.elements.compactMap { element -> Name? in
        switch element.base {
        case .short, .customShort:
          return includingShort ? element.name(for: key) : nil
        case .long:
          let modifiedKey = InputKey(
            name: key.name.addingIntercappedPrefix(prefix), parent: key)
          return element.name(for: modifiedKey)
        case .customLong(let name, let withSingleDash):
          let modifiedName = name.addingPrefixWithAutodetectedStyle(prefix)
          let modifiedElement = NameSpecification.Element.customLong(
            modifiedName, withSingleDash: withSingleDash)
          return modifiedElement.name(for: key)
        case .invalidLiteral:
          fatalError("Invalid literals are diagnosed previously")
        }
      }
    }

    switch self.base {
    case .prefixedNo:
      return (
        name.makeNames(key),
        makeNames(withPrefix: "no", includingShort: false)
      )
    case .prefixedEnableDisable:
      return (
        makeNames(withPrefix: "enable", includingShort: true),
        makeNames(withPrefix: "disable", includingShort: false)
      )
    }
  }
}
