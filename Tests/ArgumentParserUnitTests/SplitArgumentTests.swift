//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020-2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import ArgumentParserTestHelpers
import Testing

@testable import ArgumentParser

extension ArgumentParser.SplitArguments.InputIndex: Swift
    .ExpressibleByIntegerLiteral
{
  public init(integerLiteral value: Int) {
    self.init(rawValue: value)
  }
}

private func expectIndexEqual(
  _ sut: SplitArguments, at index: Int, inputIndex: Int,
  subIndex: SplitArguments.SubIndex,
  sourceLocation: SourceLocation = #_sourceLocation
) throws {
  try #require(
    index < sut.elements.endIndex,
    "Element index \(index) is out of range. sut only has \(sut.elements.count) elements.",
    sourceLocation: sourceLocation
  )

  let splitIndex = sut.elements[index].index
  let expected = SplitArguments.Index(
    inputIndex: SplitArguments.InputIndex(rawValue: inputIndex),
    subIndex: subIndex
  )
  #expect(
    splitIndex.inputIndex == expected.inputIndex,
    "inputIndex does not match: \(splitIndex.inputIndex.rawValue) != \(expected.inputIndex.rawValue)",
    sourceLocation: sourceLocation
  )

  #expect(
    splitIndex.subIndex == expected.subIndex,
    "subIndex does not match: \(splitIndex.subIndex) != \(expected.subIndex)",
    sourceLocation: sourceLocation
  )
}

private func expectElementEqual(
  _ sut: SplitArguments, at index: Int, _ element: SplitArguments.Element.Value,
  sourceLocation: SourceLocation = #_sourceLocation
) throws {
  try #require(
    index < sut.elements.endIndex,
    "Element index \(index) is out of range. sut only has \(sut.elements.count) elements.",
    sourceLocation: sourceLocation
  )
  #expect(
    sut.elements[index].value == element,
    sourceLocation: sourceLocation
  )
}

@Suite struct SplitArgumentTests {
  @Test func empty() async throws {
    let sut = try SplitArguments(arguments: [])
    #expect(sut.elements.count == 0)
    #expect(sut.originalInput.count == 0)
  }

  @Test func singleValue() async throws {
    let sut = try SplitArguments(arguments: ["abc"])

    #expect(sut.elements.count == 1)
    try expectIndexEqual(sut, at: 0, inputIndex: 0, subIndex: .complete)
    try expectElementEqual(sut, at: 0, .value("abc"))

    #expect(sut.originalInput.count == 1)
    #expect(sut.originalInput == ["abc"])
  }

  @Test func singleLongOption() async throws {
    let sut = try SplitArguments(arguments: ["--abc"])

    #expect(sut.elements.count == 1)
    try expectIndexEqual(sut, at: 0, inputIndex: 0, subIndex: .complete)
    try expectElementEqual(sut, at: 0, .option(.name(.long("abc"))))

    #expect(sut.originalInput.count == 1)
    #expect(sut.originalInput == ["--abc"])
  }

  @Test func singleShortOption() async throws {
    let sut = try SplitArguments(arguments: ["-a"])

    #expect(sut.elements.count == 1)
    try expectIndexEqual(sut, at: 0, inputIndex: 0, subIndex: .complete)
    try expectElementEqual(sut, at: 0, .option(.name(.short("a"))))

    #expect(sut.originalInput.count == 1)
    #expect(sut.originalInput == ["-a"])
  }

  @Test func singleLongOptionWithValue() async throws {
    let sut = try SplitArguments(arguments: ["--abc=def"])

    #expect(sut.elements.count == 1)
    try expectIndexEqual(sut, at: 0, inputIndex: 0, subIndex: .complete)
    try expectElementEqual(
      sut, at: 0, .option(.nameWithValue(.long("abc"), "def"))
    )

    #expect(sut.originalInput.count == 1)
    #expect(sut.originalInput == ["--abc=def"])
  }

