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

protocol PointerView {
  associatedtype View

  var pointer: UnsafeRawPointer { get }
}

extension PointerView {
  var view: View {
    pointer.load(as: View.self)
  }

  var trailing: UnsafeRawPointer {
    pointer + MemoryLayout<View>.size
  }
}
