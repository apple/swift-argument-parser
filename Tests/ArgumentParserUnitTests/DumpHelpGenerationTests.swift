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
    ("testDumpExampleCommands", testDumpExampleCommands),
    ("testDumpA", testDumpA)
  ]
}

extension DumpHelpGenerationTests {
  struct A: ParsableCommand {
    enum TestEnum: String, CaseIterable, ExpressibleByArgument {
      case a = "one", b = "two", c = "three"
    }

    @Option
    var enumeratedOption: TestEnum

    @Option
    var enumeratedOptionWithDefaultValue: TestEnum = .b
    
    @Option
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
  
  struct Options: ParsableArguments {
    @Flag var verbose = false
    @Option var name: String
  }
  
  struct B: ParsableCommand {
    @OptionGroup(title: "Other")
    var options: Options
  }

  struct C: ParsableCommand {
    enum Color: String, CaseIterable, ExpressibleByArgument {
      case blue
      case red
      case yellow

      var defaultValueDescription: String {
        switch self {
        case .blue:
          "A blue color, like the sky!"
        case .red:
          "A red color, like a rose!"
        case .yellow:
          "A yellow color, like the sun!"
        }
      }
    }

    @Option(help: "A color to select.")
    var color: Color

    @Option(help: "Another color to select!")
    var defaultColor: Color = .red

    @Option(help: "An optional color.")
    var opt: Color?

    @Option(help: "An optional color with a default value.")
    var optWithDefault: Color? = .yellow

    @Option(help: .init(discussion: "A preamble for the list of values in the discussion section."))
    var extra: Color

    @Option(help: .init(discussion: "A discussion."))
    var discussion: String
  }

  public func testDumpA() throws {
    try AssertDump(for: A.self, equals: Self.aDumpText)
  }
  
  public func testDumpB() throws {
    try AssertDump(for: B.self, equals: Self.bDumpText)
  }

  public func testDumpC() throws {
    try AssertDump(for: C.self, equals: Self.cDumpText)
  }

  public func testDumpExampleCommands() throws {
    struct TestCase {
      let expected: String
      let command: String
    }
    
    let testCases: [UInt : TestCase] = [
      #line : .init(expected: Self.mathDumpText, command: "math --experimental-dump-help"),
      #line : .init(expected: Self.mathAddDumpText, command: "math add --experimental-dump-help"),
      #line : .init(expected: Self.mathMultiplyDumpText, command: "math multiply --experimental-dump-help"),
      #line : .init(expected: Self.mathStatsDumpText, command: "math stats --experimental-dump-help")
    ]
    
    try testCases.forEach { line, testCase in
      try AssertJSONOutputEqual(
        command: testCase.command,
        expected: testCase.expected,
        line: line)
    }
  }
}

extension DumpHelpGenerationTests {
  static let aDumpText = """
{
  "command" : {
    "arguments" : [
      {
        "allValues" : [
          "one",
          "two",
          "three"
        ],
        "discussion" : {
          "values" : [
            {
              "description" : "one",
              "value" : "one"
            },
            {
              "description" : "two",
              "value" : "two"
            },
            {
              "description" : "three",
              "value" : "three"
            }
          ]
        },
        "isOptional" : false,
        "isRepeating" : false,
        "kind" : "option",
        "names" : [
          {
            "kind" : "long",
            "name" : "enumerated-option"
          }
        ],
        "preferredName" : {
          "kind" : "long",
          "name" : "enumerated-option"
        },
        "shouldDisplay" : true,
        "valueName" : "enumerated-option"
      },
      {
        "allValues" : [
          "one",
          "two",
          "three"
        ],
        "defaultValue" : "two",
        "discussion" : {
          "values" : [
            {
              "description" : "one",
              "value" : "one"
            },
            {
              "description" : "two",
              "value" : "two"
            },
            {
              "description" : "three",
              "value" : "three"
            }
          ]
        },
        "isOptional" : true,
        "isRepeating" : false,
        "kind" : "option",
        "names" : [
          {
            "kind" : "long",
            "name" : "enumerated-option-with-default-value"
          }
        ],
        "preferredName" : {
          "kind" : "long",
          "name" : "enumerated-option-with-default-value"
        },
        "shouldDisplay" : true,
        "valueName" : "enumerated-option-with-default-value"
      },
      {
        "isOptional" : false,
        "isRepeating" : false,
        "kind" : "option",
        "names" : [
          {
            "kind" : "long",
            "name" : "no-help-option"
          }
        ],
        "preferredName" : {
          "kind" : "long",
          "name" : "no-help-option"
        },
        "shouldDisplay" : true,
        "valueName" : "no-help-option"
      },
      {
        "abstract" : "int value option",
        "isOptional" : false,
        "isRepeating" : false,
        "kind" : "option",
        "names" : [
          {
            "kind" : "long",
            "name" : "int-option"
          }
        ],
        "preferredName" : {
          "kind" : "long",
          "name" : "int-option"
        },
        "shouldDisplay" : true,
        "valueName" : "int-option"
      },
      {
        "abstract" : "int value option with default value",
        "defaultValue" : "0",
        "isOptional" : true,
        "isRepeating" : false,
        "kind" : "option",
        "names" : [
          {
            "kind" : "long",
            "name" : "int-option-with-default-value"
          }
        ],
        "preferredName" : {
          "kind" : "long",
          "name" : "int-option-with-default-value"
        },
        "shouldDisplay" : true,
        "valueName" : "int-option-with-default-value"
      },
      {
        "isOptional" : false,
        "isRepeating" : false,
        "kind" : "positional",
        "shouldDisplay" : true,
        "valueName" : "arg"
      },
      {
        "abstract" : "argument with help",
        "isOptional" : false,
        "isRepeating" : false,
        "kind" : "positional",
        "shouldDisplay" : true,
        "valueName" : "arg-with-help"
      },
      {
        "abstract" : "argument with default value",
        "defaultValue" : "1",
        "isOptional" : true,
        "isRepeating" : false,
        "kind" : "positional",
        "shouldDisplay" : true,
        "valueName" : "arg-with-default-value"
      },
      {
        "abstract" : "Show help information.",
        "isOptional" : true,
        "isRepeating" : false,
        "kind" : "flag",
        "names" : [
          {
            "kind" : "short",
            "name" : "h"
          },
          {
            "kind" : "long",
            "name" : "help"
          }
        ],
        "preferredName" : {
          "kind" : "long",
          "name" : "help"
        },
        "shouldDisplay" : true,
        "valueName" : "help"
      }
    ],
    "commandName" : "a"
  },
  "serializationVersion" : 0
}
"""

