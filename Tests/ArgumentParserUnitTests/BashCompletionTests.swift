//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if os(macOS) || os(Linux)
import ArgumentParser
import Foundation
import Testing

extension SerializedTests {
  struct BashCompletionTests {}
}

extension SerializedTests.BashCompletionTests {
  static let candidates = [
    "it's", "say \"hi\"", "back\\slash", "two words", "$literal",
    "*.swift", "[abc]", "semi;colon",
  ]

  struct OptionCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "literal-list")

    @Option(completion: .list(SerializedTests.BashCompletionTests.candidates))
    var value: String
  }

  struct ArgumentCommand: ParsableCommand {
    static let configuration = CommandConfiguration(commandName: "literal-list")

    @Argument(completion: .list(SerializedTests.BashCompletionTests.candidates))
    var value: String
  }

  @Test(
    .enabled(if: FileManager.default.isExecutableFile(atPath: "/bin/bash")),
    arguments: [false, true],
    ["", "it", "say", "back", "two", "$", "*", "[", "missing"]
  )
  func literalListCandidates(option: Bool, prefix: String) throws {
    let command: any ParsableCommand.Type =
      option ? OptionCommand.self : ArgumentCommand.self
    let script =
      command.completionScript(for: .bash) + """

        COMP_WORDS=(literal-list \(option ? "--value " : "")"${1}")
        COMP_CWORD=$((${#COMP_WORDS[@]} - 1))
        COMP_LINE="${COMP_WORDS[*]}"
        COMP_POINT=${#COMP_LINE}
        _literal-list literal-list "${1}" "${COMP_WORDS[COMP_CWORD - 1]}"
        if [[ ${#COMPREPLY[@]} -gt 0 ]]; then
            printf '%s\\0' "${COMPREPLY[@]}"
        fi
        """

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/bash")
    process.arguments = [
      "--noprofile", "--norc", "-c", script, "completion-test", prefix,
    ]
    let output = Pipe()
    let error = Pipe()
    process.standardOutput = output
    process.standardError = error
    try process.run()
    let outputData = output.fileHandleForReading.readDataToEndOfFile()
    let errorData = error.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()

    #expect(process.terminationStatus == 0)
    #expect(String(decoding: errorData, as: UTF8.self).isEmpty)
    let actual = String(decoding: outputData, as: UTF8.self)
      .split(separator: "\0").map(String.init)
    #expect(actual == Self.candidates.filter { $0.hasPrefix(prefix) })
  }
}
#endif
