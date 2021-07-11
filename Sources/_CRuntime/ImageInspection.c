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

#include "ImageInspection.h"

//===----------------------------------------------------------------------===//
// MachO Image Inspection
//===----------------------------------------------------------------------===//

#if defined(__MACH__)

#include <mach-o/dyld.h>

void _loadImageCallback(const struct mach_header *header, intptr_t size) {
  lookupSection(header, "__TEXT", "__swift5_proto",
                registerProtocolConformances);
}

__attribute__((__constructor__))
void loadImages() {
  _dyld_register_func_for_add_image(_loadImageCallback);
}

#endif // defined(__MACH__)

//===----------------------------------------------------------------------===//
// ELF Image Inspection
//===----------------------------------------------------------------------===//

#if defined(__ELF__)

#define SWIFT_REGISTER_SECTION(name, handle) \
  handle(&__start_##name, &__stop_##name - &__start_##name);

__attribute__((__constructor__))
void loadImages() {
  SWIFT_REGISTER_SECTION(swift5_protocol_conformances,
                         registerProtocolConformances)
}

#undef SWIFT_REGISTER_SECTION

#endif // defined(__ELF__)

//===----------------------------------------------------------------------===//
// COFF Image Inspection
//===----------------------------------------------------------------------===//

#if !defined(__MACH__) && !defined(__ELF__)

#define SWIFT_REGISTER_SECTION(name, handle) \
  handle((const char *)&__start_##name, &__stop_##name - &__start_##name);

void loadImages() {
  SWIFT_REGISTER_SECTION(sw5prtc, registerProtocolConformances)
}

#undef SWIFT_REGISTER_SECTION

#endif // !defined(__MACH__) && !defined(__ELF__)
