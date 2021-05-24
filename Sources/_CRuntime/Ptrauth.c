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

#include "Ptrauth.h"

#if defined(__arm64e__)
#include <ptrauth.h>

const void *__ptrauth_strip_asda(const void *pointer) {
  return ptrauth_strip(pointer, ptrauth_key_asda);
}

#endif
