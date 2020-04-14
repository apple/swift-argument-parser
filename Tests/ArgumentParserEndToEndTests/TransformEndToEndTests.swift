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

fileprivate struct FooOption: ParsableArguments {

    static var usageString: String = """
    Usage: foo_option --string <int_str>
    """
    
    enum FooError: Error {
        case outOfBounds
    }
    
    @Option(help: ArgumentHelp("Convert string to integer", valueName: "int_str"),
            transform: { try convert($0) })
    var string: Int
    
    private static func convert(_ str: String) throws -> Int {
        guard let converted = Int(argument: str) else { throw ValidationError("Could not transform to an Int.") }
        guard converted < 1000 else { throw FooError.outOfBounds }
        return converted
    }
}

extension TransformEndToEndTests {
    func testTransform() throws {
        AssertParse(FooOption.self, ["--string", "42"]) { foo in
            XCTAssertEqual(foo.string, 42)
        }
    }
    
    func testValidation_Fail_CustomErrorMessage() throws {
        AssertFullErrorMessage(FooOption.self, ["--string", "Forty Two"], "Error: Could not transform to an Int.\n" + FooOption.usageString)
    }

    func testValidation_Fail_DefaultErrorMessage() throws {
        AssertFullErrorMessage(FooOption.self, ["--string", "4827"], "Error: The value '4827' is invalid for '--string <int_str>'\n" + FooOption.usageString)
    }
}
