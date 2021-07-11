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

public struct ClassMetadata: Metadata, PointerView {
  // The ObjC specific properties of class metadata are always present on
  // ObjC interopt enabled devices or platforms pre Swift 5.4. In 5.4,
  // those were removed on platforms who do not provide ObjectiveC.
  #if canImport(ObjectiveC) || swift(<5.4)
  typealias View = _CRuntime.ClassMetadataObjC
  #else
  typealias View = _CRuntime.ClassMetadata
  #endif

  public let pointer: UnsafeRawPointer

  var descriptor: ContextDescriptor {
    // Type descriptors are signed on arm64e using pointer authentication.
    #if _ptrauth(_arm64e)
    let signed = __ptrauth_strip_asda(view.descriptor)!
    return ContextDescriptor(pointer: signed)
    #else
    return ContextDescriptor(pointer: view.descriptor)
    #endif
  }
}
