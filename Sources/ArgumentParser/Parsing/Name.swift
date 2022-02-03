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

enum Name {
  /// A name (usually multi-character) prefixed with `--` (2 dashes) or equivalent.
  case long(String)
  /// A single character name prefixed with `-` (1 dash) or equivalent.
  ///
  /// Usually supports mixing multiple short names with a single dash, i.e. `-ab` is equivalent to `-a -b`.
  case short(Character, allowingJoined: Bool = false)
  /// A long (multi-character) name prefixed with the short argument prefix
  /// (i.e. one dash or slash.)
  case longWithShortPrefix(String)
}

extension Name {
  init(_ baseName: Substring) {
    let (longPrefix, shortPrefix) = ParsingConvention.current.argumentPrefixes
    if baseName.hasPrefix(longPrefix) {
      self = .long(String(baseName.dropFirst(longPrefix.count)))
    } else if baseName.hasPrefix(shortPrefix) {
      if baseName.count == shortPrefix.count + 1 {
        // single character style such as "-x" or "+x" (depending on convention)
        self = .short(baseName.last!)
      } else { // long name with single dash
        self = .longWithShortPrefix(String(baseName.dropFirst()))
      }
    } else {
      fatalError("Attempted to create name for unprefixed argument \"\(baseName)\"")
    }
  }
}

// short argument names based on the synopsisString
// this will put the single - options before the -- options
extension Name: Comparable {
  static func < (lhs: Name, rhs: Name) -> Bool {
    return lhs.synopsisString < rhs.synopsisString
  }
}

extension Name: Hashable { }

extension Name {
  enum Case: Equatable {
    case long
    case short
    case longWithShortPrefix
  }

  var `case`: Case {
    switch self {
    case .short:
      return .short
    case .longWithShortPrefix:
      return .longWithShortPrefix
    case .long:
      return .long
    }
  }
}

extension Name {
  var synopsisString: String {
    let convention = ParsingConvention.current
    let (longPrefix, shortPrefix) = convention.argumentPrefixes
    switch self {
    case .long(let n):
      return "\(longPrefix)\(n)"
    case .short(let n, _):
      return "\(shortPrefix)\(n)"
    case .longWithShortPrefix(let n):
      return "\(shortPrefix)\(n)"
    }
  }
  
  var valueString: String {
    switch self {
    case .long(let n):
      return n
    case .short(let n, _):
      return String(n)
    case .longWithShortPrefix(let n):
      return n
    }
  }

  var allowsJoined: Bool {
    switch self {
    case .short(_, let allowingJoined):
      return allowingJoined
    default:
      return false
    }
  }
  
  /// The instance to match against user input -- this always has
  /// `allowingJoined` as `false`, since that's the way input is parsed.
  var nameToMatch: Name {
    switch self {
    case .long, .longWithShortPrefix: return self
    case .short(let c, _): return .short(c)
    }
  }
}

extension BidirectionalCollection where Element == Name {
  var preferredName: Name? {
    first { $0.case != .short } ?? first
  }

  var partitioned: [Name] {
    filter { $0.case == .short } + filter { $0.case != .short }
  }
}
