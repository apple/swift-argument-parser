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

public struct ExistentialMetadata: Metadata, PointerView {
  typealias View = _ExistentialMetadata

  public let pointer: UnsafeRawPointer

  public var protocols: UnsafeBufferPointer<ContextDescriptor> {
    var start = trailing

    // The first trailing object is the superclass metadata, if there is any.
    if view._flags.hasSuperclassConstraint {
      start += MemoryLayout<Int>.size
    }

    return UnsafeBufferPointer(
      start: UnsafePointer<ContextDescriptor>(start._rawValue),
      count: Int(view._numProtocols)
    )
  }
}

struct _ExistentialMetadata {
  let kind: Int
  let _flags: ExistentialMetadata.Flags
  let _numProtocols: UInt32
}

extension ExistentialMetadata {
  struct Flags {
    let value: UInt32

    var hasSuperclassConstraint: Bool {
      value & 0x40000000 != 0
    }
  }
}
