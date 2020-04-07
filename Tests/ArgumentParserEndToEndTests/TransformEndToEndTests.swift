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

import XCTest
import ArgumentParserTestHelpers
import ArgumentParser

final class TransformEndToEndTests: XCTestCase {
}

fileprivate struct Foo: ParsableArguments {

    static var usageString: String = """
    Usage: foo --string <int_str>
    """
    
    @Option(help: ArgumentHelp("Convert string to integer", valueName: "int_str"),
            transform: { try convert($0) })
    var string: Int
    
    private static func convert(_ str: String) throws -> Int {
        guard let converted = Int(argument: str) else { throw ValidationError("Could not convert to Int") }
        return converted
    }
}

extension TransformEndToEndTests {
    func testTransform() throws {
        AssertParse(Foo.self, ["--string", "42"]) { foo in
            XCTAssertEqual(foo.string, 42)
        }
    }
    
    func testValidation_Fail() throws {
        AssertFullErrorMessage(Foo.self, ["--string", "Forty Two"], "Error: Internal error. Invalid state while parsing command-line arguments.\n" + Foo.usageString)
    }
}