  @Test func multipleShortOptionsCombined() async throws {
    let sut = try SplitArguments(arguments: ["-abc"])

    #expect(sut.elements.count == 4)

    try expectIndexEqual(sut, at: 0, inputIndex: 0, subIndex: .complete)
    try expectElementEqual(
      sut, at: 0, .option(.name(.longWithSingleDash("abc")))
    )

    try expectIndexEqual(sut, at: 1, inputIndex: 0, subIndex: .sub(0))
    try expectElementEqual(sut, at: 1, .option(.name(.short("a"))))

    try expectIndexEqual(sut, at: 2, inputIndex: 0, subIndex: .sub(1))
    try expectElementEqual(sut, at: 2, .option(.name(.short("b"))))

    try expectIndexEqual(sut, at: 3, inputIndex: 0, subIndex: .sub(2))
    try expectElementEqual(sut, at: 3, .option(.name(.short("c"))))

    #expect(sut.originalInput.count == 1)
    #expect(sut.originalInput == ["-abc"])
  }

  @Test func singleLongOptionWithValueAndSingleDash() async throws {
    let sut = try SplitArguments(arguments: ["-abc=def"])

    #expect(sut.elements.count == 1)

    try expectIndexEqual(sut, at: 0, inputIndex: 0, subIndex: .complete)
    try expectElementEqual(
      sut, at: 0, .option(.nameWithValue(.longWithSingleDash("abc"), "def")))

    #expect(sut.originalInput.count == 1)
    #expect(sut.originalInput == ["-abc=def"])
  }
}

// https://github.com/apple/swift-argument-parser/issues/710
extension SplitArgumentTests {
  @Test func multipleValues() async throws {
    let sut = try SplitArguments(arguments: ["abc", "x", "1234"])

    #expect(sut.elements.count == 3)

    try expectIndexEqual(sut, at: 0, inputIndex: 0, subIndex: .complete)
    try expectElementEqual(sut, at: 0, .value("abc"))

    try expectIndexEqual(sut, at: 1, inputIndex: 1, subIndex: .complete)
    try expectElementEqual(sut, at: 1, .value("x"))

    try expectIndexEqual(sut, at: 2, inputIndex: 2, subIndex: .complete)
    try expectElementEqual(sut, at: 2, .value("1234"))

    #expect(sut.originalInput.count == 3)
    #expect(sut.originalInput == ["abc", "x", "1234"])
  }

  @Test func multipleLongOptions() async throws {
    let sut = try SplitArguments(arguments: ["--d", "--1", "--abc-def"])

    #expect(sut.elements.count == 3)

    try expectIndexEqual(sut, at: 0, inputIndex: 0, subIndex: .complete)
    try expectElementEqual(sut, at: 0, .option(.name(.long("d"))))

    try expectIndexEqual(sut, at: 1, inputIndex: 1, subIndex: .complete)
    try expectElementEqual(sut, at: 1, .option(.name(.long("1"))))

    try expectIndexEqual(sut, at: 2, inputIndex: 2, subIndex: .complete)
    try expectElementEqual(sut, at: 2, .option(.name(.long("abc-def"))))

    #expect(sut.originalInput.count == 3)
    #expect(sut.originalInput == ["--d", "--1", "--abc-def"])
  }

