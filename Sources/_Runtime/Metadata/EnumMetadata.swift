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

public struct EnumMetadata: Metadata, PointerView {
  typealias View = _EnumMetadata

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

struct _EnumMetadata {
  let _kind: Int
  let _descriptor: ContextDescriptor
}
