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

final class DumpHelpGenerationTests: XCTestCase {
  public static let allTests = [
    ("testDumpExampleCommands", testDumpExampleCommands)
  ]
  
}

extension DumpHelpGenerationTests {
  struct A: ParsableArguments {
    @Option()
    var noHelpOption: Int
    
    @Option(help: "int value option")
    var intOption: Int
    
    @Option(help: "int value option with default value")
    var intOptionWithDefaultValue: Int = 0
    
    @Argument
    var arg: Int
     
    @Argument(help: "argument with help")
    var argWithHelp: Int
    
    @Argument(help: "argument with default value")
    var argWithDefaultValue: Int = 1
  }
  
  public func testDumpExampleCommands() {
    struct TestCase {
      let expected: String
      let commandToDump: String
    }
    
    let testCases: [UInt : TestCase] = [
      #line : .init(expected:
                    """
{
  "arguments" : [

  ],
  "options" : [
    {
      "isRequired" : false,
      "name" : "--version",
      "discussion" : "",
      "abstract" : "Show the version."
    },
    {
      "isRequired" : false,
      "name" : "-h, --help",
      "discussion" : "",
      "abstract" : "Show help information."
    }
  ],
  "command" : {
    "name" : "math",
    "abstract" : "A utility for performing maths.",
    "discussion" : ""
  },
  "subcommands" : [
    {
      "isDefault" : true,
      "name" : "add",
      "discussion" : "",
      "abstract" : "Print the sum of the values."
    },
    {
      "isDefault" : false,
      "name" : "multiply",
      "discussion" : "",
      "abstract" : "Print the product of the values."
    },
    {
      "isDefault" : false,
      "name" : "stats",
      "discussion" : "",
      "abstract" : "Calculate descriptive statistics."
    }
  ]
}
""",
                    commandToDump: "math --dump-help"),
      
      #line : .init(expected:
                    """
{
  "arguments" : [
    {
      "defaultValue" : "",
      "isRequired" : true,
      "name" : "<values>",
      "discussion" : "",
      "abstract" : "A group of integers to operate on. "
    }
  ],
  "options" : [
    {
      "defaultValue" : "",
      "isRequired" : false,
      "name" : "-x, --hex-output",
      "discussion" : "",
      "abstract" : "Use hexadecimal notation for the result. "
    },
    {
      "isRequired" : false,
      "name" : "--version",
      "discussion" : "",
      "abstract" : "Show the version."
    },
    {
      "isRequired" : false,
      "name" : "-h, --help",
      "discussion" : "",
      "abstract" : "Show help information."
    }
  ],
  "command" : {
    "name" : "math add",
    "abstract" : "Print the sum of the values.",
    "discussion" : ""
  },
  "subcommands" : [

  ]
}
"""
        , commandToDump: "math add --dump-help"),
      
      #line : .init(expected:
                        """
{
  "arguments" : [
    {
      "defaultValue" : "",
      "isRequired" : true,
      "name" : "<values>",
      "discussion" : "",
      "abstract" : "A group of integers to operate on. "
    }
  ],
  "options" : [
    {
      "defaultValue" : "",
      "isRequired" : false,
      "name" : "-x, --hex-output",
      "discussion" : "",
      "abstract" : "Use hexadecimal notation for the result. "
    },
    {
      "isRequired" : false,
      "name" : "--version",
      "discussion" : "",
      "abstract" : "Show the version."
    },
    {
      "isRequired" : false,
      "name" : "-h, --help",
      "discussion" : "",
      "abstract" : "Show help information."
    }
  ],
  "command" : {
    "name" : "math multiply",
    "abstract" : "Print the product of the values.",
    "discussion" : ""
  },
  "subcommands" : [

  ]
}
""", commandToDump: "math multiply --dump-help"),
      
      #line : .init(expected: """
{
  "arguments" : [

  ],
  "options" : [
    {
      "isRequired" : false,
      "name" : "--version",
      "discussion" : "",
      "abstract" : "Show the version."
    },
    {
      "isRequired" : false,
      "name" : "-h, --help",
      "discussion" : "",
      "abstract" : "Show help information."
    }
  ],
  "command" : {
    "name" : "math stats",
    "abstract" : "Calculate descriptive statistics.",
    "discussion" : ""
  },
  "subcommands" : [
    {
      "isDefault" : false,
      "name" : "average",
      "discussion" : "",
      "abstract" : "Print the average of the values."
    },
    {
      "isDefault" : false,
      "name" : "stdev",
      "discussion" : "",
      "abstract" : "Print the standard deviation of the values."
    },
    {
      "isDefault" : false,
      "name" : "quantiles",
      "discussion" : "",
      "abstract" : "Print the quantiles of the values (TBD)."
    }
  ]
}
""", commandToDump: "math stats --dump-help")
    ]
    
    testCases.forEach { keyAndValue in
      let (key: line, value: testCase) = keyAndValue
      AssertExecuteCommand(command: testCase.commandToDump, expected: testCase.expected, line: line)
    }
  }
}
