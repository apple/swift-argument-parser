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

/// An environment variable name
///
/// Wrapped as `RawRepresentable` for type safety.
struct EnvironmentName: RawRepresentable, Hashable {
  var rawValue: String
}
