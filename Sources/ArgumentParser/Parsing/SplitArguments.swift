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

/// A single `-f`, `--foo`, or `--foo=bar`.
///
/// When parsing, we might see `"--foo"` or `"--foo=bar"`.
enum ParsedArgument: Equatable, CustomStringConvertible {
  /// `--foo` or `-f`
  case name(Name)
  /// `--foo=bar`
  case nameWithValue(Name, String)
  
  init<S: StringProtocol>(_ str: S) where S.SubSequence == Substring {
    let indexOfEqualSign = str.firstIndex(of: "=") ?? str.endIndex
    let (baseName, value) = (str[..<indexOfEqualSign], str[indexOfEqualSign...].dropFirst())
    let name = Name(baseName)
    self = value.isEmpty
      ? .name(name)
      : .nameWithValue(name, String(value))
  }
  
  /// An array of short arguments and their indices in the original base
  /// name, if this argument could be a combined pack of short arguments.
  ///
  /// For `subarguments` to be non-empty:
  ///
  /// 1) This must have a single-dash prefix (not `--foo`)
  /// 2) This must not have an attached value (not `-foo=bar`)
  var subarguments: [(Int, ParsedArgument)] {
    switch self {
    case .nameWithValue: return []
    case .name(let name):
      switch name {
      case .longWithSingleDash(let base):
        return base.enumerated().map {
          ($0, .name(.short($1)))
        }
      case .long, .short:
        return []
      }
    }
  }
  
  var name: Name {
    switch self {
    case let .name(n): return n
    case let .nameWithValue(n, _): return n
    }
  }
  
  var value: String? {
    switch self {
    case .name: return nil
    case let .nameWithValue(_, v): return v
    }
  }

  var description: String {
    switch self {
    case .name(let name):
      return name.synopsisString
    case .nameWithValue(let name, let value):
      return "\(name.synopsisString)=\(value)"
    }
  }
}

/// A parsed version of command-line arguments.
///
/// This is a flat list of *values* and *options*. E.g. the
/// arguments `["--foo", "bar"]` would be parsed into
/// `[.option(.name(.long("foo"))), .value("bar")]`.
struct SplitArguments {
  enum Element: Equatable {
    case option(ParsedArgument)
    case value(String)
    /// The `--` marker
    case terminator
  }
  
  /// The index into the (original) input.
  ///
  /// E.g. for `["--foo", "-vh"]` there are index positions 0 (`--foo`) and
  /// 1 (`-vh`).
  struct InputIndex: RawRepresentable, Hashable, Comparable {
    var rawValue: Int
    
    static func <(lhs: InputIndex, rhs: InputIndex) -> Bool {
      lhs.rawValue < rhs.rawValue
    }
    
    var next: InputIndex {
      InputIndex(rawValue: rawValue + 1)
    }
  }
  
  /// The index into an input index position.
  ///
  /// E.g. the input `"-vh"` will be split into the elements `-v`, and `-h`
  /// each with its own subindex.
  enum SubIndex: Hashable, Comparable {
    case complete
    case sub(Int)
    
    static func <(lhs: SubIndex, rhs: SubIndex) -> Bool {
      switch (lhs, rhs) {
      case (.complete, .sub):
        return true
      case (.sub(let l), .sub(let r)) where l < r:
        return true
      default:
        return false
      }
    }
  }
  
  /// Tracks both the index into the original input and the index into the split arguments (array of elements).
  struct Index: Hashable, Comparable {
    static func < (lhs: SplitArguments.Index, rhs: SplitArguments.Index) -> Bool {
      if lhs.inputIndex < rhs.inputIndex {
        return true
      } else if lhs.inputIndex == rhs.inputIndex {
        return lhs.subIndex < rhs.subIndex
      } else {
        return false
      }
    }
    
    var inputIndex: InputIndex
    var subIndex: SubIndex
  }
  
  var elements: [(index: Index, element: Element)]
  var originalInput: [String]
}

