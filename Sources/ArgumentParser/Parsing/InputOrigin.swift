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

/// Specifies where a given input came from.
///
/// When reading from the command line, a value might originate from multiple indices.
///
/// This is usually an index into the `SplitArguments`.
/// In some cases it can be multiple indices.
struct InputOrigin: Equatable, ExpressibleByArrayLiteral {
  enum Element: Comparable, Hashable {
    case argumentIndex(SplitArguments.Index)
  }
  
  private var _elements: Set<Element> = []
  var elements: [Element] {
    get {
      Array(_elements).sorted()
    }
    set {
      _elements = Set(newValue)
    }
  }
  
  init() {
  }
  
  init(elements: [Element]) {
    _elements = Set(elements)
  }
  
  init(element: Element) {
    _elements = Set([element])
  }
  
  init(arrayLiteral elements: InputOrigin.Element...) {
    self.init(elements: elements)
  }
  
  static func argumentIndex(_ index: SplitArguments.Index) -> InputOrigin {
    return InputOrigin(elements: [.argumentIndex(index)])
  }
  
  mutating func insert(_ other: InputOrigin.Element) {
    guard !_elements.contains(other) else { return }
    _elements.insert(other)
  }
  
  func inserting(_ other: InputOrigin.Element) -> InputOrigin {
    guard !_elements.contains(other) else { return self }
    var result = self
    result.insert(other)
    return result
  }
  
  mutating func formUnion(_ other: InputOrigin) {
    _elements.formUnion(other._elements)
  }
  
  func union(_ other: InputOrigin) -> InputOrigin {
    var result = self
    result._elements.formUnion(other._elements)
    return result
  }
  
  func isSubset(of other: Self) -> Bool {
    return _elements.isSubset(of: other._elements)
  }
  
  func forEach(_ closure: (Element) -> Void) {
    _elements.forEach(closure)
  }
}

extension InputOrigin.Element {
  static func < (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case (.argumentIndex(let l), .argumentIndex(let r)):
      return l < r
    }
  }
}
