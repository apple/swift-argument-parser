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
    case environment(EnvironmentName)
  }
  
  private var _elements: Set<Element> = []
  var elements: [Element] {
    Array(_elements).sorted()
  }
  
  init() {
  }
  
  init(elements: [Element]) {
    _elements = Set(elements)
  }
  
  init(element: Element) {
    _elements = Set([element])
  }
  
  init(arrayLiteral elements: Element...) {
    self.init(elements: elements)
  }

  init(argumentIndex: SplitArguments.Index) {
    self.init(element: .argumentIndex(argumentIndex))
  }

  static func environment(_ name: EnvironmentName) -> InputOrigin {
    return InputOrigin(elements: [.environment(name)])
  }
}

// MARK: Set Like Operations

extension InputOrigin {
  mutating func insert(_ other: Element) {
    guard !_elements.contains(other) else { return }
    _elements.insert(other)
  }
  
  func inserting(_ other: Element) -> Self {
    guard !_elements.contains(other) else { return self }
    var result = self
    result.insert(other)
    return result
  }
  
  mutating func formUnion(_ other: InputOrigin) {
    _elements.formUnion(other._elements)
  }
}

// MARK: Other

extension InputOrigin {
  /// Does this origin contain elements that are from the command line arguments?
  var containsAnyArguments: Bool {
    return !_elements.allSatisfy {
      switch $0 {
      case .argumentIndex:
        return false
      case .environment:
        return true
      }
    }
  }

  func forEach(_ closure: (Element) -> Void) {
    _elements.forEach(closure)
  }
}

extension InputOrigin.Element {
  static func < (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case (.argumentIndex, .environment):
      return true
    case (.environment, .argumentIndex):
      return false
    case (.argumentIndex(let l), .argumentIndex(let r)):
      return l < r
    case (.environment(let l), .environment(let r)):
      return l.rawValue < r.rawValue
    }
  }
}
