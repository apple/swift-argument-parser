//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2021-2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import Foundation
import Testing

@testable import ArgumentParser

@Suite struct InputOriginTests {}

// MARK: - `isDefaultValue`

/// Cases exercising `InputOrigin.isDefaultValue`.
///
/// Labels correspond to the input shape so failures point at the specific
/// case that regressed.
struct IsDefaultValueCase:
  @unchecked Sendable, CustomTestStringConvertible
{
  let label: String
  let elements: [InputOrigin.Element]
  let expected: Bool

  var testDescription: String { label }
}

extension InputOriginTests {
  @Test(
    arguments: [
      IsDefaultValueCase(
        label: "empty elements",
        elements: [],
        expected: false),
      IsDefaultValueCase(
        label: "[defaultValue]",
        elements: [.defaultValue],
        expected: true),
      IsDefaultValueCase(
        label: "[argumentIndex(1)]",
        elements: [.argumentIndex(SplitArguments.Index(inputIndex: 1))],
        expected: false),
      IsDefaultValueCase(
        label: "[defaultValue, argumentIndex(1)]",
        elements: [
          .defaultValue,
          .argumentIndex(SplitArguments.Index(inputIndex: 1)),
        ],
        expected: false),
    ]
  )
  func isDefaultValue(_ testCase: IsDefaultValueCase) async throws {
    let inputOrigin = InputOrigin(elements: testCase.elements)
    #expect(inputOrigin.isDefaultValue == testCase.expected)
  }
}

// MARK: - `InputOrigin.ResponseFileStep` Codable

extension InputOriginTests {
  fileprivate func encode<T: Encodable>(_ value: T) throws -> [String: Any] {
    let data = try JSONEncoder().encode(value)
    // swift-format-ignore: NeverForceUnwrap
    return
      (try JSONSerialization.jsonObject(with: data)) as! [String: Any]
  }

  @Test func responseFileStepEncodeFile() async throws {
    let step = InputOrigin.ResponseFileStep.file(path: "/a/b.txt", line: 7)
    let obj = try encode(step)
    #expect(obj["path"] as? String == "/a/b.txt")
    #expect(obj["line"] as? Int == 7)
    #expect(obj["argvIndex"] == nil)
  }

  @Test func responseFileStepEncodeArgv() async throws {
    let step = InputOrigin.ResponseFileStep.argv(index: 3)
    let obj = try encode(step)
    #expect(obj["path"] as? String == "argv")
    #expect(obj["argvIndex"] as? Int == 3)
    #expect(obj["line"] == nil)
  }
}

/// Cases exercising Codable round-trip for `InputOrigin.ResponseFileStep`.
struct ResponseFileStepRoundtripCase:
  @unchecked Sendable, CustomTestStringConvertible
{
  let label: String
  let step: InputOrigin.ResponseFileStep

  var testDescription: String { label }
}

extension InputOriginTests {
  @Test(
    arguments: [
      ResponseFileStepRoundtripCase(
        label: "file(/x/y.rsp:12)",
        step: .file(path: "/x/y.rsp", line: 12)),
      ResponseFileStepRoundtripCase(
        label: "argv(0)",
        step: .argv(index: 0)),
    ]
  )
  func responseFileStepRoundtrip(
    _ testCase: ResponseFileStepRoundtripCase
  ) async throws {
    let data = try JSONEncoder().encode(testCase.step)
    let decoded = try JSONDecoder().decode(
      InputOrigin.ResponseFileStep.self, from: data)
    #expect(testCase.step == decoded)
  }
}

// MARK: - `InputOrigin.Element` Codable

extension InputOriginTests {
  @Test func elementEncodeDefaultValue() async throws {
    let element = InputOrigin.Element.defaultValue
    let obj = try encode(element)
    #expect(obj["kind"] as? String == "default")
    #expect(obj.count == 1, "no extra fields for default: \(obj)")
  }

  @Test func elementEncodeArgumentIndex() async throws {
    let idx = SplitArguments.Index(
      inputIndex: SplitArguments.InputIndex(rawValue: 5))
    let element = InputOrigin.Element.argumentIndex(idx)
    let obj = try encode(element)
    #expect(obj["kind"] as? String == "commandLine")
    #expect(obj["argvIndex"] as? Int == 5)
    #expect(obj["chain"] == nil)
  }

