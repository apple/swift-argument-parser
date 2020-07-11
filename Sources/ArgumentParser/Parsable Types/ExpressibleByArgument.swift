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

/// A type that can be expressed as a command-line argument.
public protocol ExpressibleByArgument {
  /// Creates a new instance of this type from a command-line-specified
  /// argument.
  init?(argument: String)

  /// Default representation value in help.
  ///
  /// Implement this method to customize default value representation in help.
  var defaultValueDescription: String { get }
  
  static var allValueStrings: [String] { get }

  static var defaultCompletionKind: CompletionKind { get }
}

extension ExpressibleByArgument {
  public var defaultValueDescription: String {
    "\(self)"
  }
  
  public static var allValueStrings: [String] { [] }

  public static var defaultCompletionKind: CompletionKind {
    .default
  }
}

extension ExpressibleByArgument where Self: CaseIterable {
  public static var allValueStrings: [String] {
    self.allCases.map { String(describing: $0) }
  }

  public static var defaultCompletionKind: CompletionKind {
    .list(allValueStrings)
  }
}

extension ExpressibleByArgument where Self: CaseIterable, Self: RawRepresentable, RawValue == String {
  public static var allValueStrings: [String] {
    self.allCases.map { $0.rawValue }
  }
}

extension String: ExpressibleByArgument {
  public init?(argument: String) {
    self = argument
  }
}

extension RawRepresentable where Self: ExpressibleByArgument, RawValue: ExpressibleByArgument {
  public init?(argument: String) {
    if let value = RawValue(argument: argument) {
      self.init(rawValue: value)
    } else {
      return nil
    }
  }
}

// MARK: LosslessStringConvertible

extension LosslessStringConvertible where Self: ExpressibleByArgument {
  public init?(argument: String) {
    self.init(argument)
  }
}

extension Int: ExpressibleByArgument {}
extension Int8: ExpressibleByArgument {}
extension Int16: ExpressibleByArgument {}
extension Int32: ExpressibleByArgument {}
extension Int64: ExpressibleByArgument {}
extension UInt: ExpressibleByArgument {}
extension UInt8: ExpressibleByArgument {}
extension UInt16: ExpressibleByArgument {}
extension UInt32: ExpressibleByArgument {}
extension UInt64: ExpressibleByArgument {}

extension Float: ExpressibleByArgument {}
extension Double: ExpressibleByArgument {}

extension Bool: ExpressibleByArgument {}