  static let bDumpText: String = """
{
  "command" : {
    "arguments" : [
      {
        "isOptional" : true,
        "isRepeating" : false,
        "kind" : "flag",
        "names" : [
          {
            "kind" : "long",
            "name" : "verbose"
          }
        ],
        "preferredName" : {
          "kind" : "long",
          "name" : "verbose"
        },
        "sectionTitle" : "Other",
        "shouldDisplay" : true,
        "valueName" : "verbose"
      },
      {
        "isOptional" : false,
        "isRepeating" : false,
        "kind" : "option",
        "names" : [
          {
            "kind" : "long",
            "name" : "name"
          }
        ],
        "preferredName" : {
          "kind" : "long",
          "name" : "name"
        },
        "sectionTitle" : "Other",
        "shouldDisplay" : true,
        "valueName" : "name"
      },
      {
        "abstract" : "Show help information.",
        "isOptional" : true,
        "isRepeating" : false,
        "kind" : "flag",
        "names" : [
          {
            "kind" : "short",
            "name" : "h"
          },
          {
            "kind" : "long",
            "name" : "help"
          }
        ],
        "preferredName" : {
          "kind" : "long",
          "name" : "help"
        },
        "shouldDisplay" : true,
        "valueName" : "help"
      }
    ],
    "commandName" : "b"
  },
  "serializationVersion" : 0
}
"""

