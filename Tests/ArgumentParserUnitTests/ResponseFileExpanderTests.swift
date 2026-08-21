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

import ArgumentParserTestHelpers
import Foundation
import Testing

@testable import ArgumentParser

extension ResponseFileExpander {
  fileprivate init(maxNestingDepth: Int = 32) {
    self.init(prefix: "@", maxNestingDepth: maxNestingDepth)
  }
}

@Suite struct ResponseFileExpanderTests {}

// MARK: - ResponseFileExpander Unit Tests

extension ResponseFileExpanderTests {

  @Test func expandArgumentsWithNoResponseFiles() throws {
    var expander = ResponseFileExpander()
    let input = ["--name", "test", "--count", "42"]
    let result = try expander.expandArguments(input)

    #expect(
      result.arguments.map { $0.value } == input,
      "Arguments without @ prefix should remain unchanged")
    #expect(
      !result.hasResponseFile,
      "hasResponseFile should be false when no @file is present")
    #expect(
      result.arguments.map { $0.chain }
        == [
          [.argv(index: 0)], [.argv(index: 1)], [.argv(index: 2)],
          [.argv(index: 3)],
        ],
      "Argv-only args should each carry a single-step argv chain")
  }

  @Test func expandArgumentsWithSingleResponseFile() async throws {
    try await withTemporaryFile(
      "simple.txt",
      content: """
        --name
        TestName
        --count
        42
        """
    ) { responseFile in
      var expander = ResponseFileExpander()
      let input = ["@\(responseFile)"]
      let result = try expander.expandArguments(input)

      #expect(
        result.arguments.map { $0.value }
          == ["--name", "TestName", "--count", "42"])
      #expect(result.hasResponseFile)
      // Every expanded arg should carry a chain ending in argv[0].
      #expect(result.arguments.count == 4)
      for arg in result.arguments {
        #expect(arg.chain.last == .argv(index: 0))
      }
    }
  }

  @Test func expandArgumentsMixedResponseFileAndRegular() async throws {
    try await withTemporaryFile(
      "mixed.txt",
      content: """
        --name
        FromFile
        """
    ) { responseFile in
      var expander = ResponseFileExpander()
      let input = ["--verbose", "@\(responseFile)", "--count", "100"]
      let result = try expander.expandArguments(input)

      #expect(
        result.arguments.map { $0.value }
          == ["--verbose", "--name", "FromFile", "--count", "100"])
      #expect(result.hasResponseFile)
    }
  }

  @Test func expandArgumentsFileArgsLandAtFilesArgvPosition() async throws {
    // Guard against a regression where response-file arguments would be
    // appended after *all* command-line arguments regardless of where
    // the `@file` reference appeared in the input. In-place expansion
    // requires that file-origin arguments occupy the slot vacated by
    // the `@file` token itself — anything else would break the
    // downstream "last wins" semantics the parser depends on.
    try await withTemporaryFile(
      "middle.txt",
      content: """
        FROM_FILE_A
        FROM_FILE_B
        """
    ) { responseFile in
      var expander = ResponseFileExpander()
      let input = ["cli-before", "@\(responseFile)", "cli-after"]
      let result = try expander.expandArguments(input)

      #expect(
        result.arguments.map { $0.value }
          == ["cli-before", "FROM_FILE_A", "FROM_FILE_B", "cli-after"],
        "File-origin args must land between the preceding and following argv tokens, not at the tail"
      )
    }
  }

  @Test func expandArgumentsFileAtEndDoesNotReorderPrecedingArgs()
    async throws
  {
    // The "last wins" behaviour at parse time relies on file args
    // being placed *after* any argv tokens that preceded the `@file`
    // reference.
    try await withTemporaryFile(
      "tail.txt",
      content: """
        FROM_FILE
        """
    ) { responseFile in
      var expander = ResponseFileExpander()
      let input = ["cli-1", "cli-2", "@\(responseFile)"]
      let result = try expander.expandArguments(input)

      #expect(
        result.arguments.map { $0.value }
          == ["cli-1", "cli-2", "FROM_FILE"])
    }
  }

  @Test func expandArgumentsInterleavedResponseFilesPreserveArgvOrder()
    async throws
  {
    // Two `@file` references separated by argv tokens: each file's
    // contents must be spliced in-place, and the surrounding argv
    // tokens must retain their relative order.
    try await withTemporaryDirectory { dir in
      let file1 = try dir.createTestFile(
        "f1.txt",
        content: """
          F1_A
          F1_B
          """)
      let file2 = try dir.createTestFile(
        "f2.txt",
        content: """
          F2_A
          """)

      var expander = ResponseFileExpander()
      let input = ["head", "@\(file1)", "middle", "@\(file2)", "tail"]
      let result = try expander.expandArguments(input)

      #expect(
        result.arguments.map { $0.value }
          == ["head", "F1_A", "F1_B", "middle", "F2_A", "tail"])

      // Each expanded arg's outermost chain step should point at the
      // argv index of the token that produced it. This is what lets
      // error rendering annotate response-file arguments with the
      // correct `at argv[N]` frame.
      let outermostChain = result.arguments.map { $0.chain.last }
      #expect(
        outermostChain
          == [
            .argv(index: 0),  // "head"
            .argv(index: 1),  // "@f1.txt"
            .argv(index: 1),  // "@f1.txt"
            .argv(index: 2),  // "middle"
            .argv(index: 3),  // "@f2.txt"
            .argv(index: 4),  // "tail"
          ])
    }
  }

  @Test func expandArgumentsNestedResponseFilePreservesInPlaceOrder()
    async throws
  {
    // Nested response files: `outer.txt` contains an inline argument
    // before and after an `@inner.txt` reference. The nested file's
    // tokens must be spliced in-place *within* the outer file's
    // token stream, so the surrounding outer-file tokens keep their
    // relative order too.
    try await withTemporaryDirectory { dir in
      let innerPath = try dir.createTestFile(
        "inner.txt",
        content: """
          INNER_A
          INNER_B
          """)
      let outerPath = try dir.createTestFile(
        "outer.txt",
        content: """
          OUTER_PRE
          @inner.txt
          OUTER_POST
          """)

      var expander = ResponseFileExpander()
      let input = ["cli-before", "@\(outerPath)", "cli-after"]
      let result = try expander.expandArguments(input)

      #expect(
        result.arguments.map { $0.value }
          == [
            "cli-before",
            "OUTER_PRE",
            "INNER_A",
            "INNER_B",
            "OUTER_POST",
            "cli-after",
          ])

      // Every expanded token's chain must terminate at the argv index
      // of the top-level `@outer.txt` reference (or the argv index of
      // the token itself, for CLI-origin tokens).
      #expect(
        result.arguments.map { $0.chain.last }
          == [
            .argv(index: 0),  // "cli-before"
            .argv(index: 1),  // "@outer.txt"
            .argv(index: 1),  // "@outer.txt" (via inner)
            .argv(index: 1),  // "@outer.txt" (via inner)
            .argv(index: 1),  // "@outer.txt"
            .argv(index: 2),  // "cli-after"
          ])

      // Chain depths: CLI tokens carry a single argv step; outer-file
      // tokens carry [file(outer), argv]; inner-file tokens carry the
      // full three-step chain [file(inner), file(outer), argv].
      #expect(result.arguments.map { $0.chain.count } == [1, 2, 3, 3, 2, 1])

      // Innermost step of each expanded token identifies the source
      // location — verify line numbers propagate correctly through
      // the include chain.
      #expect(result.arguments[1].chain[0] == .file(path: outerPath, line: 1))
      #expect(result.arguments[2].chain[0] == .file(path: innerPath, line: 1))
      #expect(result.arguments[3].chain[0] == .file(path: innerPath, line: 2))
      #expect(result.arguments[4].chain[0] == .file(path: outerPath, line: 3))

      // Inner-file tokens include the outer file's `@inner.txt`
      // reference line (2) as their middle chain step.
      #expect(result.arguments[2].chain[1] == .file(path: outerPath, line: 2))
      #expect(result.arguments[3].chain[1] == .file(path: outerPath, line: 2))
    }
  }
}

