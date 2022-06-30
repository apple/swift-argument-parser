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

@main
struct Repeat: ParsableCommand {
    @Option(help: "The number of times to repeat 'phrase'.")
    var count: Int

    @Flag(help: "Include a counter with each repetition.")
    var includeCounter = false

    @Argument(help: "The phrase to repeat.")
    var phrase: [String]

    mutating func run() throws {
        let repeatCount = count

        for i in 1 ... repeatCount {
            if includeCounter {
                print("\(i): \(phrase)")
            } else {
                print(phrase)
            }
        }
    }

//    public static func main() {
//
//        main(["--count", "3", "hello", "world"])
//        main(["--count", "3"])
//        main(["--include-counter"])
//        main(["hello", "--count"])
//        main(["hello", "--count", "--include-counter"])
//        main(["--count", "--include-counter", "hello"])
//        main(["--count", "3", "--include-counter", "hello"])
//
//    }
}
