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

public struct ConformanceDescriptor: PointerView {
  typealias View = _ConformanceDescriptor
  
  let pointer: UnsafeRawPointer
  
  public var `protocol`: ContextDescriptor {
    ContextDescriptor(pointer: view._protocol.address(from: pointer))
  }
  
  public var contextDescriptor: ContextDescriptor? {
    let start = pointer + MemoryLayout<Int32>.size
    let offset = start.load(as: Int32.self)
    let address = start + Int(offset)
    
    switch view._flags.typeReferenceKind {
    case .directTypeDescriptor:
      return ContextDescriptor(pointer: address)
    case .indirectTypeDescriptor:
      let indirect = address.load(as: ContextDescriptor.self)
      return indirect
    default:
      return nil
    }
  }
}

extension ConformanceDescriptor {
  public struct Flags {
    let value: UInt32
    
    var typeReferenceKind: TypeReferenceKind {
      TypeReferenceKind(UInt16(value & (0x7 << 3)) >> 3)
    }
  }
}

enum TypeReferenceKind: UInt16 {
  case directTypeDescriptor = 0x0
  case indirectTypeDescriptor = 0x1
  case other = 0xFFFF
  
  init(_ int: UInt16) {
    guard let kind = TypeReferenceKind(rawValue: int) else {
      self = .other
      return
    }
    
    self = kind
  }
}

struct _ConformanceDescriptor {
  let _protocol: RelativeIndirectablePointer<_ContextDescriptor>
  let _typeReference: Int32
  let _witnessTablePattern: RelativeDirectPointer<Void>
  let _flags: ConformanceDescriptor.Flags
}
