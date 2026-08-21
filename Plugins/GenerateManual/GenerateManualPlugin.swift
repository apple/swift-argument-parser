//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import Foundation
import PackagePlugin

@main
struct GenerateManualPlugin: GeneratePlugin {
  static let pluginName = "GenerateManual"
  static let executableName = "generate-manual"
  static let artifactName = "manual"

  static func outputDirectory(
    context: PluginContext, target: SwiftSourceModuleTarget
  ) -> URL {
    context.pluginWorkDirectoryURL.appendingPathComponent(target.name)
  }
}
