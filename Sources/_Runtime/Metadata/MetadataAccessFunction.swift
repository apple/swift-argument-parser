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

public struct MetadataAccessFunction {
  let pointer: UnsafeRawPointer

  public func callAsFunction() -> Any.Type {
    // For the purposes of subcommand autodiscovery, we don't care about types
    // who are generic or require witness tables, so using the simple access
    // function is okay because we only ever call it on non-generic types.
    let fn = unsafeBitCast(
      pointer,
      to: (@convention(thin) (Int) -> MetadataResponse).self
    )

    // We only care about complete blocking metadata, so 0 is correct here.
    return fn(0).type
  }
}

struct MetadataResponse {
  let type: Any.Type

  let state: Int
}
