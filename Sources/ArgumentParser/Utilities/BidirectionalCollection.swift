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

extension BidirectionalCollection where Index == String.Index {
    internal func _alignIndex(roundingDown i: Index) -> Index {
        index(i, offsetBy: 0)
    }

    internal func _alignIndex(roundingUp i: Index) -> Index {
        let truncated = _alignIndex(roundingDown: i)
        guard i > truncated && truncated < endIndex else { return truncated }
        return index(after: truncated)
    }

    internal func _boundaryAlignedRange(_ r: some RangeExpression<Index>) -> Range<Index> {
        let range = r.relative(to: self)
        return _alignIndex(roundingDown: range.lowerBound)..<_alignIndex(roundingUp: range.upperBound)
    }

    internal func _checkRange(_ r: Range<Index>) -> Range<Index>? {
        guard r.lowerBound >= startIndex, r.upperBound <= endIndex else {
            return nil
        }
        return r
    }
}

extension BidirectionalCollection {
    func _trimmingCharacters(while predicate: (Element) -> Bool) -> SubSequence {
        var idx = startIndex
        while idx < endIndex && predicate(self[idx]) {
            formIndex(after: &idx)
        }

        let startOfNonTrimmedRange = idx // Points at the first char not in the set
        guard startOfNonTrimmedRange != endIndex else {
            return self[endIndex...]
        }

        let beforeEnd = index(before: endIndex)
        guard startOfNonTrimmedRange < beforeEnd else {
            return self[startOfNonTrimmedRange ..< endIndex]
        }

        var backIdx = beforeEnd
        // No need to bound-check because we've already trimmed from the beginning, so we'd definitely break off of this loop before `backIdx` rewinds before `startIndex`
        while predicate(self[backIdx]) {
            formIndex(before: &backIdx)
        }
        return self[startOfNonTrimmedRange ... backIdx]
    }

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