  static let cDumpText: String = """
  {
    "command" : {
      "arguments" : [
        {
          "abstract" : "A color to select.",
          "allValues" : [
            "blue",
            "red",
            "yellow"
          ],
          "discussion" : {
            "values" : [
              {
                "description" : "A blue color, like the sky!",
                "value" : "blue"
              },
              {
                "description" : "A red color, like a rose!",
                "value" : "red"
              },
              {
                "description" : "A yellow color, like the sun!",
                "value" : "yellow"
              }
            ]
          },
          "isOptional" : false,
          "isRepeating" : false,
          "kind" : "option",
          "names" : [
            {
              "kind" : "long",
              "name" : "color"
            }
          ],
          "preferredName" : {
            "kind" : "long",
            "name" : "color"
          },
          "shouldDisplay" : true,
          "valueName" : "color"
        },
        {
          "abstract" : "Another color to select!",
          "allValues" : [
            "blue",
            "red",
            "yellow"
          ],
          "defaultValue" : "red",
          "discussion" : {
            "values" : [
              {
                "description" : "A blue color, like the sky!",
                "value" : "blue"
              },
              {
                "description" : "A red color, like a rose!",
                "value" : "red"
              },
              {
                "description" : "A yellow color, like the sun!",
                "value" : "yellow"
              }
            ]
          },
          "isOptional" : true,
          "isRepeating" : false,
          "kind" : "option",
          "names" : [
            {
              "kind" : "long",
              "name" : "default-color"
            }
          ],
          "preferredName" : {
            "kind" : "long",
            "name" : "default-color"
          },
          "shouldDisplay" : true,
          "valueName" : "default-color"
        },
        {
          "abstract" : "An optional color.",
          "allValues" : [
            "blue",
            "red",
            "yellow"
          ],
          "discussion" : {
            "values" : [
              {
                "description" : "A blue color, like the sky!",
                "value" : "blue"
              },
              {
                "description" : "A red color, like a rose!",
                "value" : "red"
              },
              {
                "description" : "A yellow color, like the sun!",
                "value" : "yellow"
              }
            ]
          },
          "isOptional" : true,
          "isRepeating" : false,
          "kind" : "option",
          "names" : [
            {
              "kind" : "long",
              "name" : "opt"
            }
          ],
          "preferredName" : {
            "kind" : "long",
            "name" : "opt"
          },
          "shouldDisplay" : true,
          "valueName" : "opt"
        },
        {
          "abstract" : "An optional color with a default value.",
          "allValues" : [
            "blue",
            "red",
            "yellow"
          ],
          "defaultValue" : "yellow",
          "discussion" : {
            "values" : [
              {
                "description" : "A blue color, like the sky!",
                "value" : "blue"
              },
              {
                "description" : "A red color, like a rose!",
                "value" : "red"
              },
              {
                "description" : "A yellow color, like the sun!",
                "value" : "yellow"
              }
            ]
          },
          "isOptional" : true,
          "isRepeating" : false,
          "kind" : "option",
          "names" : [
            {
              "kind" : "long",
              "name" : "opt-with-default"
            }
          ],
          "preferredName" : {
            "kind" : "long",
            "name" : "opt-with-default"
          },
          "shouldDisplay" : true,
          "valueName" : "opt-with-default"
        },
        {
          "allValues" : [
            "blue",
            "red",
            "yellow"
          ],
          "discussion" : {
            "preamble" : "A preamble for the list of values in the discussion section.",
            "values" : [
              {
                "description" : "A blue color, like the sky!",
                "value" : "blue"
              },
              {
                "description" : "A red color, like a rose!",
                "value" : "red"
              },
              {
                "description" : "A yellow color, like the sun!",
                "value" : "yellow"
              }
            ]
          },
          "isOptional" : false,
          "isRepeating" : false,
          "kind" : "option",
          "names" : [
            {
              "kind" : "long",
              "name" : "extra"
            }
          ],
          "preferredName" : {
            "kind" : "long",
            "name" : "extra"
          },
          "shouldDisplay" : true,
          "valueName" : "extra"
        },
        {
          "discussion" : "A discussion.",
          "isOptional" : false,
          "isRepeating" : false,
          "kind" : "option",
          "names" : [
            {
              "kind" : "long",
              "name" : "discussion"
            }
          ],
          "preferredName" : {
            "kind" : "long",
            "name" : "discussion"
          },
          "shouldDisplay" : true,
          "valueName" : "discussion"
        },
        {
          "abstract" : "Show help information.",
          "isOptional" : true,
          "isRepeating" : false,
          "kind" : "flag",
          "names" : [
            {
              "kind" : "short",
              "name" : "h"
            },
            {
              "kind" : "long",
              "name" : "help"
            }
          ],
          "preferredName" : {
            "kind" : "long",
            "name" : "help"
          },
          "shouldDisplay" : true,
          "valueName" : "help"
        }
      ],
      "commandName" : "c"
    },
    "serializationVersion" : 0
  }
  """

