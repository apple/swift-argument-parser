// swift-tools-version:5.5
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
        .library(name: "ArgumentParser", targets: ["ArgumentParser"]),
        .library(name: "CTools", targets: ["CTools"])
    ],
    dependencies: [],
    targets: [
        // Core Library
      .target(name: "CTools"),
        .target(
            name: "ArgumentParser",
            dependencies: ["ArgumentParserToolInfo", "CTools"],
            exclude: ["CMakeLists.txt"],
            swiftSettings: [.unsafeFlags(["-cxx-interoperability-mode=default"])]),
        .target(
            name: "ArgumentParserTestHelpers",
            dependencies: ["ArgumentParser", "ArgumentParserToolInfo"],
            exclude: ["CMakeLists.txt"]),
        .target(
            name: "ArgumentParserToolInfo",
            dependencies: [],
            exclude: ["CMakeLists.txt"]),

        // Examples
        .executableTarget(
            name: "roll",
            dependencies: ["ArgumentParser"],
            path: "Examples/roll",
            swiftSettings: [.unsafeFlags(["-cxx-interoperability-mode=default"])]),
        .executableTarget(
            name: "math",
            dependencies: ["ArgumentParser"],
            path: "Examples/math",
            swiftSettings: [.unsafeFlags(["-cxx-interoperability-mode=default"])]),
        .executableTarget(
            name: "repeat",
            dependencies: ["ArgumentParser"],
            path: "Examples/repeat",
            swiftSettings: [.unsafeFlags(["-cxx-interoperability-mode=default"])]),

        // Tests
        .testTarget(
            name: "ArgumentParserEndToEndTests",
            dependencies: ["ArgumentParser", "ArgumentParserTestHelpers"],
            exclude: ["CMakeLists.txt"]),
        .testTarget(
            name: "ArgumentParserUnitTests",
            dependencies: ["ArgumentParser", "ArgumentParserTestHelpers"],
            exclude: ["CMakeLists.txt"]),
        .testTarget(
            name: "ArgumentParserPackageManagerTests",
            dependencies: ["ArgumentParser", "ArgumentParserTestHelpers"],
            exclude: ["CMakeLists.txt"]),
        .testTarget(
            name: "ArgumentParserExampleTests",
            dependencies: ["ArgumentParserTestHelpers"],
            resources: [.copy("CountLinesTest.txt")]),
    ]
)
