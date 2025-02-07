//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import Foundation
import PackagePlugin

enum GenerateDoccReferencePluginError: Error {
  case unknownBuildConfiguration(String)
  case buildFailed(String)
  case createOutputDirectoryFailed(Error)
  case subprocessFailedNonZeroExit(Path, Int32)
  case subprocessFailedError(Path, Error)
}

extension GenerateDoccReferencePluginError: CustomStringConvertible {
  var description: String {
    switch self {
    case let .unknownBuildConfiguration(configuration):
      return "Build failed: Unknown build configuration '\(configuration)'."
    case let .buildFailed(logText):
      return "Build failed: \(logText)."
    case let .createOutputDirectoryFailed(error):
      return """
        Failed to create output directory: '\(error.localizedDescription)'
        """
    case let .subprocessFailedNonZeroExit(tool, exitCode):
      return """
        '\(tool.lastComponent)' invocation failed with a nonzero exit code: \
        '\(exitCode)'.
        """
    case let .subprocessFailedError(tool, error):
      return """
        '\(tool.lastComponent)' invocation failed: \
        '\(error.localizedDescription)'
        """
    }
  }
}

extension GenerateDoccReferencePluginError: LocalizedError {
  var errorDescription: String? { self.description }
}
