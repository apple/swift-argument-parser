//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2025-2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import ArgumentParserToolInfo
import Foundation
import Testing

extension DecodingError: Swift.CustomStringConvertible {
  public var description: String {
    func pathDescription(_ path: [any CodingKey]) -> String {
      var description = ""
      for element in path {
        if let intValue = element.intValue {
          description += "[\(intValue)]"
        } else {
          if description.count > 0 { description += "." }
          description += "\(element.stringValue)"
        }
      }
      return description
    }

    switch self {
    case .dataCorrupted(let context):
      return "Data corrupted at '\(pathDescription(context.codingPath))'"
    case .keyNotFound(let key, let context):
      return "Key not found at '\(pathDescription(context.codingPath + [key]))'"
    case .typeMismatch(_, let context):
      return "Type mismatch at '\(pathDescription(context.codingPath))'"
    case .valueNotFound(_, let context):
      return "Value not found at '\(pathDescription(context.codingPath))'"
    @unknown default:
      return "\(self)"
    }
  }
}

extension FileManager {
  func files(
    inDirectory directoryURL: URL,
    withPathExtension pathExtension: String
  ) -> [URL] {
    let enumerator = self.enumerator(
      at: directoryURL,
      includingPropertiesForKeys: [])
    guard let enumerator = enumerator else { return [] }

    return enumerator
      .lazy
      .compactMap { $0 as? URL }
      .filter { $0.pathExtension == pathExtension }
      .sorted { $0.path < $1.path }
  }
}

@Suite struct ArgumentParserToolInfoTests {
  static let examplesDirectory = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()
    .appendingPathComponent("Examples")

  static let examples: [URL] = FileManager.default.files(
    inDirectory: Self.examplesDirectory,
    withPathExtension: "json")

  @Test(arguments: examples)
  func example(url: URL) throws {
    let data = try Data(contentsOf: url)
    _ = try JSONDecoder().decode(ToolInfoV0.self, from: data)
  }
}
