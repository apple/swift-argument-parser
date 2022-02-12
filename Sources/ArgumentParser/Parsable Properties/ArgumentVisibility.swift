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

/// Visibility level of an argument's help.
public enum ArgumentVisibility {
    /// Show help for this argument whenever appropriate.
    case `default`

    /// Only show help for this argument in the extended help screen.
    case hidden

    /// Never show help for this argument.
    case `private`
}
