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
  
  public func testDumpA() throws {
    try AssertDump(for: A.self, equals: """
            {
              "command" : {
                "name" : [
                  "a"
                ],
                "abstract" : "",
                "discussion" : ""
              },
              "arguments" : [
                {
                  "valueName" : "arg",
                  "isRequired" : true,
                  "discussion" : "",
                  "abstract" : ""
                },
                {
                  "valueName" : "arg-with-help",
                  "isRequired" : true,
                  "discussion" : "",
                  "abstract" : "argument with help"
                },
                {
                  "defaultValue" : "1",
                  "valueName" : "arg-with-default-value",
                  "isRequired" : false,
                  "discussion" : "",
                  "abstract" : "argument with default value (default: 1)"
                }
              ],
              "options" : [
                {
                  "valueName" : "no-help-option",
                  "isRequired" : true,
                  "name" : [
                    "--no-help-option"
                  ],
                  "discussion" : "",
                  "abstract" : ""
                },
                {
                  "valueName" : "int-option",
                  "isRequired" : true,
                  "name" : [
                    "--int-option"
                  ],
                  "discussion" : "",
                  "abstract" : "int value option"
                },
                {
                  "defaultValue" : "0",
                  "valueName" : "int-option-with-default-value",
                  "isRequired" : false,
                  "name" : [
                    "--int-option-with-default-value"
                  ],
                  "discussion" : "",
                  "abstract" : "int value option with default value (default: 0)"
                },
                {
                  "isRequired" : false,
                  "name" : [
                    "-h",
                    "--help"
                  ],
                  "discussion" : "",
                  "abstract" : "Show help information."
                }
              ]
            }
            """)
  }
  
  public func testDumpExampleCommands() throws {
    struct TestCase {
      let expected: String
      let commandToDump: String
    }
    
    let testCases: [UInt : TestCase] = [
      #line : .init(expected: DumpHelpGenerationTests.mathDumpText, commandToDump: "math --dump-help"),
      #line : .init(expected: DumpHelpGenerationTests.mathAddDumpText, commandToDump: "math add --dump-help"),
      #line : .init(expected: DumpHelpGenerationTests.mathMultiplyDumpText, commandToDump: "math multiply --dump-help"),
      #line : .init(expected: DumpHelpGenerationTests.mathStatsDumpText, commandToDump: "math stats --dump-help")
    ]
    
    try testCases.forEach { keyAndValue in
      let (key: line, value: testCase) = keyAndValue
      try AssertJSONOutputEqual(command: testCase.commandToDump, expected: testCase.expected, line: line)
    }
  }
}

