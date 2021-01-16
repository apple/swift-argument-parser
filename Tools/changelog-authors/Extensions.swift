//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import Foundation
import _Concurrency

extension Sequence {
  func uniqued<T: Hashable>(by transform: (Element) throws -> T) rethrows -> [Element] {
    var seen: Set<T> = []
    var result: [Element] = []
    
    for element in self {
      if try seen.insert(transform(element)).inserted {
        result.append(element)
      }
    }
    return result
  }
}

struct NoDataReceived: Error {}

@available(macOS 9999, *)
extension URLSession {
  func data(from url: URL) async throws -> Data {
    try await withUnsafeThrowingContinuation { c in
      let task = URLSession.shared.dataTask(with: url) { data, _, error in
        switch (data, error) {
        case let (_, error?):
          c.resume(throwing: error)
        case let (data?, _):
          c.resume(returning: data)
        case (nil, nil):
          c.resume(throwing: NoDataReceived())
        }
      }
      task.resume()
    }
  }
}
