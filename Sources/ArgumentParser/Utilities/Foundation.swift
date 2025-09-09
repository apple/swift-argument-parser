//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if compiler(>=6.0)
#if canImport(FoundationEssentials)
internal import FoundationEssentials
#else
internal import Foundation
#endif
#else
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
#endif

enum Environment {
  struct Key {
    /// The name of the environment variable whose value is the name of the shell
    /// for which completions are being requested from a custom completion
    /// handler.
    ///
    /// The environment variable is set in generated completion scripts.
    static let shellName = Self(rawValue: "SAP_SHELL")

    /// The name of the environment variable whose value is the version of the
    /// shell for which completions are being requested from a custom completion
    /// handler.
    ///
    /// The environment variable is set in generated completion scripts.
    static let shellVersion = Self(rawValue: "SAP_SHELL_VERSION")

    var rawValue: String
  }

  static subscript(_ key: Key) -> String? {
    ProcessInfo.processInfo.environment[key.rawValue]
  }

  static var shellName: String? {
    Self[Key.shellName]
  }

  static var shellVersion: String? {
    Self[Key.shellVersion]
  }
}

extension Error {
  func describe() -> String {
    #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
    if let description = (self as? LocalizedError)?.errorDescription {
      return description
    } else {
      if Swift.type(of: self) is NSError.Type {
        return self.localizedDescription
      } else {
        return String(describing: self)
      }
    }
    #else
    return String(describing: error)
    #endif
  }
}

enum JSONEncoder {
  static func encode<T: Encodable>(_ value: T) -> String {
    let encoder = Foundation.JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    encoder.outputFormatting.insert(.sortedKeys)
    guard let encoded = try? encoder.encode(value) else { return "" }
    return String(data: encoded, encoding: .utf8) ?? ""
  }
}
