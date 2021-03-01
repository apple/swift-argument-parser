//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

struct ForEach<C>: MDocComponent where C: Collection {
  var items: C
  var builder: (C.Element, Bool) -> MDocComponent

  init(_ items: C, @MDocBuilder builder: @escaping (C.Element, Bool) -> MDocComponent) {
    self.items = items
    self.builder = builder
  }

  var body: MDocComponent {
    guard !items.isEmpty else { return Empty() }
    var currentIndex = items.startIndex
    var last = false
    var components = [MDocComponent]()
    repeat {
      let item = items[currentIndex]
      currentIndex = items.index(after: currentIndex)
      last = currentIndex == items.endIndex
      components.append(builder(item, last))
    } while !last
    return Container(children: components)
  }
}
