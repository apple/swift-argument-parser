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
            name: "SAPTestHelpers",
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
            name: "EndToEndTests",
            dependencies: ["ArgumentParser", "SAPTestHelpers"]),
        .testTarget(
            name: "UnitTests",
            dependencies: ["ArgumentParser", "SAPTestHelpers"]),
        .testTarget(
            name: "PackageManagerTests",
            dependencies: ["ArgumentParser", "SAPTestHelpers"]),
        .testTarget(
            name: "ExampleTests",
            dependencies: ["SAPTestHelpers"]),
    ]
)
