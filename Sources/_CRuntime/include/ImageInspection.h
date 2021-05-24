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

#ifndef IMAGE_INSPECTION_H
#define IMAGE_INSPECTION_H

#include <stddef.h>

extern void registerProtocolConformances(const char *section, size_t size);

void loadImages();

//===----------------------------------------------------------------------===//
// MachO Image Inspection
//===----------------------------------------------------------------------===//

#if defined(__MACH__)

#include <mach-o/dyld.h>

extern void lookupSection(const struct mach_header *header, const char *segment,
                          const char *section,
                          void (*registerFunc)(const char *, size_t));

#endif // defined(__MACH__)

//===----------------------------------------------------------------------===//
// ELF Image Inspection
//===----------------------------------------------------------------------===//

#if defined(__ELF__)

// Create an empty section here so that we can get legitimate pointers to the
// actual start and stop of a specific section.

#define DECLARE_SWIFT_SECTION(name) \
  __asm__("\t.section " #name ", \"a\"\n"); \
  __attribute__((__visibility__("hidden"), __aligned__(1))) extern const char __start_##name; \
  __attribute__((__visibility__("hidden"), __aligned__(1))) extern const char __stop_##name;

#if defined(__cplusplus)
extern "C" {
#endif

DECLARE_SWIFT_SECTION(swift5_protocol_conformances)

#if defined(__cplusplus)
} // extern "C"
#endif

#undef DECLARE_SWIFT_SECTION

#endif // defined(__ELF__)

//===----------------------------------------------------------------------===//
// COFF Image Inspection
//===----------------------------------------------------------------------===//

#if !defined(__MACH__) && !defined(__ELF__)

#include "stdint.h"

#define PASTE_EXPANDED(a, b) a##b
#define PASTE(a, b) PASTE_EXPANDED(a, b)

#define STRING_EXPANDED(string) #string
#define STRING(string) STRING_EXPANDED(string)

#define C_LABEL(name) PASTE(__USER_LABEL_PREFIX__, name)

#define PRAGMA(pragma) _Pragma(#pragma)

#define DECLARE_SWIFT_SECTION(name) \
  PRAGMA(section("." #name "$A", long, read)) \
  __declspec(allocate("." #name "$A")) \
  __declspec(align(1)) \
  static uintptr_t __start_##name = 0; \
                                      \
  PRAGMA(section("." #name "$C", long, read)) \
  __declspec(allocate("." #name "$C")) \
  __declspec(align(1)) \
  static uintptr_t __stop_##name = 0;
  
#if defined(__cplusplus)
extern "C" {
#endif

DECLARE_SWIFT_SECTION(sw5prtc)

#if defined(__cplusplus)
}
#endif

#undef DECLARE_SWIFT_SECTION

#pragma section(".CRT$XCIS", long, read)

__declspec(allocate(".CRT$XCIS"))
#if defined(__cplusplus)
extern "C"
#endif
void (*pLoadImages)(void) = &loadImages;
#pragma comment(linker, "/include:" STRING(C_LABEL(pLoadImages)))

#endif // !defined(__MACH__) && !defined(__ELF__)

#endif /* IMAGE_INSPECTION_H */
