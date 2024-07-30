//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import XCTest
import ArgumentParserTestHelpers
@testable import ArgumentParser

extension HelpGenerationTests {
  enum Fruit: String, ExpressibleByArgument, CaseIterable {
    case apple, banana, coconut, dragonFruit = "dragon-fruit", elderberry, fig, grape, honeydew
  }
  
  enum Action: String, ExpressibleByArgument, CaseIterable {
    case purchase, sample, refund = "return"
  }
  
  enum Count: Int, ExpressibleByArgument, CaseIterable {
    case zero, one, two, three, four, five, six, seven, eight, nine, ten, eleven, twelve, thirteen, fourteen, fifteen, sixteen, seventeen, eighteen, nineteen, twenty
  }
  
  enum Ripeness: String, ExpressibleByArgument, CaseIterable {
    case under, perfect, over
  }

  struct FruitStore: ParsableArguments {
    @Argument(help: "The transaction type")
    var action: Action = .purchase

    @Argument(help: "The fruit to purchase")
    var fruit: Fruit
      
    @Option(help: "The number of fruit to purchase")
    var quantity: Count = .one

    @Option(help: "The desired ripeness of fruit")
    var ripeness: Ripeness = .perfect
  }
  
  func testFruitStoreHelp() {
    AssertHelp(.default, for: FruitStore.self, equals: """
            USAGE: fruit_store [<action>] <fruit> [--quantity <quantity>] [--ripeness <under|perfect|over>]

            ARGUMENTS:
              <action>                The transaction type (values: purchase, sample,
                                      return; default: purchase)
              <fruit>                 The fruit to purchase (values: apple, banana,
                                      coconut, dragon-fruit, elderberry, fig, grape,
                                      honeydew)
            
            OPTIONS:
              --quantity <quantity>   The number of fruit to purchase (values: 0, 1, 2, 3,
                                      4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18,
                                      19, 20; default: 1)
              --ripeness <ripeness>   The desired ripeness of fruit (values: under,
                                      perfect, over; default: perfect)
              -h, --help              Show help information.
            
            """)
  }
}
