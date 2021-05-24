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

public protocol Metadata {
  var pointer: UnsafeRawPointer { get }
}

extension Metadata {
  public var kind: MetadataKind {
    MetadataKind(pointer)
  }

  public var descriptor: ContextDescriptor {
    switch self {
    case let classMetadata as ClassMetadata:
      return classMetadata.descriptor
    case let enumMetadata as EnumMetadata:
      return enumMetadata.descriptor
    case let structMetadata as StructMetadata:
      return structMetadata.descriptor
    default:
      fatalError("Metadata kind: \(kind), does not have a context descriptor.")
    }
  }
}

public enum MetadataKind: Int {
  case `class` = 0
  case `struct` = 0x200
  case `enum` = 0x201
  case optional = 0x202
  case existential = 0x303
  case other = 0xFFFF
}

extension MetadataKind {
  init(_ ptr: UnsafeRawPointer) {
    let raw = ptr.load(as: Int.self)

    guard let kind = MetadataKind(rawValue: raw) else {
      // If we're larger than 2047, then this is a class isa pointer for ObjC,
      // otherwise we're some other kind of metadata (or unknown) that we don't
      // care about for autodiscovery.
      self = raw > 0x7FF ? .class : .other
      return
    }

    self = kind
  }
}

public func metadata(for type: Any.Type) -> Metadata? {
  let ptr = unsafeBitCast(type, to: UnsafeRawPointer.self)
  let kind = MetadataKind(ptr)

  switch kind {
  case .class:
    return ClassMetadata(pointer: ptr)
  case .struct:
    return StructMetadata(pointer: ptr)
  case .enum, .optional:
    return EnumMetadata(pointer: ptr)
  case .existential:
    return ExistentialMetadata(pointer: ptr)
  default:
    return nil
  }
}