  static let mathDumpText: String = """
{
  "command" : {
    "abstract" : "A utility for performing maths.",
    "arguments" : [
      {
        "abstract" : "Show the version.",
        "isOptional" : true,
        "isRepeating" : false,
        "kind" : "flag",
        "names" : [
          {
            "kind" : "long",
            "name" : "version"
          }
        ],
        "preferredName" : {
          "kind" : "long",
          "name" : "version"
        },
        "shouldDisplay" : true,
        "valueName" : "version"
      },
      {
        "abstract" : "Show help information.",
        "isOptional" : true,
        "isRepeating" : false,
        "kind" : "flag",
        "names" : [
          {
            "kind" : "short",
            "name" : "h"
          },
          {
            "kind" : "long",
            "name" : "help"
          }
        ],
        "preferredName" : {
          "kind" : "long",
          "name" : "help"
        },
        "shouldDisplay" : true,
        "valueName" : "help"
      }
    ],
    "commandName" : "math",
    "subcommands" : [
      {
        "abstract" : "Print the sum of the values.",
        "arguments" : [
          {
            "abstract" : "Use hexadecimal notation for the result.",
            "isOptional" : true,
            "isRepeating" : false,
            "kind" : "flag",
            "names" : [
              {
                "kind" : "long",
                "name" : "hex-output"
              },
              {
                "kind" : "short",
                "name" : "x"
              }
            ],
            "preferredName" : {
              "kind" : "long",
              "name" : "hex-output"
            },
            "shouldDisplay" : true,
            "valueName" : "hex-output"
          },
          {
            "abstract" : "A group of integers to operate on.",
            "isOptional" : true,
            "isRepeating" : true,
            "kind" : "positional",
            "shouldDisplay" : true,
            "valueName" : "values"
          },
          {
            "abstract" : "Show the version.",
            "isOptional" : true,
            "isRepeating" : false,
            "kind" : "flag",
            "names" : [
              {
                "kind" : "long",
                "name" : "version"
              }
            ],
            "preferredName" : {
              "kind" : "long",
              "name" : "version"
            },
            "shouldDisplay" : true,
            "valueName" : "version"
          },
          {
            "abstract" : "Show help information.",
            "isOptional" : true,
            "isRepeating" : false,
            "kind" : "flag",
            "names" : [
              {
                "kind" : "short",
                "name" : "h"
              },
              {
                "kind" : "long",
                "name" : "help"
              }
            ],
            "preferredName" : {
              "kind" : "long",
              "name" : "help"
            },
            "shouldDisplay" : true,
            "valueName" : "help"
          }
        ],
        "commandName" : "add",
        "superCommands" : [
          "math"
        ]
      },
      {
        "abstract" : "Print the product of the values.",
        "arguments" : [
          {
            "abstract" : "Use hexadecimal notation for the result.",
            "isOptional" : true,
            "isRepeating" : false,
            "kind" : "flag",
            "names" : [
              {
                "kind" : "long",
                "name" : "hex-output"
              },
              {
                "kind" : "short",
                "name" : "x"
              }
            ],
            "preferredName" : {
              "kind" : "long",
              "name" : "hex-output"
            },
            "shouldDisplay" : true,
            "valueName" : "hex-output"
          },
          {
            "abstract" : "A group of integers to operate on.",
            "isOptional" : true,
            "isRepeating" : true,
            "kind" : "positional",
            "shouldDisplay" : true,
            "valueName" : "values"
          },
          {
            "abstract" : "Show the version.",
            "isOptional" : true,
            "isRepeating" : false,
            "kind" : "flag",
            "names" : [
              {
                "kind" : "long",
                "name" : "version"
              }
            ],
            "preferredName" : {
              "kind" : "long",
              "name" : "version"
            },
            "shouldDisplay" : true,
            "valueName" : "version"
          },
          {
            "abstract" : "Show help information.",
            "isOptional" : true,
            "isRepeating" : false,
            "kind" : "flag",
            "names" : [
              {
                "kind" : "short",
                "name" : "h"
              },
              {
                "kind" : "long",
                "name" : "help"
              }
            ],
            "preferredName" : {
              "kind" : "long",
              "name" : "help"
            },
            "shouldDisplay" : true,
            "valueName" : "help"
          }
        ],
        "commandName" : "multiply",
        "superCommands" : [
          "math"
        ]
      },
      {
        "abstract" : "Calculate descriptive statistics.",
        "arguments" : [
          {
            "abstract" : "Show the version.",
            "isOptional" : true,
            "isRepeating" : false,
            "kind" : "flag",
            "names" : [
              {
                "kind" : "long",
                "name" : "version"
              }
            ],
            "preferredName" : {
              "kind" : "long",
              "name" : "version"
            },
            "shouldDisplay" : true,
            "valueName" : "version"
          },
          {
            "abstract" : "Show help information.",
            "isOptional" : true,
            "isRepeating" : false,
            "kind" : "flag",
            "names" : [
              {
                "kind" : "short",
                "name" : "h"
              },
              {
                "kind" : "long",
                "name" : "help"
              }
            ],
            "preferredName" : {
              "kind" : "long",
              "name" : "help"
            },
            "shouldDisplay" : true,
            "valueName" : "help"
          }
        ],
        "commandName" : "stats",
        "subcommands" : [
          {
            "abstract" : "Print the average of the values.",
            "arguments" : [
              {
                "abstract" : "The kind of average to provide.",
                "allValues" : [
                  "mean",
                  "median",
                  "mode"
                ],
                "defaultValue" : "mean",
                "discussion" : {
                  "values" : [
                    {
                      "description" : "mean",
                      "value" : "mean"
                    },
                    {
                      "description" : "median",
                      "value" : "median"
                    },
                    {
                      "description" : "mode",
                      "value" : "mode"
                    }
                  ]
                },
                "isOptional" : true,
                "isRepeating" : false,
                "kind" : "option",
                "names" : [
                  {
                    "kind" : "long",
                    "name" : "kind"
                  }
                ],
                "preferredName" : {
                  "kind" : "long",
                  "name" : "kind"
                },
                "shouldDisplay" : true,
                "valueName" : "kind"
              },
              {
                "abstract" : "A group of floating-point values to operate on.",
                "isOptional" : true,
                "isRepeating" : true,
                "kind" : "positional",
                "shouldDisplay" : true,
                "valueName" : "values"
              },
              {
                "abstract" : "Show the version.",
                "isOptional" : true,
                "isRepeating" : false,
                "kind" : "flag",
                "names" : [
                  {
                    "kind" : "long",
                    "name" : "version"
                  }
                ],
                "preferredName" : {
                  "kind" : "long",
                  "name" : "version"
                },
                "shouldDisplay" : true,
                "valueName" : "version"
              },
              {
                "abstract" : "Show help information.",
                "isOptional" : true,
                "isRepeating" : false,
                "kind" : "flag",
                "names" : [
                  {
                    "kind" : "short",
                    "name" : "h"
                  },
                  {
                    "kind" : "long",
                    "name" : "help"
                  }
                ],
                "preferredName" : {
                  "kind" : "long",
                  "name" : "help"
                },
                "shouldDisplay" : true,
                "valueName" : "help"
              }
            ],
            "commandName" : "average",
            "superCommands" : [
              "math",
              "stats"
            ]
          },
          {
            "abstract" : "Print the standard deviation of the values.",
            "arguments" : [
              {
                "abstract" : "A group of floating-point values to operate on.",
                "isOptional" : true,
                "isRepeating" : true,
                "kind" : "positional",
                "shouldDisplay" : true,
                "valueName" : "values"
              },
              {
                "abstract" : "Show the version.",
                "isOptional" : true,
                "isRepeating" : false,
                "kind" : "flag",
                "names" : [
                  {
                    "kind" : "long",
                    "name" : "version"
                  }
                ],
                "preferredName" : {
                  "kind" : "long",
                  "name" : "version"
                },
                "shouldDisplay" : true,
                "valueName" : "version"
              },
              {
                "abstract" : "Show help information.",
                "isOptional" : true,
                "isRepeating" : false,
                "kind" : "flag",
                "names" : [
                  {
                    "kind" : "short",
                    "name" : "h"
                  },
                  {
                    "kind" : "long",
                    "name" : "help"
                  }
                ],
                "preferredName" : {
                  "kind" : "long",
                  "name" : "help"
                },
                "shouldDisplay" : true,
                "valueName" : "help"
              }
            ],
            "commandName" : "stdev",
            "superCommands" : [
              "math",
              "stats"
            ]
          },
          {
            "abstract" : "Print the quantiles of the values (TBD).",
            "arguments" : [
              {
                "isOptional" : true,
                "isRepeating" : false,
                "kind" : "positional",
                "shouldDisplay" : true,
                "valueName" : "one-of-four"
              },
              {
                "isOptional" : true,
                "isRepeating" : false,
                "kind" : "positional",
                "shouldDisplay" : true,
                "valueName" : "custom-arg"
              },
              {
                "abstract" : "A group of floating-point values to operate on.",
                "isOptional" : true,
                "isRepeating" : true,
                "kind" : "positional",
                "shouldDisplay" : true,
                "valueName" : "values"
              },
              {
                "isOptional" : true,
                "isRepeating" : false,
                "kind" : "flag",
                "names" : [
                  {
                    "kind" : "long",
                    "name" : "test-success-exit-code"
                  }
                ],
                "preferredName" : {
                  "kind" : "long",
                  "name" : "test-success-exit-code"
                },
                "shouldDisplay" : false,
                "valueName" : "test-success-exit-code"
              },
              {
                "isOptional" : true,
                "isRepeating" : false,
                "kind" : "flag",
                "names" : [
                  {
                    "kind" : "long",
                    "name" : "test-failure-exit-code"
                  }
                ],
                "preferredName" : {
                  "kind" : "long",
                  "name" : "test-failure-exit-code"
                },
                "shouldDisplay" : false,
                "valueName" : "test-failure-exit-code"
              },
              {
                "isOptional" : true,
                "isRepeating" : false,
                "kind" : "flag",
                "names" : [
                  {
                    "kind" : "long",
                    "name" : "test-validation-exit-code"
                  }
                ],
                "preferredName" : {
                  "kind" : "long",
                  "name" : "test-validation-exit-code"
                },
                "shouldDisplay" : false,
                "valueName" : "test-validation-exit-code"
              },
              {
                "isOptional" : true,
                "isRepeating" : false,
                "kind" : "option",
                "names" : [
                  {
                    "kind" : "long",
                    "name" : "test-custom-exit-code"
                  }
                ],
                "preferredName" : {
                  "kind" : "long",
                  "name" : "test-custom-exit-code"
                },
                "shouldDisplay" : false,
                "valueName" : "test-custom-exit-code"
              },
              {
                "isOptional" : true,
                "isRepeating" : false,
                "kind" : "option",
                "names" : [
                  {
                    "kind" : "long",
                    "name" : "file"
                  }
                ],
                "preferredName" : {
                  "kind" : "long",
                  "name" : "file"
                },
                "shouldDisplay" : true,
                "valueName" : "file"
              },
              {
                "isOptional" : true,
                "isRepeating" : false,
                "kind" : "option",
                "names" : [
                  {
                    "kind" : "long",
                    "name" : "directory"
                  }
                ],
                "preferredName" : {
                  "kind" : "long",
                  "name" : "directory"
                },
                "shouldDisplay" : true,
                "valueName" : "directory"
              },
              {
                "isOptional" : true,
                "isRepeating" : false,
                "kind" : "option",
                "names" : [
                  {
                    "kind" : "long",
                    "name" : "shell"
                  }
                ],
                "preferredName" : {
                  "kind" : "long",
                  "name" : "shell"
                },
                "shouldDisplay" : true,
                "valueName" : "shell"
              },
              {
                "isOptional" : true,
                "isRepeating" : false,
                "kind" : "option",
                "names" : [
                  {
                    "kind" : "long",
                    "name" : "custom"
                  }
                ],
                "preferredName" : {
                  "kind" : "long",
                  "name" : "custom"
                },
                "shouldDisplay" : true,
                "valueName" : "custom"
              },
              {
                "abstract" : "Show the version.",
                "isOptional" : true,
                "isRepeating" : false,
                "kind" : "flag",
                "names" : [
                  {
                    "kind" : "long",
                    "name" : "version"
                  }
                ],
                "preferredName" : {
                  "kind" : "long",
                  "name" : "version"
                },
                "shouldDisplay" : true,
                "valueName" : "version"
              },
              {
                "abstract" : "Show help information.",
                "isOptional" : true,
                "isRepeating" : false,
                "kind" : "flag",
                "names" : [
                  {
                    "kind" : "short",
                    "name" : "h"
                  },
                  {
                    "kind" : "long",
                    "name" : "help"
                  }
                ],
                "preferredName" : {
                  "kind" : "long",
                  "name" : "help"
                },
                "shouldDisplay" : true,
                "valueName" : "help"
              }
            ],
            "commandName" : "quantiles",
            "superCommands" : [
              "math",
              "stats"
            ]
          }
        ],
        "superCommands" : [
          "math"
        ]
      }
    ]
  },
  "serializationVersion" : 0
}

"""

