//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

/// Represents the path to a parsed field, annotated with ``Flag``, ``Option`` or
/// ``Argument``. It has a parent, which will either be ``InputKey/Parent/root``
/// if the field is on the root ``ParsableComand`` or ``AsyncParsableCommand``,
/// or it will have a ``InputKey/Parent/key(InputKey)`` if it is defined in
/// a ``ParsableArguments`` instance.
struct InputKey: Hashable {
  /// Describes the parent of an ``InputKey``.
  indirect enum Parent: Hashable {
    /// There is no parent key.
    case root
    /// There is a parent key.
    case key(InputKey)
    
    /// Initialises a parent depending on whether the key is provided.
    init(_ key: InputKey?) {
      if let key = key {
        self = .key(key)
      } else {
        self = .root
      }
    }
  }
  
  /// The name of the input key.
  let name: String
  
  /// The parent of this key.
  let parent: Parent
  
  
  /// Constructs a new ``InputKey``, cleaing the `name`, with the specified ``InputKey/Parent``.
  ///
  /// - Parameter name: The name of the key.
  /// - Parameter parent: The ``InputKey/Parent`` of the key.
  init(name: String, parent: Parent) {
    self.name = Self.clean(codingKey: name)
    self.parent = parent
  }
  
  @inlinable
  init?(path: [CodingKey]) {
    var parentPath = path
    guard let key = parentPath.popLast() else {
      return nil
    }
    self.name = Self.clean(codingKey: key)
    self.parent = Parent(InputKey(path: parentPath))
  }

  /// Constructs a new ``InputKey``, "cleaning the `value` and `path` if necessary.
  ///
  /// - Parameter value: The base value of the key.
  /// - Parameter path: The list of ``CodingKey`` values that lead to this one. May be empty.
  @inlinable
  init(name: String, path: [CodingKey]) {
    self.init(name: name, parent: Parent(InputKey(path: path)))
  }
  
  /// Constructs a new ``InputKey``, "cleaning the `value` and `path` if necessary.
  ///
  /// - Parameter codingKey: The base ``CodingKey``
  /// - Parameter path: The list of ``CodingKey`` values that lead to this one. May be empty.
  @inlinable
  init(codingKey: CodingKey, path: [CodingKey]) {
    self.init(name: codingKey.stringValue, parent: Parent(InputKey(path: path)))
  }
  
  /// The full path, including the ``parent`` and the ``name``.
  var fullPath: [String] {
    switch parent {
    case .root:
      return [name]
    case .key(let key):
      var parentPath = key.fullPath
      parentPath.append(name)
      return parentPath
    }
  }
  
  /// Returns a new ``InputKey`` with the same ``path`` and a new ``name``.
  /// The new value will be cleaned.
  ///
  /// - Parameter newName: The new ``String`` value.
  /// - Returns: A new ``InputKey`` with the cleaned value and the same ``path``.
  func with(newName: String) -> InputKey {
    return .init(name: Self.clean(codingKey: newName), parent: self.parent)
  }
}

extension InputKey {
  /// Property wrappers have underscore-prefixed names, so this returns a "clean"
  /// version of the `codingKey`, which has the leading `'_'` removed, if present.
  ///
  /// - Parameter codingKey: The key to clean.
  /// - Returns: The cleaned key.
  static func clean(codingKey: String) -> String {
    String(codingKey.first == "_" ? codingKey.dropFirst(1) : codingKey.dropFirst(0))
  }
  
  /// Property wrappers have underscore-prefixed names, so this returns a "clean"
  /// version of the `codingKey`, which has the leading `'_'` removed, if present.
  ///
  /// - Parameter codingKey: The key to clean.
  /// - Returns: The cleaned key.
  static func clean(codingKey: CodingKey) -> String {
    clean(codingKey: codingKey.stringValue)
  }
}

extension InputKey: CustomStringConvertible {
  var description: String {
    switch parent {
    case .key(let parent):
      return "\(parent).\(name)"
    case .root:
      return name
    }
  }
}