  /// Nested `.responseFile` linked list should encode as a flat `chain`
  /// array from innermost to outermost, terminated by an argv step.
  @Test func elementEncodeResponseFileNested() async throws {
    // Build: main.txt:7 → shared.txt:4 → prod.txt:12 → argv[2]
    let argvTerm = InputOrigin.Element.argumentIndex(
      SplitArguments.Index(inputIndex: SplitArguments.InputIndex(rawValue: 2)))
    let level2 = InputOrigin.Element.responseFile(
      step: .file(path: "/abs/prod.txt", line: 12),
      referencedFrom: argvTerm)
    let level1 = InputOrigin.Element.responseFile(
      step: .file(path: "/abs/shared.txt", line: 4),
      referencedFrom: level2)
    let element = InputOrigin.Element.responseFile(
      step: .file(path: "/abs/main.txt", line: 7),
      referencedFrom: level1)

    let obj = try encode(element)
    #expect(obj["kind"] as? String == "responseFile")

    let chain = try #require(
      obj["chain"] as? [[String: Any]], "Missing chain in \(obj)")
    #expect(chain.count == 4)

    #expect(chain[0]["path"] as? String == "/abs/main.txt")
    #expect(chain[0]["line"] as? Int == 7)

    #expect(chain[1]["path"] as? String == "/abs/shared.txt")
    #expect(chain[1]["line"] as? Int == 4)

    #expect(chain[2]["path"] as? String == "/abs/prod.txt")
    #expect(chain[2]["line"] as? Int == 12)

    #expect(chain[3]["path"] as? String == "argv")
    #expect(chain[3]["argvIndex"] as? Int == 2)
  }
}

/// Cases exercising Codable round-trip for `InputOrigin.Element`.
///
/// Labels carry the suffix of the original XCTest method for each case.
struct ElementRoundtripCase:
  @unchecked Sendable, CustomTestStringConvertible
{
  let label: String
  let element: InputOrigin.Element

  var testDescription: String { label }

  /// Builds the three roundtrip cases — one per `InputOrigin.Element`
  /// shape (`.argumentIndex`, `.defaultValue`, and a nested
  /// `.responseFile` chain).
  static let all: [ElementRoundtripCase] = {
    let argvTerm = InputOrigin.Element.argumentIndex(
      SplitArguments.Index(inputIndex: SplitArguments.InputIndex(rawValue: 1)))
    let level1 = InputOrigin.Element.responseFile(
      step: .file(path: "/tmp/inner.txt", line: 3),
      referencedFrom: argvTerm)
    let nested = InputOrigin.Element.responseFile(
      step: .file(path: "/tmp/outer.txt", line: 1),
      referencedFrom: level1)

    return [
      ElementRoundtripCase(
        label: "argumentIndex",
        element: .argumentIndex(
          SplitArguments.Index(
            inputIndex: SplitArguments.InputIndex(rawValue: 42)))),
      ElementRoundtripCase(
        label: "defaultValue",
        element: .defaultValue),
      ElementRoundtripCase(
        label: "responseFileNested",
        element: nested),
    ]
  }()
}

extension InputOriginTests {
  @Test(arguments: ElementRoundtripCase.all)
  func elementRoundtrip(_ testCase: ElementRoundtripCase) async throws {
    let data = try JSONEncoder().encode(testCase.element)
    let decoded = try JSONDecoder().decode(
      InputOrigin.Element.self, from: data)
    #expect(testCase.element == decoded)
  }
}

// MARK: - JSON → `[String: InputOrigin.Element]` decoding
//
// These tests exercise the decoding path a consumer would use to
// interpret a JSON dump's `source` field(s) as typed
// `InputOrigin.Element` values, rather than as `[String: Any]` bags.
//
// Each test starts from a hardcoded JSON string (representing what an
// external tool or a test fixture would see on the wire), decodes it as
// `[String: InputOrigin.Element]`, and asserts the resulting typed
// values.

