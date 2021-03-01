// swift-tools-version:5.2
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

import PackageDescription

var package = Package(
    name: "swift-argument-parser",
    products: [
        .library(
            name: "ArgumentParser",
            targets: ["ArgumentParser"]),
        .executable(
            name: "generate",
            targets: ["ArgumentParserGenerators"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ArgumentParser",
            dependencies: []),
        .target(
            name: "ArgumentParserGenerators",
            dependencies: ["ArgumentParser", "MDoc"]),
        .target(
            name: "ArgumentParserTestHelpers",
            dependencies: ["ArgumentParser"]),
        .target(
            name: "MDoc",
            dependencies: []),

        .target(
            name: "math",
            dependencies: ["ArgumentParser"],
            path: "Examples/math"),
        .target(
            name: "repeat",
            dependencies: ["ArgumentParser"],
            path: "Examples/repeat"),
        .target(
            name: "roll",
            dependencies: ["ArgumentParser"],
            path: "Examples/roll"),

        .target(
            name: "changelog-authors",
            dependencies: ["ArgumentParser"],
            path: "Tools/changelog-authors"),

        .testTarget(
            name: "ArgumentParserEndToEndTests",
            dependencies: ["ArgumentParser", "ArgumentParserTestHelpers"]),
        .testTarget(
            name: "ArgumentParserUnitTests",
            dependencies: ["ArgumentParser", "ArgumentParserTestHelpers"]),
        .testTarget(
            name: "ArgumentParserExampleTests",
            dependencies: ["ArgumentParserTestHelpers"]),
    ]
)

#if swift(>=5.2)
// Skip if < 5.2 to avoid issue with nested type synthesized 'CodingKeys'
package.targets.append(
    .testTarget(
        name: "ArgumentParserPackageManagerTests",
        dependencies: ["ArgumentParser", "ArgumentParserTestHelpers"]))
#endif
