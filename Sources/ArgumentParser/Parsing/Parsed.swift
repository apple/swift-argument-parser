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

enum Parsed<Value> {
  /// The definition of how this value is to be parsed from command-line arguments.
  ///
  /// Internally, this wraps an `ArgumentSet`, but that’s not `public` since it’s
  /// an implementation detail.
  public struct Definition {
    var makeSet: (InputKey) -> ArgumentSet
  }
  
  case value(Value, ArgumentSource)
  case definition(Definition)
  
  internal init(_ makeSet: @escaping (InputKey) -> ArgumentSet) {
    self = .definition(Definition(makeSet: makeSet))
  }
  
  var value: Value? {
    switch self {
    case .value(let v, _): return v
    case .definition: return nil
    }
  }
  
  var source: ArgumentSource? {
    switch self {
    case .value(_, let s): return s
    case .definition: return nil
    }
  }
}

/// A type that wraps a `Parsed` instance to act as a property wrapper.
///
/// This protocol simplifies the implementations of property wrappers that
/// wrap the `Parsed` type.
internal protocol ParsedWrapper: Decodable, ArgumentSetProvider {
  associatedtype Value
  var _parsedValue: Parsed<Value> { get }
  init(_parsedValue: Parsed<Value>)
}

/// A `Parsed`-wrapper whose value type knows how to decode itself. Types that
/// conform to this protocol can initialize their values directly from a
/// `Decoder`.
internal protocol DecodableParsedWrapper: ParsedWrapper
  where Value: Decodable
{
  init(_parsedValue: Parsed<Value>)
}

extension ParsedWrapper {
  init(_decoder: Decoder) throws {
    guard let d = _decoder as? SingleValueDecoder else {
      throw ParserError.invalidState
    }
    guard let value = d.parsedElement?.value as? Value else {
      throw ParserError.noValue(forKey: d.parsedElement?.key ?? d.key)
    }
    
    let sourceIndexes: [Int] = d.parsedElement!.inputOrigin.elements.compactMap { x -> Int? in
      guard case .argumentIndex(let i) = x else { return nil }
      return i.inputIndex.rawValue
    }
    let sourceValues = sourceIndexes.map { d.underlying.values.originalInput[$0] }
    let source = ArgumentSource(source: Array(zip(sourceValues, sourceIndexes)))
    
    self.init(_parsedValue: .value(value, source))
  }
  
  func argumentSet(for key: InputKey) -> ArgumentSet {
    switch _parsedValue {
    case .value:
      fatalError("Trying to get the argument set from a resolved/parsed property.")
    case .definition(let a):
      return a.makeSet(key)
    }
  }
}

extension ParsedWrapper where Value: Decodable {
  init(_decoder: Decoder) throws {
    var value: Value
    let source: ArgumentSource
    
    do {
      value = try Value.init(from: _decoder)
      source = ArgumentSource(source: [])
    } catch {
      guard let d = _decoder as? SingleValueDecoder,
        let v = d.parsedElement?.value as? Value else {
        throw error
      }
      value = v
    
      let sourceIndexes: [Int] = d.parsedElement!.inputOrigin.elements.compactMap { x -> Int? in
        guard case .argumentIndex(let i) = x else { return nil }
        return i.inputIndex.rawValue
      }
      let sourceValues = sourceIndexes.map { d.underlying.values.originalInput[$0] }
      source = ArgumentSource(source: Array(zip(sourceValues, sourceIndexes)))
    }
    self.init(_parsedValue: .value(value, source))
  }
}