// MARK: - Nested Response File Tests

extension ResponseFileExpanderTests {

  @Test func expandNestedResponseFiles() async throws {
    try await withTemporaryDirectory { dir in
      let innerFile = try dir.createTestFile(
        "inner.txt",
        content: """
          --count
          42
          --verbose
          """)

      let outerFile = try dir.createTestFile(
        "outer.txt",
        content: """
          --name
          TestName
          @\(innerFile)
          """)

      var expander = ResponseFileExpander()
      let input = ["@\(outerFile)"]
      let result = try expander.expandArguments(input)

      #expect(
        result.arguments.map { $0.value }
          == ["--name", "TestName", "--count", "42", "--verbose"])
    }
  }

  @Test func expandDeepNestedResponseFiles() async throws {
    try await withTemporaryDirectory { dir in
      let level3 = try dir.createTestFile("level3.txt", content: "--verbose")
      let level2 = try dir.createTestFile(
        "level2.txt",
        content: """
          --count
          100
          @\(level3)
          """)
      let level1 = try dir.createTestFile(
        "level1.txt",
        content: """
          --name
          DeepTest
          @\(level2)
          """)

      var expander = ResponseFileExpander()
      let input = ["@\(level1)"]
      let result = try expander.expandArguments(input)

      #expect(
        result.arguments.map { $0.value }
          == ["--name", "DeepTest", "--count", "100", "--verbose"])
    }
  }

  @Test func recursiveResponseFileDetection() async throws {
    try await withTemporaryDirectory { dir in
      let file1 = try dir.createTestFile(
        "recursive1.txt",
        content: """
          --name
          Test
          @recursive2.txt
          """)

      _ = try dir.createTestFile(
        "recursive2.txt",
        content: """
          --count
          10
          @recursive1.txt
          """)

      var expander = ResponseFileExpander()
      let input = ["@\(file1)"]

      #expect(throws: (any Error).self) {
        try expander.expandArguments(input)
      }

      do {
        _ = try expander.expandArguments(input)
        Issue.record("Expected ResponseFileError")
      } catch let responseError as ResponseFileExpander.ResponseFileError {
        if case .recursiveInclude(let url) = responseError {
          #expect(url.path.contains("recursive"))
        } else {
          Issue.record("Expected recursiveInclude error, got \(responseError)")
        }
      } catch {
        Issue.record("Expected ResponseFileError, got \(type(of: error))")
      }
    }
  }

  @Test func selfRecursiveResponseFile() async throws {
    try await withTemporaryFile(
      "self.txt",
      content: """
        --name
        Test
        @self.txt
        """
    ) { selfFile in
      var expander = ResponseFileExpander()
      let input = ["@\(selfFile)"]

      do {
        _ = try expander.expandArguments(input)
        Issue.record("Expected ResponseFileError")
      } catch let responseError as ResponseFileExpander.ResponseFileError {
        if case .recursiveInclude = responseError {
          // Expected behavior
        } else {
          Issue.record("Expected recursiveInclude error, got \(responseError)")
        }
      } catch {
        Issue.record("Expected ResponseFileError, got \(type(of: error))")
      }
    }
  }
}

