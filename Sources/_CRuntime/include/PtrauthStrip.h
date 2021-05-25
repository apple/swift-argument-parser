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

#ifndef PTRAUTH_H
#define PTRAUTH_H

#if defined(__arm64e__)
const void *__ptrauth_strip_asda(const void *pointer);
#endif

#endif /* PTRAUTH_H */