  static let mathAddDumpText: String = """
{
  "command" : {
    "abstract" : "Print the sum of the values.",
    "arguments" : [
      {
        "abstract" : "Use hexadecimal notation for the result.",
        "isOptional" : true,
        "isRepeating" : false,
        "kind" : "flag",
        "names" : [
          {
            "kind" : "long",
            "name" : "hex-output"
          },
          {
            "kind" : "short",
            "name" : "x"
          }
        ],
        "preferredName" : {
          "kind" : "long",
          "name" : "hex-output"
        },
        "shouldDisplay" : true,
        "valueName" : "hex-output"
      },
      {
        "abstract" : "A group of integers to operate on.",
        "isOptional" : true,
        "isRepeating" : true,
        "kind" : "positional",
        "shouldDisplay" : true,
        "valueName" : "values"
      },
      {
        "abstract" : "Show the version.",
        "isOptional" : true,
        "isRepeating" : false,
        "kind" : "flag",
        "names" : [
          {
            "kind" : "long",
            "name" : "version"
          }
        ],
        "preferredName" : {
          "kind" : "long",
          "name" : "version"
        },
        "shouldDisplay" : true,
        "valueName" : "version"
      },
      {
        "abstract" : "Show help information.",
        "isOptional" : true,
        "isRepeating" : false,
        "kind" : "flag",
        "names" : [
          {
            "kind" : "short",
            "name" : "h"
          },
          {
            "kind" : "long",
            "name" : "help"
          }
        ],
        "preferredName" : {
          "kind" : "long",
          "name" : "help"
        },
        "shouldDisplay" : true,
        "valueName" : "help"
      }
    ],
    "commandName" : "add",
    "superCommands" : [
      "math"
    ]
  },
  "serializationVersion" : 0
}

"""

