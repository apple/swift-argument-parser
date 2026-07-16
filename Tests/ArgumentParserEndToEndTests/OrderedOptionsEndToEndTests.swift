//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import ArgumentParser
import ArgumentParserTestHelpers
import XCTest

final class OrderedOptionsEndToEndTests: XCTestCase {}

private enum Operation: Equatable {
    case resize(String)
    case blur(Double)
    case crop(String)
    case rotate(Double)
}

private struct ImageTool: ParsableArguments {
    @Option(
        name: [.customLong("resize"), .customLong("blur"), .customLong("crop"), .customLong("rotate")],
        transform: { optionName, value in
            switch optionName {
            case "resize": return .resize(value)
            case "blur":   return .blur(Double(value)!)
            case "crop":   return .crop(value)
            case "rotate": return .rotate(Double(value)!)
            default: fatalError("Unexpected option name: \(optionName)")
            }
        }
    ) var operations: [Operation] = []
}

extension OrderedOptionsEndToEndTests {
    func testOrderedOptions() throws {
        AssertParse(ImageTool.self, [
            "--resize", "50%",
            "--blur", "3",
            "--crop", "100x100",
            "--rotate", "90",
            "--blur", "1"
        ]) { tool in
            XCTAssertEqual(tool.operations, [
                .resize("50%"),
                .blur(3.0),
                .crop("100x100"),
                .rotate(90.0),
                .blur(1.0)
            ])
        }
    }

    func testMixedShortAndLongNames() throws {
        struct MixedTool: ParsableArguments {
            @Option(
                name: [.customShort("r"), .customLong("resize")],
                transform: { name, value in
                    return "\(name):\(value)"
                }
            ) var ops: [String] = []
        }

        AssertParse(MixedTool.self, ["-r", "1", "--resize", "2", "-r", "3"]) { tool in
            XCTAssertEqual(tool.ops, ["r:1", "resize:2", "r:3"])
        }
    }
}
