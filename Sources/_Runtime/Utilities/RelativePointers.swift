//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

struct RelativeDirectPointer<Pointee> {
  let offset: Int32

  func address(from pointer: UnsafeRawPointer) -> UnsafeRawPointer {
    pointer + Int(offset)
  }
}

struct RelativeIndirectablePointer<Pointee> {
  let offset: Int32

  func address(from pointer: UnsafeRawPointer) -> UnsafeRawPointer {
    let dest = pointer + Int(offset & ~1)

    // If our low bit is set, then it indicates that we're indirectly pointing
    // at our desired object. Otherwise, it's directly in front of us.
    if Int(offset) & 1 == 1 {
      return dest.load(as: UnsafeRawPointer.self)
    } else {
      return dest
    }
  }
}
