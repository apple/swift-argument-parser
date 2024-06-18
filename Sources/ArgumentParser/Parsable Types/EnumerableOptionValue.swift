//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

/// A type that represents the different possible values by a `@Option` property.
///
/// For example, consider an enumeration `Color` that can be used as the type of an `@Option` property:
///
/// ```swift
/// enum Color: String, EnumerableOptionValue {
///   case red
///   case blue
///   case yellow
///
///   public var description: String {
///     switch self {
///     case .red:
///       return "A red color!"
///     case .blue:
///       return "A blue color!"
///     case .yellow:
///       return "A yellow color!"
///     }
///   }
/// }
///
/// struct Hat: ParsableCommand {
///     @Option(abstract: "A color for my hat.") var color: Color
///
///     mutating func run() {
///       print("The color of my hat is: \(color.rawValue)")
///     }
/// }
/// ```
///
/// As `EnumerableOptionValue` implements `RawRepresentable`, it is up to the user to implement the required properties. Much
/// of this can be omitted if the `EumerableOptionValue` type specifies a raw type that it implements, but the user will be
/// required to implement a `description` property in every case, like the above example.
///
/// By default, the `name` of an `EnumerableOptionValue` is its raw value. To provide a custom name, implement the `name` property
/// in your `EnumerableOptionValue` type, like this:
///
/// ```swift
/// extension Color {
///   public var name: String {
///     switch self {
///       case .red:
///         return "Red Color"
///       case .blue:
///         return "Blue Color"
///       case .yellow:
///         return "Yellow Color"
///     }
///   }
/// }
/// ```
public protocol EnumerableOptionValue: CaseIterable, ExpressibleByArgument, RawRepresentable where RawValue: ExpressibleByArgument, AllCases == [Self] {
  /// The  name of the `@Option` value.
  ///
  /// The default implementation for this property returns the `rawValue` of this type.
  /// Implement this property in your custom `EnumerableOptionValue` type to
  /// provide a custom name.
  var name: String { get }

  /// The description of the `@Option` value. This can be a brief description about the value's functionality.
  var description: String { get }
}

extension EnumerableOptionValue {
  public init?(argument: String) {
    guard let rawValue = RawValue(argument: argument),
          let value = Self.init(rawValue: rawValue)
    else {
      return nil
    }

    self = value
  }

  public var name: String {
    String(describing: rawValue)
  }
}