  @Test func multipleShortOptions() async throws {
    let sut = try SplitArguments(arguments: ["-x", "-y", "-z"])

    #expect(sut.elements.count == 3)

    try expectIndexEqual(sut, at: 0, inputIndex: 0, subIndex: .complete)
    try expectElementEqual(sut, at: 0, .option(.name(.short("x"))))

    try expectIndexEqual(sut, at: 1, inputIndex: 1, subIndex: .complete)
    try expectElementEqual(sut, at: 1, .option(.name(.short("y"))))

    try expectIndexEqual(sut, at: 2, inputIndex: 2, subIndex: .complete)
    try expectElementEqual(sut, at: 2, .option(.name(.short("z"))))

    #expect(sut.originalInput.count == 3)
    #expect(sut.originalInput == ["-x", "-y", "-z"])
  }

  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func multipleShortOptionsCombined_2() async throws {
    let sut = try SplitArguments(arguments: ["-bc", "-fv", "-a"])

    #expect(sut.elements.count == 7)

    try expectIndexEqual(sut, at: 0, inputIndex: 0, subIndex: .complete)
    try expectElementEqual(
      sut, at: 0, .option(.name(.longWithSingleDash("bc")))
    )

    try expectIndexEqual(sut, at: 1, inputIndex: 0, subIndex: .sub(0))
    try expectElementEqual(sut, at: 1, .option(.name(.short("b"))))

    try expectIndexEqual(sut, at: 2, inputIndex: 0, subIndex: .sub(1))
    try expectElementEqual(sut, at: 2, .option(.name(.short("c"))))

    try expectIndexEqual(sut, at: 3, inputIndex: 1, subIndex: .complete)
    try expectElementEqual(
      sut, at: 3, .option(.name(.longWithSingleDash("fv")))
    )

    try expectIndexEqual(sut, at: 4, inputIndex: 1, subIndex: .sub(0))
    try expectElementEqual(sut, at: 4, .option(.name(.short("f"))))

    try expectIndexEqual(sut, at: 5, inputIndex: 1, subIndex: .sub(1))
    try expectElementEqual(sut, at: 5, .option(.name(.short("v"))))

    try expectIndexEqual(sut, at: 6, inputIndex: 2, subIndex: .complete)
    try expectElementEqual(sut, at: 6, .option(.name(.short("a"))))

    #expect(sut.originalInput.count == 3)
    #expect(sut.originalInput == ["-bc", "-fv", "-a"])
  }
}