// MARK: - Error Handling Tests

extension ResponseFileExpanderTests {

  @Test func fileNotFoundError() throws {
    var expander = ResponseFileExpander()
    let input = ["@/nonexistent/file.txt"]

    do {
      _ = try expander.expandArguments(input)
      Issue.record("Expected ResponseFileError")
    } catch let responseError as ResponseFileExpander.ResponseFileError {
      if case .fileNotFound = responseError {
        // Expected behavior
      } else {
        Issue.record("Expected fileNotFound error, got \(responseError)")
      }
    } catch {
      Issue.record("Expected ResponseFileError, got \(type(of: error))")
    }
  }

  @Test func filePermissionError() async throws {
    try await withTemporaryFile(
      "restricted.txt", content: "--name Test"
    ) { restrictedFile in
      // Remove read permissions
      try FileManager.default.setAttributes(
        [.posixPermissions: 0o000],
        ofItemAtPath: restrictedFile
      )
      defer {
        // Restore permissions for cleanup
        try? FileManager.default.setAttributes(
          [.posixPermissions: 0o644],
          ofItemAtPath: restrictedFile
        )
      }

      // Skip on platforms/environments where POSIX permissions don't
      // actually restrict reads — most notably root inside a Docker
      // container (root bypasses mode bits) and Windows (NTFS ACLs, not
      // POSIX modes, gate access).
      guard !FileManager.default.isReadableFile(atPath: restrictedFile) else {
        return
      }

      var expander = ResponseFileExpander()
      let input = ["@\(restrictedFile)"]

      do {
        _ = try expander.expandArguments(input)
        Issue.record("Expected ResponseFileError")
      } catch let responseError as ResponseFileExpander.ResponseFileError {
        if case .readError = responseError {
          // Expected behavior
        } else {
          Issue.record("Expected readError, got \(responseError)")
        }
      } catch {
        Issue.record("Expected ResponseFileError, got \(type(of: error))")
      }
    }
  }

  @Test func emptyResponseFile() async throws {
    try await withTemporaryFile("empty.txt", content: "") { emptyFile in
      var expander = ResponseFileExpander()
      let input = ["@\(emptyFile)", "--name", "test"]
      let result = try expander.expandArguments(input)

      #expect(result.arguments.map { $0.value } == ["--name", "test"])
    }
  }
}