  static let mathMultiplyDumpText: String = """
{
  "command" : {
    "abstract" : "Print the product of the values.",
    "arguments" : [
      {
        "abstract" : "Use hexadecimal notation for the result.",
        "isOptional" : true,
        "isRepeating" : false,
        "kind" : "flag",
        "names" : [
          {
            "kind" : "long",
            "name" : "hex-output"
          },
          {
            "kind" : "short",
            "name" : "x"
          }
        ],
        "preferredName" : {
          "kind" : "long",
          "name" : "hex-output"
        },
        "shouldDisplay" : true,
        "valueName" : "hex-output"
      },
      {
        "abstract" : "A group of integers to operate on.",
        "isOptional" : true,
        "isRepeating" : true,
        "kind" : "positional",
        "shouldDisplay" : true,
        "valueName" : "values"
      },
      {
        "abstract" : "Show the version.",
        "isOptional" : true,
        "isRepeating" : false,
        "kind" : "flag",
        "names" : [
          {
            "kind" : "long",
            "name" : "version"
          }
        ],
        "preferredName" : {
          "kind" : "long",
          "name" : "version"
        },
        "shouldDisplay" : true,
        "valueName" : "version"
      },
      {
        "abstract" : "Show help information.",
        "isOptional" : true,
        "isRepeating" : false,
        "kind" : "flag",
        "names" : [
          {
            "kind" : "short",
            "name" : "h"
          },
          {
            "kind" : "long",
            "name" : "help"
          }
        ],
        "preferredName" : {
          "kind" : "long",
          "name" : "help"
        },
        "shouldDisplay" : true,
        "valueName" : "help"
      }
    ],
    "commandName" : "multiply",
    "superCommands" : [
      "math"
    ]
  },
  "serializationVersion" : 0
}

"""

