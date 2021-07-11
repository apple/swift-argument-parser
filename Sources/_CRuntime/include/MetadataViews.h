//===--------------------------------------------------------------*- C -*-===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#ifndef METADATA_VIEWS_H
#define METADATA_VIEWS_H

#include "stdint.h"

// FIXME: Currently, the ClangImporter does not import types who have ptrauth
// decorators on member pointer types. This means that we could get rid of the
// whole ptrauth ceremony in Swift by stripping the asda portion and actually
// sign using the designated type descriptor key.

struct ClassMetadata {
  intptr_t kind;
  const void *superclass;
  uint32_t flags;
  uint32_t instanceAddressPoint;
  uint32_t instanceSize;
  uint16_t instanceAlignmentMask;
  uint16_t runtimeReserved;
  uint32_t classSize;
  uint32_t classAddressPoint;
  const void *descriptor;
};

struct ClassMetadataObjC {
  intptr_t kind;
  const void *superclass;
  intptr_t cacheData[2];
  const void *data;
  uint32_t flags;
  uint32_t instanceAddressPoint;
  uint32_t instanceSize;
  uint16_t instanceAlignmentMask;
  uint16_t runtimeReserved;
  uint32_t classSize;
  uint32_t classAddressPoint;
  const void *descriptor;
};

struct ConformanceDescriptor {
  int32_t protocol;
  int32_t typeReference;
  int32_t witnessTablePattern;
  uint32_t flags;
};

struct ContextDescriptor {
  uint32_t flags;
  int32_t parent;
};

struct EnumMetadata {
  intptr_t kind;
  const void *descriptor;
};

struct ExistentialMetadata {
  intptr_t kind;
  uint32_t flags;
  uint32_t numProtocols;
};

struct StructMetadata {
  intptr_t kind;
  const void *descriptor;
};

struct TypeContextDescriptor {
  struct ContextDescriptor base;
  int32_t name;
  int32_t accessor;
};

#endif /* METADATA_VIEWS_H */
