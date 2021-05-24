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

protocol RelativePointer {
  associatedtype Pointee

  var offset: Int32 { get }

  func address(from pointer: UnsafeRawPointer) -> UnsafeRawPointer
  func pointee(from pointer: UnsafeRawPointer) -> Pointee?
}

extension RelativePointer {
  func pointee(from pointer: UnsafeRawPointer) -> Pointee? {
    if offset == 0 {
      return nil
    }

    return address(from: pointer).load(as: Pointee.self)
  }
}

struct RelativeDirectPointer<Pointee>: RelativePointer {
  let offset: Int32

  func address(from pointer: UnsafeRawPointer) -> UnsafeRawPointer {
    pointer + Int(offset)
  }
}

struct RelativeIndirectablePointer<Pointee>: RelativePointer {
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
