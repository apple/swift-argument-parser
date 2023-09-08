//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import XCTest
@testable import ArgumentParser

final class SendableTests: XCTestCase {}

extension SendableTests {

  public struct MyExpressibleType: ExpressibleByArgument {
    public init?(argument: String) {
    }
  }

  public final class MySendableClassType: Sendable {
    init(_: String) {
    }
  }

    private static func transformFactory(_ value: @autoclosure () -> NonSendableType) -> (String) -> MySendableClassType {
        return { MySendableClassType($0) }
    }

    public final class NonSendableType {
    init() {
    }
    }

  struct Foo: ParsableArguments, Sendable {
    @Flag()
    var foo: Bool = false

    @Option()
    var custom: MyExpressibleType?

    @Option(transform: { MySendableClassType($0) })
    var transformed1: MySendableClassType

    @Option(transform: transformFactory(NonSendableType()))
    var transformed2: MySendableClassType

    @Argument()
    var arg: [MyExpressibleType]

  }

  struct Bar: ParsableCommand, Sendable {
    @OptionGroup
    var foo: Foo
  }

  struct Baz: AsyncParsableCommand, Sendable {
    @OptionGroup
    var bar: Foo
  }

}