extension SplitArguments.Element: CustomDebugStringConvertible {
  var debugDescription: String {
    switch self {
    case .option(.name(let name)):
      return name.synopsisString
    case .option(.nameWithValue(let name, let value)):
      return name.synopsisString + "; value '\(value)'"
    case .value(let value):
      return "value '\(value)'"
    case .terminator:
      return "terminator"
    }
  }
}

extension SplitArguments.Index: CustomStringConvertible {
  var description: String {
    switch subIndex {
    case .complete: return "\(inputIndex.rawValue)"
    case .sub(let sub): return "\(inputIndex.rawValue).\(sub)"
    }
  }
}

extension SplitArguments: CustomStringConvertible {
  var description: String {
    guard !isEmpty else { return "<empty>" }
    return elements
      .map { (index, element) -> String in
        switch element {
        case .option(.name(let name)):
          return "[\(index)] \(name.synopsisString)"
        case .option(.nameWithValue(let name, let value)):
          return "[\(index)] \(name.synopsisString)='\(value)'"
        case .value(let value):
          return "[\(index)] '\(value)'"
        case .terminator:
          return "[\(index)] --"
        }
    }
    .joined(separator: " ")
  }
}

extension SplitArguments.Element {
  var isValue: Bool {
    switch self {
    case .value: return true
    case .option, .terminator: return false
    }
  }
}

extension SplitArguments {
  var isEmpty: Bool {
    elements.isEmpty
  }
  
  subscript(position: Index) -> Element? {
    return elements.first {
      $0.0 == position
      }?.1
  }
  
  /// Returns the original input string at the given origin, or `nil` if
  /// `origin` is a sub-index.
  func originalInput(at origin: InputOrigin.Element) -> String? {
    guard case let .argumentIndex(index) = origin else {
      return nil
    }
    return originalInput[index.inputIndex.rawValue]
  }
  
  mutating func popNext() -> (InputOrigin.Element, Element)? {
    guard let (index, value) = elements.first else { return nil }
    elements.remove(at: 0)
    return (.argumentIndex(index), value)
  }
  
  func peekNext() -> (InputOrigin.Element, Element)? {
    guard let (index, value) = elements.first else { return nil }
    return (.argumentIndex(index), value)
  }
  
  /// Pops the element immediately after the given index, if it is a `.value`.
  ///
  /// This is used to get the next value in `-fb name` where `name` is the
  /// value for `-f`, or `--foo name` where `name` is the value for `--foo`.
  /// If `--foo` expects a value, an input of `--foo --bar name` will return
  /// `nil`, since the option `--bar` comes before the value `name`.
  mutating func popNextElementIfValue(after origin: InputOrigin.Element) -> (InputOrigin.Element, String)? {
    // Look for the index of the input that comes from immediately after
    // `origin` in the input string. We look at the input index so that
    // packed short options can be followed, in order, by their values.
    // e.g. "-fn f-value n-value"
    guard
      case .argumentIndex(let after) = origin,
      let elementIndex = elements.firstIndex(where: { $0.0.inputIndex > after.inputIndex })
      else { return nil }
    
    // Only succeed if the element is a value (not prefixed with a dash)
    guard case .value(let value) = elements[elementIndex].1
      else { return nil }
    
    let matchedArgumentIndex = elements[elementIndex].0
    elements.remove(at: elementIndex)
    return (.argumentIndex(matchedArgumentIndex), value)
  }
  
  /// Pops the next `.value` after the given index.
  ///
  /// This is used to get the next value in `-f -b name` where `name` is the value of `-f`.
  mutating func popNextValue(after origin: InputOrigin.Element) -> (InputOrigin.Element, String)? {
    guard case .argumentIndex(let after) = origin else { return nil }
    for (index, element) in elements.enumerated() {
      guard
        element.0 > after,
        case .value(let value) = element.1
        else { continue }
      elements.remove(at: index)
      return (.argumentIndex(element.0), value)
    }
    return nil
  }
  