// https://github.com/apple/swift-argument-parser/issues/710
extension SplitArgumentTests {
  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func mixed_1() async throws {
    let sut = try SplitArguments(arguments: [
      "-x", "abc", "--foo", "1234", "-zz",
    ])

    #expect(sut.elements.count == 7)

    try expectIndexEqual(sut, at: 0, inputIndex: 0, subIndex: .complete)
    try expectElementEqual(sut, at: 0, .option(.name(.short("x"))))

    try expectIndexEqual(sut, at: 1, inputIndex: 1, subIndex: .complete)
    try expectElementEqual(sut, at: 1, .value("abc"))

    try expectIndexEqual(sut, at: 2, inputIndex: 2, subIndex: .complete)
    try expectElementEqual(sut, at: 2, .option(.name(.long("foo"))))

    try expectIndexEqual(sut, at: 3, inputIndex: 3, subIndex: .complete)
    try expectElementEqual(sut, at: 3, .value("1234"))

    try expectIndexEqual(sut, at: 4, inputIndex: 4, subIndex: .complete)
    try expectElementEqual(
      sut, at: 4, .option(.name(.longWithSingleDash("zz")))
    )

    try expectIndexEqual(sut, at: 5, inputIndex: 4, subIndex: .sub(0))
    try expectElementEqual(sut, at: 5, .option(.name(.short("z"))))

    try expectIndexEqual(sut, at: 6, inputIndex: 4, subIndex: .sub(1))
    try expectElementEqual(sut, at: 6, .option(.name(.short("z"))))

    #expect(sut.originalInput.count == 5)
    #expect(sut.originalInput == ["-x", "abc", "--foo", "1234", "-zz"])
  }

  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func mixed_2() async throws {
    let sut = try SplitArguments(arguments: [
      "1234", "-zz", "abc", "-x", "--foo",
    ])

    #expect(sut.elements.count == 7)

    try expectIndexEqual(sut, at: 0, inputIndex: 0, subIndex: .complete)
    try expectElementEqual(sut, at: 0, .value("1234"))

    try expectIndexEqual(sut, at: 1, inputIndex: 1, subIndex: .complete)
    try expectElementEqual(
      sut, at: 1, .option(.name(.longWithSingleDash("zz")))
    )

    try expectIndexEqual(sut, at: 2, inputIndex: 1, subIndex: .sub(0))
    try expectElementEqual(sut, at: 2, .option(.name(.short("z"))))

    try expectIndexEqual(sut, at: 3, inputIndex: 1, subIndex: .sub(1))
    try expectElementEqual(sut, at: 3, .option(.name(.short("z"))))

    try expectIndexEqual(sut, at: 4, inputIndex: 2, subIndex: .complete)
    try expectElementEqual(sut, at: 4, .value("abc"))

    try expectIndexEqual(sut, at: 5, inputIndex: 3, subIndex: .complete)
    try expectElementEqual(sut, at: 5, .option(.name(.short("x"))))

    try expectIndexEqual(sut, at: 6, inputIndex: 4, subIndex: .complete)
    try expectElementEqual(sut, at: 6, .option(.name(.long("foo"))))

    #expect(sut.originalInput.count == 5)
    #expect(sut.originalInput == ["1234", "-zz", "abc", "-x", "--foo"])
  }

  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func terminator_1() async throws {
    let sut = try SplitArguments(arguments: ["--foo", "--", "--bar"])

    #expect(sut.elements.count == 3)

    try expectIndexEqual(sut, at: 0, inputIndex: 0, subIndex: .complete)
    try expectElementEqual(sut, at: 0, .option(.name(.long("foo"))))

    try expectIndexEqual(sut, at: 1, inputIndex: 1, subIndex: .complete)
    try expectElementEqual(sut, at: 1, .terminator)

    try expectIndexEqual(sut, at: 2, inputIndex: 2, subIndex: .complete)
    try expectElementEqual(sut, at: 2, .value("--bar"))

    #expect(sut.originalInput.count == 3)
    #expect(sut.originalInput == ["--foo", "--", "--bar"])
  }

  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func terminator_2() async throws {
    let sut = try SplitArguments(arguments: ["--foo", "--", "bar"])

    #expect(sut.elements.count == 3)

    try expectIndexEqual(sut, at: 0, inputIndex: 0, subIndex: .complete)
    try expectElementEqual(sut, at: 0, .option(.name(.long("foo"))))

    try expectIndexEqual(sut, at: 1, inputIndex: 1, subIndex: .complete)
    try expectElementEqual(sut, at: 1, .terminator)

    try expectIndexEqual(sut, at: 2, inputIndex: 2, subIndex: .complete)
    try expectElementEqual(sut, at: 2, .value("bar"))

    #expect(sut.originalInput.count == 3)
    #expect(sut.originalInput == ["--foo", "--", "bar"])
  }

  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func terminator_3() async throws {
    let sut = try SplitArguments(arguments: ["--foo", "--", "--bar=baz"])

    #expect(sut.elements.count == 3)

    try expectIndexEqual(sut, at: 0, inputIndex: 0, subIndex: .complete)
    try expectElementEqual(sut, at: 0, .option(.name(.long("foo"))))

    try expectIndexEqual(sut, at: 1, inputIndex: 1, subIndex: .complete)
    try expectElementEqual(sut, at: 1, .terminator)

    try expectIndexEqual(sut, at: 2, inputIndex: 2, subIndex: .complete)
    try expectElementEqual(sut, at: 2, .value("--bar=baz"))

    #expect(sut.originalInput.count == 3)
    #expect(sut.originalInput == ["--foo", "--", "--bar=baz"])
  }

  @Test func terminatorAtTheEnd() async throws {
    let sut = try SplitArguments(arguments: ["--foo", "--"])

    #expect(sut.elements.count == 2)

    try expectIndexEqual(sut, at: 0, inputIndex: 0, subIndex: .complete)
    try expectElementEqual(sut, at: 0, .option(.name(.long("foo"))))

    try expectIndexEqual(sut, at: 1, inputIndex: 1, subIndex: .complete)
    try expectElementEqual(sut, at: 1, .terminator)

    #expect(sut.originalInput.count == 2)
    #expect(sut.originalInput == ["--foo", "--"])
  }

  @Test func terminatorAtTheBeginning() async throws {
    let sut = try SplitArguments(arguments: ["--", "--foo"])

    #expect(sut.elements.count == 2)

    try expectIndexEqual(sut, at: 0, inputIndex: 0, subIndex: .complete)
    try expectElementEqual(sut, at: 0, .terminator)

    try expectIndexEqual(sut, at: 1, inputIndex: 1, subIndex: .complete)
    try expectElementEqual(sut, at: 1, .value("--foo"))

    #expect(sut.originalInput.count == 2)
    #expect(sut.originalInput == ["--", "--foo"])
  }
}

