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

import _CRuntime

public struct ExistentialMetadata: Metadata, PointerView {
  typealias View = _CRuntime.ExistentialMetadata

  public let pointer: UnsafeRawPointer

  var flags: ExistentialMetadata.Flags {
    Flags(value: view.flags)
  }
  
  public var protocols: UnsafeBufferPointer<ContextDescriptor> {
    var start = trailing

    // The first trailing object is the superclass metadata, if there is any.
    if flags.hasSuperclassConstraint {
      start += MemoryLayout<Int>.size
    }

    return UnsafeBufferPointer(
      start: UnsafePointer<ContextDescriptor>(start._rawValue),
      count: Int(view.numProtocols)
    )
  }
}

extension ExistentialMetadata {
  struct Flags {
    let value: UInt32

    var hasSuperclassConstraint: Bool {
      value & 0x40000000 != 0
    }
  }
}