/// Cases exercising `[String: InputOrigin.Element]` decoding.
///
/// Labels carry the suffix of the original XCTest method for each case.
struct DecodeSourceMapCase:
  @unchecked Sendable, CustomTestStringConvertible
{
  let label: String
  let json: String
  let expected: InputOrigin.Element

  var testDescription: String { label }

  /// A `{"source": ...}` JSON payload paired with the expected decoded
  /// `InputOrigin.Element` value at `map["source"]`.
  static let all: [DecodeSourceMapCase] = {
    let argumentIndexExpected = InputOrigin.Element.argumentIndex(
      SplitArguments.Index(inputIndex: SplitArguments.InputIndex(rawValue: 5)))

    // main.txt:7 → shared.txt:4 → prod.txt:12 → argv[2]
    let nestedArgvTerm = InputOrigin.Element.argumentIndex(
      SplitArguments.Index(inputIndex: SplitArguments.InputIndex(rawValue: 2)))
    let nestedL2 = InputOrigin.Element.responseFile(
      step: .file(path: "/abs/prod.txt", line: 12),
      referencedFrom: nestedArgvTerm)
    let nestedL1 = InputOrigin.Element.responseFile(
      step: .file(path: "/abs/shared.txt", line: 4),
      referencedFrom: nestedL2)
    let nestedExpected = InputOrigin.Element.responseFile(
      step: .file(path: "/abs/main.txt", line: 7),
      referencedFrom: nestedL1)

    let singleArgvTerm = InputOrigin.Element.argumentIndex(
      SplitArguments.Index(inputIndex: SplitArguments.InputIndex(rawValue: 0)))
    let singleExpected = InputOrigin.Element.responseFile(
      step: .file(path: "/tmp/inner.txt", line: 3),
      referencedFrom: singleArgvTerm)

    return [
      DecodeSourceMapCase(
        label: "default",
        json: #"{"source": {"kind": "default"}}"#,
        expected: .defaultValue),
      DecodeSourceMapCase(
        label: "argumentIndex",
        json: #"{"source": {"kind": "commandLine", "argvIndex": 5}}"#,
        expected: argumentIndexExpected),
      DecodeSourceMapCase(
        label: "responseFileNestedChain",
        json: """
          {
            "source": {
              "kind": "responseFile",
              "chain": [
                {"path": "/abs/main.txt",   "line": 7},
                {"path": "/abs/shared.txt", "line": 4},
                {"path": "/abs/prod.txt",   "line": 12},
                {"path": "argv",            "argvIndex": 2}
              ]
            }
          }
          """,
        expected: nestedExpected),
      DecodeSourceMapCase(
        label: "responseFileSingleFile",
        json: """
          {
            "source": {
              "kind": "responseFile",
              "chain": [
                {"path": "/tmp/inner.txt", "line": 3},
                {"path": "argv", "argvIndex": 0}
              ]
            }
          }
          """,
        expected: singleExpected),
    ]
  }()
}

extension InputOriginTests {
  fileprivate func decodeSourceMap(
    _ json: String
  ) throws -> [String: InputOrigin.Element] {
    // swift-format-ignore: NeverForceUnwrap
    let data = json.data(using: .utf8)!
    return try JSONDecoder().decode(
      [String: InputOrigin.Element].self, from: data)
  }

  @Test(arguments: DecodeSourceMapCase.all)
  func decodeSourceMap(_ testCase: DecodeSourceMapCase) async throws {
    let map = try decodeSourceMap(testCase.json)
    #expect(map.count == 1)
    #expect(map["source"] == testCase.expected)
  }

  @Test func decodeSourceMapMultipleEntries() async throws {
    // A synthetic multi-entry wrapper — proves the `[String: ...]`
    // decoding preserves keys and values independently.
    let json = """
      {
        "alpha": {"kind": "default"},
        "beta":  {"kind": "commandLine", "argvIndex": 3}
      }
      """
    let map = try decodeSourceMap(json)
    #expect(map.count == 2)
    #expect(map["alpha"] == .defaultValue)
    let expectedBeta = InputOrigin.Element.argumentIndex(
      SplitArguments.Index(inputIndex: SplitArguments.InputIndex(rawValue: 3)))
    #expect(map["beta"] == expectedBeta)
  }

  /// Decoding a `responseFile` payload with an empty `chain` array must
  /// throw — an empty chain is semantically invalid (there's no
  /// argv terminator).
  @Test func decodeSourceMapEmptyChainThrows() async throws {
    let json = #"{"source": {"kind": "responseFile", "chain": []}}"#
    #expect(throws: (any Error).self) {
      try decodeSourceMap(json)
    }
  }
}