  /// Pops the element after the given index as a value.
  ///
  /// This will re-interpret `.option` and `.terminator` as values, i.e.
  /// read from the `originalInput`.
  ///
  /// For an input such as `--a --b foo`, if passed the origin of `--a`,
  /// this will first pop the value `--b`, then the value `foo`.
  mutating func popNextElementAsValue(after origin: InputOrigin.Element) -> (InputOrigin.Element, String)? {
    guard case .argumentIndex(let after) = origin else { return nil }
    // Elements are sorted by their `InputIndex`. Find the first `InputIndex`
    // after `origin`:
    guard let unconditionalIndex = elements.first(where: { (index, _) in index.inputIndex > after.inputIndex })?.0.inputIndex else { return nil }
    let nextIndex = Index(inputIndex: unconditionalIndex, subIndex: .complete)
    // Remove all elements with this `InputIndex`:
    remove(at: nextIndex)
    // Return the original input
    return (.argumentIndex(nextIndex), originalInput[unconditionalIndex.rawValue])
  }
  
  /// Pops the next element if it is a value.
  ///
  /// If the current elements are `--b foo`, this will return `nil`. If the
  /// elements are `foo --b`, this will return the value `foo`.
  mutating func popNextElementIfValue() -> (InputOrigin.Element, String)? {
    guard
      let (index, element) = elements.first,
      case .value(let value) = element
      else { return nil }
    elements.remove(at: 0)
    return (.argumentIndex(index), value)
  }
  
  /// Finds and "pops" the next element that is a value.
  ///
  /// If the current elements are `--a --b foo`, this will remove and return
  /// `foo`.
  mutating func popNextValue() -> (Index, String)? {
    guard let idx = elements.firstIndex(where: {
      switch $0.element {
      case .option: return false
      case .value: return true
      case .terminator: return false
      }
    }) else { return nil }
    let e = elements[idx]
    elements.remove(at: idx)
    guard case let .value(v) = e.element else { fatalError() }
    return (e.index, v)
  }
  
  func peekNextValue() -> (Index, String)? {
    guard let idx = elements.firstIndex(where: {
      switch $0.element {
      case .option: return false
      case .value: return true
      case .terminator: return false
      }
    }) else { return nil }
    let e = elements[idx]
    guard case let .value(v) = e.element else { fatalError() }
    return (e.index, v)
  }
  
  /// Removes the element(s) at the given `Index`.
  ///
  /// - Note: This may remove multiple elements.
  ///
  /// For combined _short_ arguments such as `-ab`, these will gets parsed into
  /// 3 elements: The _long with short dash_ `ab`, and 2 _short_ `a` and `b`. All of these
  /// will have the same `inputIndex` but different `subIndex`. When either of the short ones
  /// is removed, that will remove the _long with short dash_ as well. Likewise, if the
  /// _long with short dash_ is removed, that will remove both of the _short_ elements.
  mutating func remove(at position: Index) {
    if case .complete = position.subIndex {
      // When removing a `.complete`, we need to remove _all_
      // elements that have the same `InputIndex`.
      elements.removeAll { (index, _) -> Bool in
        index.inputIndex == position.inputIndex
      }
    } else {
      // When removing a `.sub` (i.e. non-`.complete`), we need to
      // remove any `.complete`.
      elements.removeAll { (index, _) -> Bool in
        index == position ||
          ((index.inputIndex == position.inputIndex) && (index.subIndex == .complete))
      }
    }
  }
  
  mutating func removeAll(in origin: InputOrigin) {
    origin.forEach {
      remove(at: $0)
    }
  }
  
  /// Removes the element(s) at the given position.
  ///
  /// - Note: This may remove multiple elements.
  mutating func remove(at origin: InputOrigin.Element) {
    guard case .argumentIndex(let i) = origin else { return }
    remove(at: i)
  }
  
  func coalescedExtraElements() -> [(InputOrigin, String)] {
    let completeIndexes: [InputIndex] = elements
      .compactMap {
        guard case .complete = $0.0.subIndex else { return nil }
        return $0.0.inputIndex
    }
    
    // Now return all elements that are either:
    // 1) `.complete`
    // 2) `.sub` but not in `completeIndexes`
    
    let extraElements: [(Index, Element)] = elements.filter {
      switch $0.0.subIndex {
      case .complete:
        return true
      case .sub:
        return !completeIndexes.contains($0.0.inputIndex)
      }
    }
    return extraElements.map { index, element -> (InputOrigin, String) in
      let input: String
      switch index.subIndex {
      case .complete:
        input = originalInput[index.inputIndex.rawValue]
      case .sub:
        if case .option(let option) = element {
          input = String(describing: option)
        } else {
          // Odd case. Fall back to entire input at that index:
          input = originalInput[index.inputIndex.rawValue]
        }
      }
      return (.init(argumentIndex: index), input)
    }
  }
}