  static let mathStatsDumpText: String = """
{
  "command" : {
    "abstract" : "Calculate descriptive statistics.",
    "arguments" : [
      {
        "abstract" : "Show the version.",
        "isOptional" : true,
        "isRepeating" : false,
        "kind" : "flag",
        "names" : [
          {
            "kind" : "long",
            "name" : "version"
          }
        ],
        "preferredName" : {
          "kind" : "long",
          "name" : "version"
        },
        "shouldDisplay" : true,
        "valueName" : "version"
      },
      {
        "abstract" : "Show help information.",
        "isOptional" : true,
        "isRepeating" : false,
        "kind" : "flag",
        "names" : [
          {
            "kind" : "short",
            "name" : "h"
          },
          {
            "kind" : "long",
            "name" : "help"
          }
        ],
        "preferredName" : {
          "kind" : "long",
          "name" : "help"
        },
        "shouldDisplay" : true,
        "valueName" : "help"
      }
    ],
    "commandName" : "stats",
    "subcommands" : [
      {
        "abstract" : "Print the average of the values.",
        "arguments" : [
          {
            "abstract" : "The kind of average to provide.",
            "allValues" : [
              "mean",
              "median",
              "mode"
            ],
            "defaultValue" : "mean",
            "discussion" : {
              "values" : [
                {
                  "description" : "mean",
                  "value" : "mean"
                },
                {
                  "description" : "median",
                  "value" : "median"
                },
                {
                  "description" : "mode",
                  "value" : "mode"
                }
              ]
            },
            "isOptional" : true,
            "isRepeating" : false,
            "kind" : "option",
            "names" : [
              {
                "kind" : "long",
                "name" : "kind"
              }
            ],
            "preferredName" : {
              "kind" : "long",
              "name" : "kind"
            },
            "shouldDisplay" : true,
            "valueName" : "kind"
          },
          {
            "abstract" : "A group of floating-point values to operate on.",
            "isOptional" : true,
            "isRepeating" : true,
            "kind" : "positional",
            "shouldDisplay" : true,
            "valueName" : "values"
          },
          {
            "abstract" : "Show the version.",
            "isOptional" : true,
            "isRepeating" : false,
            "kind" : "flag",
            "names" : [
              {
                "kind" : "long",
                "name" : "version"
              }
            ],
            "preferredName" : {
              "kind" : "long",
              "name" : "version"
            },
            "shouldDisplay" : true,
            "valueName" : "version"
          },
          {
            "abstract" : "Show help information.",
            "isOptional" : true,
            "isRepeating" : false,
            "kind" : "flag",
            "names" : [
              {
                "kind" : "short",
                "name" : "h"
              },
              {
                "kind" : "long",
                "name" : "help"
              }
            ],
            "preferredName" : {
              "kind" : "long",
              "name" : "help"
            },
            "shouldDisplay" : true,
            "valueName" : "help"
          }
        ],
        "commandName" : "average",
        "superCommands" : [
          "math",
          "stats"
        ]
      },
      {
        "abstract" : "Print the standard deviation of the values.",
        "arguments" : [
          {
            "abstract" : "A group of floating-point values to operate on.",
            "isOptional" : true,
            "isRepeating" : true,
            "kind" : "positional",
            "shouldDisplay" : true,
            "valueName" : "values"
          },
          {
            "abstract" : "Show the version.",
            "isOptional" : true,
            "isRepeating" : false,
            "kind" : "flag",
            "names" : [
              {
                "kind" : "long",
                "name" : "version"
              }
            ],
            "preferredName" : {
              "kind" : "long",
              "name" : "version"
            },
            "shouldDisplay" : true,
            "valueName" : "version"
          },
          {
            "abstract" : "Show help information.",
            "isOptional" : true,
            "isRepeating" : false,
            "kind" : "flag",
            "names" : [
              {
                "kind" : "short",
                "name" : "h"
              },
              {
                "kind" : "long",
                "name" : "help"
              }
            ],
            "preferredName" : {
              "kind" : "long",
              "name" : "help"
            },
            "shouldDisplay" : true,
            "valueName" : "help"
          }
        ],
        "commandName" : "stdev",
        "superCommands" : [
          "math",
          "stats"
        ]
      },
      {
        "abstract" : "Print the quantiles of the values (TBD).",
        "arguments" : [
          {
            "isOptional" : true,
            "isRepeating" : false,
            "kind" : "positional",
            "shouldDisplay" : true,
            "valueName" : "one-of-four"
          },
          {
            "isOptional" : true,
            "isRepeating" : false,
            "kind" : "positional",
            "shouldDisplay" : true,
            "valueName" : "custom-arg"
          },
          {
            "abstract" : "A group of floating-point values to operate on.",
            "isOptional" : true,
            "isRepeating" : true,
            "kind" : "positional",
            "shouldDisplay" : true,
            "valueName" : "values"
          },
          {
            "isOptional" : true,
            "isRepeating" : false,
            "kind" : "flag",
            "names" : [
              {
                "kind" : "long",
                "name" : "test-success-exit-code"
              }
            ],
            "preferredName" : {
              "kind" : "long",
              "name" : "test-success-exit-code"
            },
            "shouldDisplay" : false,
            "valueName" : "test-success-exit-code"
          },
          {
            "isOptional" : true,
            "isRepeating" : false,
            "kind" : "flag",
            "names" : [
              {
                "kind" : "long",
                "name" : "test-failure-exit-code"
              }
            ],
            "preferredName" : {
              "kind" : "long",
              "name" : "test-failure-exit-code"
            },
            "shouldDisplay" : false,
            "valueName" : "test-failure-exit-code"
          },
          {
            "isOptional" : true,
            "isRepeating" : false,
            "kind" : "flag",
            "names" : [
              {
                "kind" : "long",
                "name" : "test-validation-exit-code"
              }
            ],
            "preferredName" : {
              "kind" : "long",
              "name" : "test-validation-exit-code"
            },
            "shouldDisplay" : false,
            "valueName" : "test-validation-exit-code"
          },
          {
            "isOptional" : true,
            "isRepeating" : false,
            "kind" : "option",
            "names" : [
              {
                "kind" : "long",
                "name" : "test-custom-exit-code"
              }
            ],
            "preferredName" : {
              "kind" : "long",
              "name" : "test-custom-exit-code"
            },
            "shouldDisplay" : false,
            "valueName" : "test-custom-exit-code"
          },
          {
            "isOptional" : true,
            "isRepeating" : false,
            "kind" : "option",
            "names" : [
              {
                "kind" : "long",
                "name" : "file"
              }
            ],
            "preferredName" : {
              "kind" : "long",
              "name" : "file"
            },
            "shouldDisplay" : true,
            "valueName" : "file"
          },
          {
            "isOptional" : true,
            "isRepeating" : false,
            "kind" : "option",
            "names" : [
              {
                "kind" : "long",
                "name" : "directory"
              }
            ],
            "preferredName" : {
              "kind" : "long",
              "name" : "directory"
            },
            "shouldDisplay" : true,
            "valueName" : "directory"
          },
          {
            "isOptional" : true,
            "isRepeating" : false,
            "kind" : "option",
            "names" : [
              {
                "kind" : "long",
                "name" : "shell"
              }
            ],
            "preferredName" : {
              "kind" : "long",
              "name" : "shell"
            },
            "shouldDisplay" : true,
            "valueName" : "shell"
          },
          {
            "isOptional" : true,
            "isRepeating" : false,
            "kind" : "option",
            "names" : [
              {
                "kind" : "long",
                "name" : "custom"
              }
            ],
            "preferredName" : {
              "kind" : "long",
              "name" : "custom"
            },
            "shouldDisplay" : true,
            "valueName" : "custom"
          },
          {
            "abstract" : "Show the version.",
            "isOptional" : true,
            "isRepeating" : false,
            "kind" : "flag",
            "names" : [
              {
                "kind" : "long",
                "name" : "version"
              }
            ],
            "preferredName" : {
              "kind" : "long",
              "name" : "version"
            },
            "shouldDisplay" : true,
            "valueName" : "version"
          },
          {
            "abstract" : "Show help information.",
            "isOptional" : true,
            "isRepeating" : false,
            "kind" : "flag",
            "names" : [
              {
                "kind" : "short",
                "name" : "h"
              },
              {
                "kind" : "long",
                "name" : "help"
              }
            ],
            "preferredName" : {
              "kind" : "long",
              "name" : "help"
            },
            "shouldDisplay" : true,
            "valueName" : "help"
          }
        ],
        "commandName" : "quantiles",
        "superCommands" : [
          "math",
          "stats"
        ]
      }
    ],
    "superCommands" : [
      "math"
    ]
  },
  "serializationVersion" : 0
}

"""
}
