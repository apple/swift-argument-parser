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

/// A specification for how to represent a property as a command-line argument
/// label.
public struct NameSpecification: ExpressibleByArrayLiteral {
  /// An individual property name translation.
  public struct Element: Hashable {
    internal enum Representation: Hashable {
      case long
      case customLong(_ name: String, withShortPrefix: Bool)
      case short
      case customShort(_ char: Character, allowingJoined: Bool)
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
    
    @available(*, deprecated, message: "Use .customLong(_:withShortPrefix:) instead. Some platforms may use characters other than dashes for short prefixes.")
    public static func customLong(_ name: String, withSingleDash: Bool) -> Element {
      return .customLong(name, withShortPrefix: withSingleDash)
    }
    
    /// Use the given string instead of the property's name.
    ///
    /// To create an argument with a long name that uses a short prefix, pass
    /// `true` as `withShortPrefix`. Note that combining short-prefixed options
    /// and options with short, single-character names can lead to ambiguities
    /// for the user.
    ///
    /// - Parameters:
    ///   - name: The name of the option or flag.
    ///   - withShortPrefix: A Boolean value indicating whether to use a short
    ///     prefix (for instance, `"-"` rather than the typical `"--"`.)
    public static func customLong(_ name: String, withShortPrefix: Bool = false) -> Element {
      self.init(base: .customLong(name, withShortPrefix: withShortPrefix))
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
    public static func customShort(_ char: Character, allowingJoined: Bool = false) -> Element {
      self.init(base: .customShort(char, allowingJoined: allowingJoined))
    }
  }
  var elements: [Element]
  
  public init<S>(_ sequence: S) where S : Sequence, Element == S.Element {
    self.elements = sequence.uniquing()
  }
  
  public init(arrayLiteral elements: Element...) {
    self.init(elements)
  }
}

extension NameSpecification {
  /// Use the property's name converted to lowercase with words separated by
  /// hyphens.
  ///
  /// For example, a property named `allowLongNames` would be converted to the
  /// label `--allow-long-names`.
  public static var long: NameSpecification { [.long] }
  
  @available(*, deprecated, message: "Use .customLong(_:withShortPrefix:) instead. Some platforms may use characters other than dashes for short prefixes.")
  public static func customLong(_ name: String, withSingleDash: Bool) -> NameSpecification {
    return customLong(name, withShortPrefix: withSingleDash)
  }
  
  /// Use the given string instead of the property's name.
  ///
  /// To create an argument with a long name that uses a short prefix, pass
  /// `true` as `withShortPrefix`. Note that combining short-prefixed options
  /// and options with short, single-character names can lead to ambiguities for
  /// the user.
  ///
  /// - Parameters:
  ///   - name: The name of the option or flag.
  ///   - withShortPrefix: A Boolean value indicating whether to use a short
  ///     prefix (for instance, `"-"` rather than the typical `"--"`.)
  public static func customLong(_ name: String, withShortPrefix: Bool = false) -> NameSpecification {
    [.customLong(name, withShortPrefix: withShortPrefix)]
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
  public static func customShort(_ char: Character, allowingJoined: Bool = false) -> NameSpecification {
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
      return .long(ParsingConvention.current.convertStringToArgumentNamingConvention(key.rawValue))
    case .short:
      guard let c = key.rawValue.first else { fatalError("Key '\(key.rawValue)' has not characters to form short option name.") }
      return .short(c)
    case .customLong(let name, let withShortPrefix):
      return withShortPrefix
        ? .longWithShortPrefix(name)
        : .long(name)
    case .customShort(let name, let allowingJoined):
      return .short(name, allowingJoined: allowingJoined)
    }
  }
}

extension NameSpecification {
  /// Creates the argument names for each element in the name specification.
  internal func makeNames(_ key: InputKey) -> [Name] {
    return elements.compactMap { $0.name(for: key) }
  }
}

extension FlagInversion {
  /// Creates the enable and disable name(s) for the given flag.
  internal func enableDisableNamePair(for key: InputKey, name: NameSpecification) -> ([Name], [Name]) {
    
    func makeNames(withPrefix prefix: String, includingShort: Bool) -> [Name] {
      return name.elements.compactMap { element -> Name? in
        switch element.base {
        case .short, .customShort:
          return includingShort ? element.name(for: key) : nil
        case .long:
          let modifiedKey = InputKey(rawValue: key.rawValue.addingPrefix(prefix, using: .swiftVariableCase))
          return element.name(for: modifiedKey)
        case .customLong(let name, let withShortPrefix):
          let nameConvention = name.autoDetectedNamingConvention ?? ParsingConvention.current.argumentNamingConvention
          let modifiedName = name.addingPrefix(prefix, using: nameConvention)
          let modifiedElement = NameSpecification.Element.customLong(modifiedName, withShortPrefix: withShortPrefix)
          return modifiedElement.name(for: key)
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
