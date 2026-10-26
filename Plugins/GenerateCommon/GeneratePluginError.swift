//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import Foundation
import PackagePlugin

enum GeneratePluginError: Error {
  case unknownBuildConfiguration(String)
  case pluginManagedOption(String)
  case buildFailed(String)
  case createOutputDirectoryFailed(Error)
  case subprocessFailedNonZeroExit(URL, Int32)
  case subprocessFailedError(URL, Error)
}

extension GeneratePluginError: CustomStringConvertible {
  var description: String {
    switch self {
    case .unknownBuildConfiguration(let configuration):
      return "Build failed: Unknown build configuration '\(configuration)'."
    case .pluginManagedOption(let option):
      return
        "The GeneratePlugin plugin manages '\(option)' for each target; do not pass it manually."
    case .buildFailed(let logText):
      return "Build failed: \(logText)."
    case .createOutputDirectoryFailed(let error):
      return """
        Failed to create output directory: '\(error.localizedDescription)'
        """
    case .subprocessFailedNonZeroExit(let tool, let exitCode):
      return """
        '\(tool.lastPathComponent)' invocation failed with a nonzero exit \
        code: '\(exitCode)'.
        """
    case .subprocessFailedError(let tool, let error):
      return """
        '\(tool.lastPathComponent)' invocation failed: \
        '\(error.localizedDescription)'
        """
    }
  }
}

extension GeneratePluginError: LocalizedError {
  var errorDescription: String? { self.description }
}