// MARK: - Response File Detection Tests

extension ResponseFileExpanderTests {

  @Test func isResponseFileArgument() throws {
    let expander = ResponseFileExpander()

    #expect(expander.isResponseFileArgument("@file.txt"))
    #expect(expander.isResponseFileArgument("@/path/to/file.txt"))
    #expect(expander.isResponseFileArgument("@file with spaces.txt"))

    #expect(!expander.isResponseFileArgument("--option"))
    #expect(!expander.isResponseFileArgument("value"))
    // Double @ is literal
    #expect(!expander.isResponseFileArgument("@@literal"))
    #expect(!expander.isResponseFileArgument(""))
    // Just @ without filename
    #expect(!expander.isResponseFileArgument("@"))
  }

  @Test func extractResponseFileName() throws {
    let expander = ResponseFileExpander()

    #expect(expander.extractResponseFileName("@file.txt") == "file.txt")
    #expect(
      expander.extractResponseFileName("@/path/to/file.txt")
        == "/path/to/file.txt")
    #expect(
      expander.extractResponseFileName("@file with spaces.txt")
        == "file with spaces.txt")

    #expect(expander.extractResponseFileName("--option") == nil)
    #expect(expander.extractResponseFileName("@@literal") == nil)
    #expect(expander.extractResponseFileName("@") == nil)
  }
}

// MARK: - Configuration Tests (Future)

extension ResponseFileExpanderTests {

  @Test func customPrefix() throws {
    // Test ability to use custom prefixes like +file or -file
    // This will be implemented as a configuration option

    let expander = ResponseFileExpander(prefix: "+")

    #expect(expander.isResponseFileArgument("+file.txt"))
    #expect(!expander.isResponseFileArgument("@file.txt"))
  }

  @Test func maxNestingDepth() async throws {
    // Test that we can limit nesting depth to prevent deep recursion
    // This will be implemented as a configuration option

    try await withTemporaryDirectory { dir in
      var expander = ResponseFileExpander(maxNestingDepth: 2)

      // Create deeply nested files that exceed the limit
      let level3 = try dir.createTestFile("deep3.txt", content: "--verbose")
      let level2 = try dir.createTestFile("deep2.txt", content: "@\(level3)")
      let level1 = try dir.createTestFile("deep1.txt", content: "@\(level2)")
      let level0 = try dir.createTestFile("deep0.txt", content: "@\(level1)")

      let input = ["@\(level0)"]

      do {
        _ = try expander.expandArguments(input)
        Issue.record("Expected ResponseFileError")
      } catch let responseError as ResponseFileExpander.ResponseFileError {
        if case .maxNestingDepthExceeded = responseError {
          // Expected behavior
        } else {
          Issue.record("Expected maxNestingDepthExceeded error")
        }
      } catch {
        Issue.record("Expected ResponseFileError")
      }
    }
  }
}

// MARK: - Performance Tests

extension ResponseFileExpanderTests {

  @Test func largeResponseFile() async throws {
    // Test performance with a large number of arguments
    var content = ""
    for i in 1...10000 {
      content += "arg\(i)\n"
    }

    try await withTemporaryFile("large.txt", content: content) { largeFile in
      var expander = ResponseFileExpander()
      let input = ["@\(largeFile)"]

      let clock: ContinuousClock = ContinuousClock()
      let startTime = clock.now
      let result = try expander.expandArguments(input)
      let endTime = clock.now

      #expect(result.arguments.count == 10000)
      #expect(
        endTime - startTime
          < Duration(secondsComponent: 1, attosecondsComponent: 0),
        "Should process large file within 1 second")
    }
  }

  @Test func manySmallResponseFiles() async throws {
    // Test performance with many small response files
    try await withTemporaryDirectory { dir in
      var files: [String] = []

      for i in 1...100 {
        let file = try dir.createTestFile(
          "small\(i).txt", content: "--arg\(i) value\(i)")
        files.append("@\(file)")
      }

      var expander = ResponseFileExpander()

      let clock: ContinuousClock = ContinuousClock()
      let startTime = clock.now
      let result = try expander.expandArguments(files)
      let endTime = clock.now

      #expect(result.arguments.count == 200)  // 100 files * 2 args each
      #expect(
        endTime - startTime
          < Duration(secondsComponent: 1, attosecondsComponent: 0),
        "Should process many files within 1 second"
      )
    }
  }
}