extension DumpHelpGenerationTests {
  static let mathDumpText: String =
  """
  {
    "command" : {
      "name" : [
        "math"
      ],
      "abstract" : "A utility for performing maths.",
      "discussion" : ""
    },
    "subcommands" : [
      {
        "command" : {
          "isDefault" : true,
          "name" : [
            "add"
          ],
          "discussion" : "",
          "abstract" : "Print the sum of the values."
        },
        "arguments" : [
          {
            "valueName" : "values",
            "isRequired" : false,
            "discussion" : "",
            "abstract" : "A group of integers to operate on."
          }
        ],
        "options" : [
          {
            "valueName" : "hex-output",
            "isRequired" : false,
            "name" : [
              "--hex-output",
              "-x"
            ],
            "discussion" : "",
            "abstract" : "Use hexadecimal notation for the result."
          },
          {
            "isRequired" : false,
            "name" : [
              "--version"
            ],
            "discussion" : "",
            "abstract" : "Show the version."
          },
          {
            "isRequired" : false,
            "name" : [
              "-h",
              "--help"
            ],
            "discussion" : "",
            "abstract" : "Show help information."
          }
        ]
      },
      {
        "command" : {
          "isDefault" : false,
          "name" : [
            "multiply"
          ],
          "discussion" : "",
          "abstract" : "Print the product of the values."
        },
        "arguments" : [
          {
            "valueName" : "values",
            "isRequired" : false,
            "discussion" : "",
            "abstract" : "A group of integers to operate on."
          }
        ],
        "options" : [
          {
            "valueName" : "hex-output",
            "isRequired" : false,
            "name" : [
              "--hex-output",
              "-x"
            ],
            "discussion" : "",
            "abstract" : "Use hexadecimal notation for the result."
          },
          {
            "isRequired" : false,
            "name" : [
              "--version"
            ],
            "discussion" : "",
            "abstract" : "Show the version."
          },
          {
            "isRequired" : false,
            "name" : [
              "-h",
              "--help"
            ],
            "discussion" : "",
            "abstract" : "Show help information."
          }
        ]
      },
      {
        "command" : {
          "isDefault" : false,
          "name" : [
            "stats"
          ],
          "discussion" : "",
          "abstract" : "Calculate descriptive statistics."
        },
        "subcommands" : [
          {
            "command" : {
              "isDefault" : false,
              "name" : [
                "average"
              ],
              "discussion" : "",
              "abstract" : "Print the average of the values."
            },
            "arguments" : [
              {
                "valueName" : "values",
                "isRequired" : false,
                "discussion" : "",
                "abstract" : "A group of floating-point values to operate on."
              }
            ],
            "options" : [
              {
                "defaultValue" : "mean",
                "valueName" : "kind",
                "isRequired" : false,
                "name" : [
                  "--kind"
                ],
                "discussion" : "",
                "abstract" : "The kind of average to provide. (default: mean)"
              },
              {
                "isRequired" : false,
                "name" : [
                  "--version"
                ],
                "discussion" : "",
                "abstract" : "Show the version."
              },
              {
                "isRequired" : false,
                "name" : [
                  "-h",
                  "--help"
                ],
                "discussion" : "",
                "abstract" : "Show help information."
              }
            ]
          },
          {
            "command" : {
              "isDefault" : false,
              "name" : [
                "stdev"
              ],
              "discussion" : "",
              "abstract" : "Print the standard deviation of the values."
            },
            "arguments" : [
              {
                "valueName" : "values",
                "isRequired" : false,
                "discussion" : "",
                "abstract" : "A group of floating-point values to operate on."
              }
            ],
            "options" : [
              {
                "isRequired" : false,
                "name" : [
                  "--version"
                ],
                "discussion" : "",
                "abstract" : "Show the version."
              },
              {
                "isRequired" : false,
                "name" : [
                  "-h",
                  "--help"
                ],
                "discussion" : "",
                "abstract" : "Show help information."
              }
            ]
          },
          {
            "command" : {
              "isDefault" : false,
              "name" : [
                "quantiles"
              ],
              "discussion" : "",
              "abstract" : "Print the quantiles of the values (TBD)."
            },
            "arguments" : [
              {
                "valueName" : "one-of-four",
                "isRequired" : false,
                "discussion" : "",
                "abstract" : ""
              },
              {
                "valueName" : "custom-arg",
                "isRequired" : false,
                "discussion" : "",
                "abstract" : ""
              },
              {
                "valueName" : "values",
                "isRequired" : false,
                "discussion" : "",
                "abstract" : "A group of floating-point values to operate on."
              }
            ],
            "options" : [
              {
                "valueName" : "file",
                "isRequired" : false,
                "name" : [
                  "--file"
                ],
                "discussion" : "",
                "abstract" : ""
              },
              {
                "valueName" : "directory",
                "isRequired" : false,
                "name" : [
                  "--directory"
                ],
                "discussion" : "",
                "abstract" : ""
              },
              {
                "valueName" : "shell",
                "isRequired" : false,
                "name" : [
                  "--shell"
                ],
                "discussion" : "",
                "abstract" : ""
              },
              {
                "valueName" : "custom",
                "isRequired" : false,
                "name" : [
                  "--custom"
                ],
                "discussion" : "",
                "abstract" : ""
              },
              {
                "isRequired" : false,
                "name" : [
                  "--version"
                ],
                "discussion" : "",
                "abstract" : "Show the version."
              },
              {
                "isRequired" : false,
                "name" : [
                  "-h",
                  "--help"
                ],
                "discussion" : "",
                "abstract" : "Show help information."
              }
            ]
          }
        ],
        "options" : [
          {
            "isRequired" : false,
            "name" : [
              "--version"
            ],
            "discussion" : "",
            "abstract" : "Show the version."
          },
          {
            "isRequired" : false,
            "name" : [
              "-h",
              "--help"
            ],
            "discussion" : "",
            "abstract" : "Show help information."
          }
        ]
      }
    ],
    "options" : [
      {
        "isRequired" : false,
        "name" : [
          "--version"
        ],
        "discussion" : "",
        "abstract" : "Show the version."
      },
      {
        "isRequired" : false,
        "name" : [
          "-h",
          "--help"
        ],
        "discussion" : "",
        "abstract" : "Show help information."
      }
    ]
  }
  """
  
