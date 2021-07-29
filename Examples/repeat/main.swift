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

import ArgumentParser

import Foundation

struct CustomStruct {
    let urlValue: URL
    init?() {
        return nil
    }
}

extension CustomStruct: ExpressibleByArgument {
    init?(argument: String) {
        _ = CustomStruct()
        return nil
    }
}

struct CustomGroup: ParsableArguments {
    @Option()
    var optionalOption: CustomStruct?
}

struct MainCommand: ParsableCommand {
    @OptionGroup()
    var group: CustomGroup

    func run() {
        print("Hello, world!")
    }
}

MainCommand.main()
