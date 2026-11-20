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

/// Specifies where a given input came from.
///
/// When reading from the command line, a value might originate from a single
/// index, multiple indices, or from part of an index. For this command:
///
///     struct Example: ParsableCommand {
///         @Flag(name: .short) var verbose = false
///         @Flag(name: .short) var expert = false
///
///         @Option var count: Int
///     }
///
/// ...with this usage:
///
///     $ example -ve --count 5
///
/// The parsed value for the `count` property will come from indices `1` and
/// `2`, while the value for `verbose` will come from index `1`, sub-index `0`.
struct InputOrigin: Equatable, ExpressibleByArrayLiteral {
  enum Element: Comparable, Hashable {
    /// The input value came from a property's default value, not from a
    /// command line argument.
    case defaultValue

    /// The input value came from the specified index in the argument string.
    case argumentIndex(SplitArguments.Index)

    /// The input value came from a response file. Carries the innermost
    /// step (the file/line where the argument literally lives) and a
    /// `referencedFrom` link to the origin that included this file —
    /// forming a self-describing include chain terminated by an
    /// `.argumentIndex` at the outermost level.
    indirect case responseFile(
      step: InputOrigin.ResponseFileStep,
      referencedFrom: InputOrigin.Element)

    var baseIndex: Int? {
      switch self {
      case .defaultValue, .responseFile:
        return nil
      case .argumentIndex(let i):
        return i.inputIndex.rawValue
      }
    }

    var subIndex: Int? {
      switch self {
      case .defaultValue, .responseFile:
        return nil
      case .argumentIndex(let i):
        switch i.subIndex {
        case .complete: return nil
        case .sub(let n): return n
        }
      }
    }
  }

  private var _elements: Set<Element> = []
  var elements: [Element] {
    Array(_elements).sorted()
  }

  var firstElement: Element {
    guard !elements.isEmpty else {
      fatalError("Invalid 'InputOrigin' with no positions")
    }
    return elements[0]
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

  func forEach(_ closure: (Element) -> Void) {
    _elements.forEach(closure)
  }
}

extension InputOrigin {
  var isDefaultValue: Bool {
    _elements.count == 1 && _elements.first == .defaultValue
  }
}

extension InputOrigin {
  /// One step in a response-file include chain.
  ///
  /// `SplitArguments` records a chain for every post-expansion argument:
  /// the innermost step says where the argument literally lives (a file
  /// and line number, or an argv index for arguments that came straight
  /// from the command line), and successive steps describe the parent
  /// includes — outermost step is always `.argv(_)`.
  enum ResponseFileStep: Equatable, Hashable {
    /// The argument came from `path` at 1-based `line`.
    case file(path: String, line: Int)
    /// The argument (or the outermost @file reference) came from
    /// argv at this 0-based index.
    case argv(index: Int)
  }

  /// Information snapshot taken from `SplitArguments` at parse time so
  /// the error formatter can render the source location block on failure.
  ///
  /// Threaded into `ErrorMessageGenerator` via `CommandError`. The
  /// `hasResponseFile` flag, when `false`, errors messages render exactly as
  /// they did before the response file feature existed.
  struct FormattingContext: Equatable {
    /// True iff the input array contained at least one `@file` reference.
    var hasResponseFile: Bool

    /// Map from post-expansion `InputIndex` (raw value) to the chain that
    /// produced the argument at that position.
    ///
    /// Argv-only positions hold a single-step chain `[.argv(N)]`;
    /// response-file-origin positions hold a chain ordered
    /// innermost-first ending in `.argv(_)`.
    var responseFileChains: [Int: [ResponseFileStep]]

    /// The post-expansion argv strings.
    ///
    /// Indexed by the same key space as `responseFileChains`. Used by
    /// the dump generator to distinguish name-only tokens (`--tag`) from
    /// value-carrying tokens (`--tag=value` or a bare value) when
    /// pairing origins with array elements.
    var originalInput: [String]

    /// Returns the chain for an origin element, or `nil` if the element
    /// is `.defaultValue` or no chain was recorded for it.
    func responseFileChain(for origin: InputOrigin.Element)
      -> [ResponseFileStep]?
    {
      guard case .argumentIndex(let index) = origin else { return nil }
      return responseFileChains[index.inputIndex.rawValue]
    }

    /// Returns the raw argv token at the given origin's post-expansion
    /// index, or `nil` if the origin isn't an `.argumentIndex` or the
    /// index is out of range.
    func rawToken(at origin: InputOrigin.Element) -> String? {
      guard case .argumentIndex(let index) = origin else { return nil }
      let raw = index.inputIndex.rawValue
      guard raw < originalInput.count else { return nil }
      return originalInput[raw]
    }
  }
}

extension InputOrigin.Element {
  static func < (lhs: Self, rhs: Self) -> Bool {
    // Ordering (least → greatest):
    //   .argumentIndex(a) < .argumentIndex(b) when a < b
    //   .argumentIndex(_) < .responseFile(_,_) < .defaultValue
    // Two `.responseFile` values are ordered by lexicographically
    // comparing their flattened chain step arrays.
    switch (lhs, rhs) {
    case (.argumentIndex(let l), .argumentIndex(let r)):
      return l < r
    case (.argumentIndex, .responseFile), (.argumentIndex, .defaultValue):
      return true
    case (.responseFile, .defaultValue):
      return true
    case (.responseFile, .responseFile):
      return lhs.chainAsSteps().lexicographicallyPrecedes(rhs.chainAsSteps())
    case (.defaultValue, _), (.responseFile, .argumentIndex):
      return false
    }
  }
}

extension InputOrigin.ResponseFileStep: Comparable {
  /// Total-order comparison for stable placement in sorted collections.
  ///
  /// `.file` values compare by path, then line; `.argv` values compare
  /// by index; `.file` sorts before `.argv` when the cases differ.
  static func < (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case (.file(let lp, let ll), .file(let rp, let rl)):
      if lp != rp { return lp < rp }
      return ll < rl
    case (.argv(let l), .argv(let r)):
      return l < r
    case (.file, .argv):
      return true
    case (.argv, .file):
      return false
    }
  }
}

// MARK: - Response File Chain

extension InputOrigin.Element {
  /// Walks the linked `.responseFile` list and produces a flat array of
  /// steps from innermost to outermost.
  ///
  /// The terminating `.argumentIndex(idx)` becomes a
  /// `.argv(index: idx.inputIndex.rawValue)` step. Any non-`.responseFile`
  /// terminator that isn't `.argumentIndex` (which shouldn't occur in
  /// practice) is dropped from the output.
  func chainAsSteps() -> [InputOrigin.ResponseFileStep] {
    var steps: [InputOrigin.ResponseFileStep] = []
    var current: InputOrigin.Element = self
    while case .responseFile(let step, let ref) = current {
      steps.append(step)
      current = ref
    }
    if case .argumentIndex(let idx) = current {
      steps.append(.argv(index: idx.inputIndex.rawValue))
    }
    return steps
  }
}
