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

struct InputKey: RawRepresentable, Equatable {
  var rawValue: String

  init(rawValue: String) {
    self.rawValue = rawValue
  }
  
  init<C: CodingKey>(_ codingKey: C) {
    self.rawValue = codingKey.stringValue
  }
  
  static let terminator = InputKey(rawValue: "__terminator")
}

/// The resulting values after parsing the command-line arguments.
///
/// This is a flat key-value list of values.
struct ParsedValues {
  struct Element {
    var key: InputKey
    var value: Any
    /// Where in the input that this came from.
    var inputOrigin: InputOrigin
  }
  
  /// These are the parsed key-value pairs.
  var elements: [Element] = []
  
  /// This is the *original* array of arguments that this was parsed from.
  ///
  /// This is used for error output generation.
  var originalInput: [String]
}

enum LenientParsedValues {
  case success(ParsedValues)
  case partial(ParsedValues, Swift.Error)
}

extension ParsedValues {
  mutating func set(_ new: Any, forKey key: InputKey, inputOrigin: InputOrigin) {
    set(Element(key: key, value: new, inputOrigin: inputOrigin))
  }
  
  mutating func set(_ element: Element) {
    if let index = elements.firstIndex(where: { $0.key == element.key }) {
      // Merge the source values. We need to keep track
      // of any previous source indexes we have used for
      // this key.
      var e = element
      e.inputOrigin.formUnion(elements[index].inputOrigin)
      elements[index] = e
    } else {
      elements.append(element)
    }
  }
  
  func element(forKey key: InputKey) -> Element? {
    return elements.first(where: { $0.key == key })
  }
  
  mutating func update<A>(forKey key: InputKey, inputOrigin: InputOrigin, initial: A, closure: (inout A) -> Void) {
    var e = element(forKey: key) ?? Element(key: key, value: initial, inputOrigin: InputOrigin())
    var v = (e.value as? A ) ?? initial
    closure(&v)
    e.value = v
    e.inputOrigin.formUnion(inputOrigin)
    set(e)
  }
}
