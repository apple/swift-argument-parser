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

// We really don't care about any of the various context descriptor properties,
// thus this design is a single abstraction for all context descriptors.

public struct ContextDescriptor: PointerView {
  typealias View = _CRuntime.ContextDescriptor

  let pointer: UnsafeRawPointer

  public var flags: Flags {
    Flags(value: view.flags)
  }

  public var parent: ContextDescriptor? {
    let _parent = RelativeIndirectablePointer<_CRuntime.ContextDescriptor>(
      offset: view.parent
    )
    
    guard _parent.offset != 0 else {
      return nil
    }

    let start = pointer + MemoryLayout<Int32>.size
    let address = _parent.address(from: start)
    return ContextDescriptor(pointer: address)
  }

  public var accessor: MetadataAccessFunction {
    switch flags.kind {
    case .class, .struct, .enum:
      let typeDescriptor = pointer.load(as: _CRuntime.TypeContextDescriptor.self)
      let start = pointer + MemoryLayout<Int32>.size * 3
      let _accessor = RelativeDirectPointer<Void>(
        offset: typeDescriptor.accessor
      )
      let address = _accessor.address(from: start)
      return MetadataAccessFunction(pointer: address)
    default:
      fatalError("Context descriptor kind: \(flags.kind), has no type accessor")
    }
  }
}

extension ContextDescriptor: Equatable {}
extension ContextDescriptor: Hashable {}

extension ContextDescriptor {
  public struct Flags {
    let value: UInt32

    var kind: Kind {
      let raw = UInt8(value & 0x1F)

      guard let kind = Kind(rawValue: raw) else {
        return .other
      }

      return kind
    }

    public var isGeneric: Bool {
      value & 0x80 != 0
    }
  }

  enum Kind: UInt8 {
    case module = 0x0
    case `protocol` = 0x3
    case `class` = 0x11
    case `struct` = 0x12
    case `enum` = 0x13
    case other = 0xFF
  }
}
