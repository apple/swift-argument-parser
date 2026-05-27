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

import Foundation
import PackagePlugin

@main
struct GenerateDoccReferencePlugin: GeneratePlugin {
  static let pluginName = "GenerateDoccReference"
  static let executableName = "generate-docc-reference"
  static let artifactName = "docc reference"

  static func outputDirectory(
    context: PluginContext, target: SwiftSourceModuleTarget
  ) -> URL {
    target.directoryURL.appendingPathComponent("\(target.name).docc")
  }
}
