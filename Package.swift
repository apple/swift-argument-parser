// swift-tools-version:5.1
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

let package = Package(
    name: "swift-argument-parser",
    products: [
        .library(
            name: "ArgumentParser",
            targets: ["ArgumentParser"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ArgumentParser",
            dependencies: []),
        .target(
            name: "ArgumentParserTestHelpers",
            dependencies: ["ArgumentParser"]),

        .target(
            name: "roll",
            dependencies: ["ArgumentParser"],
            path: "Examples/roll"),
        .target(
            name: "math",
            dependencies: ["ArgumentParser"],
            path: "Examples/math"),
        .target(
            name: "repeat",
            dependencies: ["ArgumentParser"],
            path: "Examples/repeat"),

        .testTarget(
            name: "ArgumentParserEndToEndTests",
            dependencies: ["ArgumentParser", "ArgumentParserTestHelpers"]),
        .testTarget(
            name: "ArgumentParserUnitTests",
            dependencies: ["ArgumentParser", "ArgumentParserTestHelpers"]),
        .testTarget(
            name: "ArgumentParserPackageManagerTests",
            dependencies: ["ArgumentParser", "ArgumentParserTestHelpers"]),
        .testTarget(
            name: "ArgumentParserExampleTests",
            dependencies: ["ArgumentParserTestHelpers"]),
    ]
)