// MARK: - Removing Entries

// https://github.com/apple/swift-argument-parser/issues/710
extension SplitArgumentTests {
  @Test func removingValuesForLongNames() async throws {
    var sut = try SplitArguments(arguments: ["--foo", "--bar"])
    #expect(sut.elements.count == 2)
    sut.remove(at: SplitArguments.Index(inputIndex: 0, subIndex: .complete))
    #expect(sut.elements.count == 1)
    sut.remove(at: SplitArguments.Index(inputIndex: 1, subIndex: .complete))
    #expect(sut.elements.count == 0)
  }

  @Test func removingValuesForLongNamesWithValue() async throws {
    var sut = try SplitArguments(arguments: ["--foo=A", "--bar=B"])
    #expect(sut.elements.count == 2)
    sut.remove(at: SplitArguments.Index(inputIndex: 0, subIndex: .complete))
    #expect(sut.elements.count == 1)
    sut.remove(at: SplitArguments.Index(inputIndex: 1, subIndex: .complete))
    #expect(sut.elements.count == 0)
  }

  @Test func removingValuesForShortNames() async throws {
    var sut = try SplitArguments(arguments: ["-f", "-b"])
    #expect(sut.elements.count == 2)
    sut.remove(at: SplitArguments.Index(inputIndex: 0, subIndex: .complete))
    #expect(sut.elements.count == 1)
    sut.remove(at: SplitArguments.Index(inputIndex: 1, subIndex: .complete))
    #expect(sut.elements.count == 0)
  }

  @Test func removingValuesForCombinedShortNames() async throws {
    let sut = try SplitArguments(arguments: ["-fb"])

    #expect(sut.elements.count == 3)
    try expectIndexEqual(sut, at: 0, inputIndex: 0, subIndex: .complete)
    try expectElementEqual(
      sut, at: 0, .option(.name(.longWithSingleDash("fb")))
    )
    try expectIndexEqual(sut, at: 1, inputIndex: 0, subIndex: .sub(0))
    try expectElementEqual(sut, at: 1, .option(.name(.short("f"))))
    try expectIndexEqual(sut, at: 2, inputIndex: 0, subIndex: .sub(1))
    try expectElementEqual(sut, at: 2, .option(.name(.short("b"))))

    do {
      var sutB = sut
      sutB.remove(at: SplitArguments.Index(inputIndex: 0, subIndex: .complete))

      #expect(sutB.elements.count == 0)
    }
    do {
      var sutB = sut
      sutB.remove(at: SplitArguments.Index(inputIndex: 0, subIndex: .sub(0)))

      #expect(sutB.elements.count == 1)
      try expectIndexEqual(sutB, at: 2, inputIndex: 0, subIndex: .sub(1))
      try expectElementEqual(sutB, at: 2, .option(.name(.short("b"))))
    }
    do {
      var sutB = sut
      sutB.remove(at: SplitArguments.Index(inputIndex: 0, subIndex: .sub(1)))

      #expect(sutB.elements.count == 1)
      try expectIndexEqual(sutB, at: 2, inputIndex: 0, subIndex: .sub(0))
      try expectElementEqual(sutB, at: 2, .option(.name(.short("f"))))
    }
  }
}

// MARK: - Pop & Peek

// https://github.com/apple/swift-argument-parser/issues/710
extension SplitArgumentTests {
  @Test func popNext() async throws {
    var sut = try SplitArguments(arguments: ["--foo", "bar"])

    let popedValueA = sut.popNext()
    let a = try #require(popedValueA)
    #expect(
      a.0
        == .argumentIndex(
          SplitArguments.Index(inputIndex: 0, subIndex: .complete)))
    #expect(a.1.value == .option(.name(.long("foo"))))

