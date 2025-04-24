//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//


extension BidirectionalCollection {
    // Equal to calling `index(&idx, offsetBy: -other.count)` with just one loop
    func _index<S: BidirectionalCollection>(_ index: Index, backwardsOffsetByCountOf other: S) -> Index? {
        var idx = index
        var otherIdx = other.endIndex
        while otherIdx > other.startIndex {
            guard idx > startIndex else {
                // other.count > self.count: bail
                return nil
            }
            other.formIndex(before: &otherIdx)
            formIndex(before: &idx)
        }
        return idx
    }

    func _range<S: BidirectionalCollection>(of other: S, anchored: Bool = false, backwards: Bool = false) -> Range<Index>? where S.Element == Element, Element : Equatable {
        var result: Range<Index>? = nil
        var fromLoc: Index
        var toLoc: Index
        if backwards {
            guard let idx = _index(endIndex, backwardsOffsetByCountOf: other) else {
                // other.count > string.count: bail
                return nil
            }
            fromLoc = idx

            toLoc = anchored ? fromLoc : startIndex
        } else {
            fromLoc = startIndex
            if anchored {
                toLoc = fromLoc
            } else {
                guard let idx = _index(endIndex, backwardsOffsetByCountOf: other) else {
                    return nil
                }
                toLoc = idx
            }
        }

        let delta = fromLoc <= toLoc ? 1 : -1

        while true {
            var str1Index = fromLoc
            var str2Index = other.startIndex

            while str2Index < other.endIndex && str1Index < endIndex {
                if self[str1Index] != other[str2Index] {
                    break
                }
                formIndex(after: &str1Index)
                other.formIndex(after: &str2Index)
            }

            if str2Index == other.endIndex {
                result = fromLoc..<str1Index
                break
            }

            if fromLoc == toLoc {
                break
            }

            formIndex(&fromLoc, offsetBy: delta)
        }

        return result
    }
}