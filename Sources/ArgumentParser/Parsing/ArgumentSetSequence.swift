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

/// Allows iteration over arguments in an `ArgumentSet`.
extension ArgumentSet: Sequence {
  func makeIterator() -> Iterator {
    return Iterator(set: self)
  }
  
  var underestimatedCount: Int { return 0 }
  
  struct Iterator: IteratorProtocol {
    enum Content {
      case arguments(ArraySlice<ArgumentDefinition>)
      case sets([Iterator])
      case empty
    }
    
    var content: Content
    
    init(set: ArgumentSet) {
      switch set.content {
      case .arguments(let a):
        self.content = .arguments(a[a.startIndex..<a.endIndex])
      case .sets(let sets):
        self.content = .sets(sets.map {
          $0.makeIterator()
        })
      }
    }
    
    mutating func next() -> ArgumentDefinition? {
      switch content {
      case .arguments(var a):
        guard !a.isEmpty else { return nil }
        let n = a.remove(at: 0)
        content = .arguments(a)
        return n
      case .sets(var sets):
        defer {
          content = .sets(sets)
        }
        while true {
          guard !sets.isEmpty else { return nil }
          if let n = sets[0].next() {
            return n
          }
          sets.remove(at: 0)
        }
      case .empty:
        return nil
      }
    }
  }
}