    let popedValueB = sut.popNext()
    let b = try #require(popedValueB)
    #expect(
      b.0
        == .argumentIndex(
          SplitArguments.Index(inputIndex: 1, subIndex: .complete)))
    #expect(b.1.value == .value("bar"))

    #expect(sut.popNext() == nil)
  }

  @Test func peekNext() async throws {
    let sut = try SplitArguments(arguments: ["--foo", "bar"])

    let a = try #require(sut.peekNext())
    #expect(
      a.0
        == .argumentIndex(
          SplitArguments.Index(inputIndex: 0, subIndex: .complete)))
    #expect(a.1.value == .option(.name(.long("foo"))))

    let b = try #require(sut.peekNext())
    #expect(
      b.0
        == .argumentIndex(
          SplitArguments.Index(inputIndex: 0, subIndex: .complete)))
    #expect(b.1.value == .option(.name(.long("foo"))))
  }

  @Test func peekNextWhenEmpty() async throws {
    let sut = try SplitArguments(arguments: [])
    #expect(sut.peekNext() == nil)
  }

  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func popNextElementIfValueAfter_1() async throws {
    var sut = try SplitArguments(arguments: ["--bar", "bar", "--foo", "foo"])

    let optValue = sut.popNextElementIfValue(
      after: .argumentIndex(
        SplitArguments.Index(inputIndex: 0, subIndex: .complete)
      )
    )
    let value = try #require(optValue)
    #expect(
      value.0
        == .argumentIndex(
          SplitArguments.Index(inputIndex: 1, subIndex: .complete)))
    #expect(value.1 == "bar")
  }

  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func popNextElementIfValueAfter_2() async throws {
    var sut = try SplitArguments(arguments: ["--bar", "bar", "--foo", "foo"])

    let optValue = sut.popNextElementIfValue(
      after: .argumentIndex(
        SplitArguments.Index(inputIndex: 2, subIndex: .complete)
      )
    )
    let value = try #require(optValue)
    #expect(
      value.0
        == .argumentIndex(
          SplitArguments.Index(inputIndex: 3, subIndex: .complete)))
    #expect(value.1 == "foo")
  }

  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func popNextElementIfValueAfter_3() async throws {
    var sut = try SplitArguments(arguments: ["--bar", "bar", "--foo", "foo"])
    #expect(
      sut.popNextElementIfValue(
        after: .argumentIndex(
          SplitArguments.Index(inputIndex: 1, subIndex: .complete))) == nil)
  }

  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func popNextValueAfter_1() async throws {
    var sut = try SplitArguments(arguments: ["--bar", "bar", "--foo", "foo"])

    let optValueA = sut.popNextValue(
      after: .argumentIndex(
        SplitArguments.Index(inputIndex: 0, subIndex: .complete)
      )
    )
    let valueA = try #require(optValueA)
    #expect(
      valueA.0
        == .argumentIndex(
          SplitArguments.Index(inputIndex: 1, subIndex: .complete)))
    #expect(valueA.1 == "bar")

    let optValueB = sut.popNextValue(
      after: .argumentIndex(
        SplitArguments.Index(inputIndex: 0, subIndex: .complete)
      )
    )
    let valueB = try #require(optValueB)
    #expect(
      valueB.0
        == .argumentIndex(
          SplitArguments.Index(inputIndex: 3, subIndex: .complete)))
    #expect(valueB.1 == "foo")
  }

  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func popNextValueAfter_2() async throws {
    var sut = try SplitArguments(arguments: ["--bar", "bar", "--foo", "foo"])

    let optValue = sut.popNextValue(
      after: .argumentIndex(
        SplitArguments.Index(inputIndex: 2, subIndex: .complete)
      )
    )
    let value = try #require(optValue)
    #expect(
      value.0
        == .argumentIndex(
          SplitArguments.Index(inputIndex: 3, subIndex: .complete)))
    #expect(value.1 == "foo")

    #expect(
      sut.popNextValue(
        after: .argumentIndex(
          SplitArguments.Index(inputIndex: 2, subIndex: .complete))) == nil)
  }

  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func popNextValueAfter_3() async throws {
    var sut = try SplitArguments(arguments: ["--bar", "bar", "--foo", "foo"])

    #expect(
      sut.popNextValue(
        after: .argumentIndex(
          SplitArguments.Index(inputIndex: 3, subIndex: .complete))) == nil)
  }

  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func popNextElementAsValueAfter_1() async throws {
    var sut = try SplitArguments(arguments: ["--bar", "bar", "--foo", "foo"])

    let optValueA = sut.popNextElementAsValue(
      after: .argumentIndex(
        SplitArguments.Index(inputIndex: 0, subIndex: .complete)
      )
    )
    let valueA = try #require(optValueA)
    #expect(
      valueA.0
        == .argumentIndex(
          SplitArguments.Index(inputIndex: 1, subIndex: .complete)))
    #expect(valueA.1 == "bar")

    let optValueB = sut.popNextElementAsValue(
      after: .argumentIndex(
        SplitArguments.Index(inputIndex: 0, subIndex: .complete)
      )
    )
    let valueB = try #require(optValueB)
    #expect(
      valueB.0
        == .argumentIndex(
          SplitArguments.Index(inputIndex: 2, subIndex: .complete)))
    #expect(valueB.1 == "--foo")
  }

  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func popNextElementAsValueAfter_2() async throws {
    var sut = try SplitArguments(arguments: ["--bar", "bar", "--foo", "foo"])

    #expect(
      sut.popNextElementAsValue(
        after: .argumentIndex(
          SplitArguments.Index(inputIndex: 3, subIndex: .complete))) == nil)
  }

  // swift-format-ignore: AlwaysUseLowerCamelCase
  @Test func popNextElementAsValueAfter_3() async throws {
    var sut = try SplitArguments(arguments: ["--bar", "-bar"])

    let optValue = sut.popNextElementAsValue(
      after: .argumentIndex(
        SplitArguments.Index(inputIndex: 0, subIndex: .complete)
      )
    )
    let value = try #require(optValue)
    #expect(
      value.0
        == .argumentIndex(
          SplitArguments.Index(inputIndex: 1, subIndex: .complete)))
    #expect(value.1 == "-bar")
  }

  @Test func popNextElementIfValue() async throws {
    var sut = try SplitArguments(arguments: ["--bar", "bar", "--foo", "foo"])

    let popedValue = sut.popNext()
    _ = try #require(popedValue)

    let optValue2 = sut.popNextElementIfValue()
    let value = try #require(optValue2)
    #expect(
      value.0
        == .argumentIndex(
          SplitArguments.Index(inputIndex: 1, subIndex: .complete)))
    #expect(value.1 == "bar")

    #expect(sut.popNextElementIfValue() == nil)
  }

  @Test func popNextValue() async throws {
    var sut = try SplitArguments(arguments: ["--bar", "bar", "--foo", "foo"])

    let optValueA = sut.popNextValue()
    let valueA = try #require(optValueA)
    #expect(
      valueA.0 == SplitArguments.Index(inputIndex: 1, subIndex: .complete))
    #expect(valueA.1 == "bar")

    let optValueB = sut.popNextValue()
    let valueB = try #require(optValueB)
    #expect(
      valueB.0 == SplitArguments.Index(inputIndex: 3, subIndex: .complete))
    #expect(valueB.1 == "foo")

    #expect(sut.popNextElementIfValue() == nil)
  }

  @Test func peekNextValue() async throws {
    let sut = try SplitArguments(arguments: ["--bar", "bar", "--foo", "foo"])

    let optValueA = sut.peekNextValue()
    let valueA = try #require(optValueA)
    #expect(
      valueA.0 == SplitArguments.Index(inputIndex: 1, subIndex: .complete)
    )
    #expect(valueA.1 == "bar")

    let optValueB = sut.peekNextValue()
    let valueB = try #require(optValueB)
    #expect(
      valueB.0 == SplitArguments.Index(inputIndex: 1, subIndex: .complete)
    )
    #expect(valueB.1 == "bar")
  }
}

extension SplitArguments {
  init(arguments: [String]) throws {
    try self.init(arguments: arguments, responseFilePrefix: "@")
  }
}