extension SplitArguments {
  /// Parses the given input into an array of `Element`.
  ///
  /// - Parameter arguments: The input from the command line.
  init(arguments: [String]) throws {
    self.init(elements: [], originalInput: arguments)
    
    var inputIndex = InputIndex(rawValue: 0)
    
    func append(_ element: SplitArguments.Element, sub: Int? = nil) {
      let subIndex = sub.flatMap { SubIndex.sub($0) } ?? SubIndex.complete
      let index = Index(inputIndex: inputIndex, subIndex: subIndex)
      elements.append((index, element))
    }
    
    var args = arguments[arguments.startIndex..<arguments.endIndex]
    argLoop: while let arg = args.popFirst() {
      defer {
        inputIndex = inputIndex.next
      }
      
      if let nonDashIdx = arg.firstIndex(where: { $0 != "-" }) {
        let dashCount = arg.distance(from: arg.startIndex, to: nonDashIdx)
        let remainder = arg[nonDashIdx..<arg.endIndex]
        switch dashCount {
        case 0:
          append(.value(arg))
        case 1:
          // Long option:
          let parsed = try ParsedArgument(longArgWithSingleDashRemainder: remainder)
          // Multiple short options:
          let parts = parsed.subarguments
          switch parts.count {
          case 0:
            // Long only:
            append(.option(parsed))
          case 1:
            // Short only:
            if let c = remainder.first {
              append(.option(.name(.short(c))))
            }
          default:
            append(.option(parsed))
            for (sub, a) in parts {
              append(.option(a), sub: sub)
            }
          }
        case 2:
          let parsed = ParsedArgument(arg)
          append(.option(parsed))
        default:
          throw ParserError.invalidOption(arg)
        }
      } else {
        // All dashes
        let dashCount = arg.count
        switch dashCount {
        case 0:
          // Empty string
          append(.value(arg))
        case 1:
          append(.value(arg))
        case 2:
          // We found the 1st "--". All the remaining are positional.
          // We need to mark this index as used:
          append(.terminator)
          break argLoop
        default:
          throw ParserError.invalidOption(arg)
        }
      }
      
    }
    args.forEach {
      append(.value($0))
      inputIndex = InputIndex(rawValue: inputIndex.rawValue + 1)
    }
  }
}

private extension ParsedArgument {
  init(longArgRemainder remainder: Substring) throws {
    try self.init(longArgRemainder: remainder, makeName: { Name.long(String($0)) })
  }
  
  init(longArgWithSingleDashRemainder remainder: Substring) throws {
    try self.init(longArgRemainder: remainder, makeName: { Name.longWithSingleDash(String($0)) })
  }
  
  init(longArgRemainder remainder: Substring, makeName: (Substring) -> Name) throws {
    if let equalIdx = remainder.firstIndex(of: "=") {
      let name = remainder[remainder.startIndex..<equalIdx]
      guard !name.isEmpty else {
        throw ParserError.invalidOption(makeName(remainder).synopsisString)
      }
      let after = remainder.index(after: equalIdx)
      let value = String(remainder[after..<remainder.endIndex])
      self = .nameWithValue(makeName(name), value)
    } else {
      self = .name(makeName(remainder))
    }
  }
  
  static func shortOptions(shortArgRemainder: Substring) throws -> [ParsedArgument] {
    var result: [ParsedArgument] = []
    var remainder = shortArgRemainder
    while let char = remainder.popFirst() {
      guard char.isLetter || char.isNumber else {
        throw ParserError.nonAlphanumericShortOption(char)
      }
      result.append(.name(.short(char)))
    }
    return result
  }
}