  static let mathStatsDumpText: String =
  """
  {
    "command" : {
      "name" : [
        "math stats"
      ],
      "abstract" : "Calculate descriptive statistics.",
      "discussion" : ""
    },
    "subcommands" : [
      {
        "command" : {
          "isDefault" : false,
          "name" : [
            "average"
          ],
          "discussion" : "",
          "abstract" : "Print the average of the values."
        },
        "arguments" : [
          {
            "valueName" : "values",
            "isRequired" : false,
            "discussion" : "",
            "abstract" : "A group of floating-point values to operate on."
          }
        ],
        "options" : [
          {
            "defaultValue" : "mean",
            "valueName" : "kind",
            "isRequired" : false,
            "name" : [
              "--kind"
            ],
            "discussion" : "",
            "abstract" : "The kind of average to provide. (default: mean)"
          },
          {
            "isRequired" : false,
            "name" : [
              "--version"
            ],
            "discussion" : "",
            "abstract" : "Show the version."
          },
          {
            "isRequired" : false,
            "name" : [
              "-h",
              "--help"
            ],
            "discussion" : "",
            "abstract" : "Show help information."
          }
        ]
      },
      {
        "command" : {
          "isDefault" : false,
          "name" : [
            "stdev"
          ],
          "discussion" : "",
          "abstract" : "Print the standard deviation of the values."
        },
        "arguments" : [
          {
            "valueName" : "values",
            "isRequired" : false,
            "discussion" : "",
            "abstract" : "A group of floating-point values to operate on."
          }
        ],
        "options" : [
          {
            "isRequired" : false,
            "name" : [
              "--version"
            ],
            "discussion" : "",
            "abstract" : "Show the version."
          },
          {
            "isRequired" : false,
            "name" : [
              "-h",
              "--help"
            ],
            "discussion" : "",
            "abstract" : "Show help information."
          }
        ]
      },
      {
        "command" : {
          "isDefault" : false,
          "name" : [
            "quantiles"
          ],
          "discussion" : "",
          "abstract" : "Print the quantiles of the values (TBD)."
        },
        "arguments" : [
          {
            "valueName" : "one-of-four",
            "isRequired" : false,
            "discussion" : "",
            "abstract" : ""
          },
          {
            "valueName" : "custom-arg",
            "isRequired" : false,
            "discussion" : "",
            "abstract" : ""
          },
          {
            "valueName" : "values",
            "isRequired" : false,
            "discussion" : "",
            "abstract" : "A group of floating-point values to operate on."
          }
        ],
        "options" : [
          {
            "valueName" : "file",
            "isRequired" : false,
            "name" : [
              "--file"
            ],
            "discussion" : "",
            "abstract" : ""
          },
          {
            "valueName" : "directory",
            "isRequired" : false,
            "name" : [
              "--directory"
            ],
            "discussion" : "",
            "abstract" : ""
          },
          {
            "valueName" : "shell",
            "isRequired" : false,
            "name" : [
              "--shell"
            ],
            "discussion" : "",
            "abstract" : ""
          },
          {
            "valueName" : "custom",
            "isRequired" : false,
            "name" : [
              "--custom"
            ],
            "discussion" : "",
            "abstract" : ""
          },
          {
            "isRequired" : false,
            "name" : [
              "--version"
            ],
            "discussion" : "",
            "abstract" : "Show the version."
          },
          {
            "isRequired" : false,
            "name" : [
              "-h",
              "--help"
            ],
            "discussion" : "",
            "abstract" : "Show help information."
          }
        ]
      }
    ],
    "options" : [
      {
        "isRequired" : false,
        "name" : [
          "--version"
        ],
        "discussion" : "",
        "abstract" : "Show the version."
      },
      {
        "isRequired" : false,
        "name" : [
          "-h",
          "--help"
        ],
        "discussion" : "",
        "abstract" : "Show help information."
      }
    ]
  }
  """
  
  static let mathAddDumpText: String =
  """
  {
    "command" : {
      "name" : [
        "math add"
      ],
      "abstract" : "Print the sum of the values.",
      "discussion" : ""
    },
    "arguments" : [
      {
        "valueName" : "values",
        "isRequired" : false,
        "discussion" : "",
        "abstract" : "A group of integers to operate on."
      }
    ],
    "options" : [
      {
        "valueName" : "hex-output",
        "isRequired" : false,
        "name" : [
          "--hex-output",
          "-x"
        ],
        "discussion" : "",
        "abstract" : "Use hexadecimal notation for the result."
      },
      {
        "isRequired" : false,
        "name" : [
          "--version"
        ],
        "discussion" : "",
        "abstract" : "Show the version."
      },
      {
        "isRequired" : false,
        "name" : [
          "-h",
          "--help"
        ],
        "discussion" : "",
        "abstract" : "Show help information."
      }
    ]
  }
  """
  
  static let mathMultiplyDumpText: String =
  """
  {
    "command" : {
      "name" : [
        "math multiply"
      ],
      "abstract" : "Print the product of the values.",
      "discussion" : ""
    },
    "arguments" : [
      {
        "valueName" : "values",
        "isRequired" : false,
        "discussion" : "",
        "abstract" : "A group of integers to operate on."
      }
    ],
    "options" : [
      {
        "valueName" : "hex-output",
        "isRequired" : false,
        "name" : [
          "--hex-output",
          "-x"
        ],
        "discussion" : "",
        "abstract" : "Use hexadecimal notation for the result."
      },
      {
        "isRequired" : false,
        "name" : [
          "--version"
        ],
        "discussion" : "",
        "abstract" : "Show the version."
      },
      {
        "isRequired" : false,
        "name" : [
          "-h",
          "--help"
        ],
        "discussion" : "",
        "abstract" : "Show help information."
      }
    ]
  }
  """
}
