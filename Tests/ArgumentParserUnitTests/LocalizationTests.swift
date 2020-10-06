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
@testable import ArgumentParser

final class LocalizationTests: XCTestCase {
}

extension LocalizationTests {
    struct A: ParsableArguments {
        @Option
        var one: String = "42"
        @Option(help: ArgumentHelp(NSLocalizedString("The second option", comment: "Help text")))
        var two: String
        @Option(help: ArgumentHelp(NSLocalizedString("The third option", comment: "Help text")))
        var three: String
    }
    
    func testHelpMessageLocalization() {
        let locale = Locale.current.languageCode
        
        if locale == "tr" {
            AssertHelp(for: A.self, equals: """
                    KULLANIM: a [--one <one>] --two <two> [--three <three>]

                    SEÇENEKLER:
                      --one <one>             (öntanımlı: 42)
                      --two <two>             İkinci seçenek
                      --three <three>         Üçüncü seçenek
                      -h, --help              Yardım bilgisini göster.
                    """)
            
        }
    }
}
