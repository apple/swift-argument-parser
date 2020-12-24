// swift-tools-version:5.3
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
    defaultLocalization: "en",
    products: [
        .library(
            name: "ArgumentParser",
            targets: ["ArgumentParser"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ArgumentParser",
            dependencies: [],
            exclude: ["CMakeLists.txt"],
            resources: [.process("Resources")]),
        .target(
            name: "ArgumentParserTestHelpers",
            dependencies: ["ArgumentParser"],
            exclude: ["CMakeLists.txt"]),
        
        .target(
            name: "roll",
            dependencies: ["ArgumentParser"],
            path: "Examples/roll",
            exclude: ["CMakeLists.txt"]),
        .target(
            name: "math",
            dependencies: ["ArgumentParser"],
            path: "Examples/math",
            exclude: ["CMakeLists.txt"]),
        .target(
            name: "repeat",
            dependencies: ["ArgumentParser"],
            path: "Examples/repeat",
            exclude: ["CMakeLists.txt"]),

        .target(
            name: "changelog-authors",
            dependencies: ["ArgumentParser"],
            path: "Tools/changelog-authors"),

        .testTarget(
            name: "ArgumentParserEndToEndTests",
            dependencies: ["ArgumentParser", "ArgumentParserTestHelpers"],
            exclude: ["CMakeLists.txt"]),
        .testTarget(
            name: "ArgumentParserUnitTests",
            dependencies: ["ArgumentParser", "ArgumentParserTestHelpers"],
            exclude: ["CMakeLists.txt"]),
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
        dependencies: ["ArgumentParser", "ArgumentParserTestHelpers"],
        exclude: ["CMakeLists.txt"]))
#endif
