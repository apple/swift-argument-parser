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

#if _ptrauth(_arm64e)
import _CRuntime
#endif

public struct ClassMetadata: Metadata, PointerView {
  typealias View = _ClassMetadata

  public let pointer: UnsafeRawPointer

  var descriptor: ContextDescriptor {
    // Type descriptors are signed on arm64e using pointer authentication.
    #if _ptrauth(_arm64e)
    let signed = __ptrauth_strip_asda(view._descriptor.pointer)
    return ContextDescriptor(pointer: signed)
    #else
    return view._descriptor
    #endif
  }
}

struct _ClassMetadata {
  let _kind: Int
  let _superclass: Any.Type?

  // The following properties are always present on ObjC interopt enabled
  // devices or platforms pre Swift 5.4. In 5.4, these were removed on platforms
  // who do not provide ObjectiveC.
  #if canImport(ObjectiveC) || swift(<5.4)
  let _cacheData: (Int, Int)
  let _data: UnsafeRawPointer
  #endif

  let _flags: UInt32
  let _instanceAddressPoint: UInt32
  let _instanceSize: UInt32
  let _instanceAlignmentMask: UInt16
  let _runtimeReserved: UInt16
  let _classSize: UInt32
  let _classAddressPoint: UInt32
  let _descriptor: ContextDescriptor
}
