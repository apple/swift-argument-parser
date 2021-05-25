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

import _CRuntime
@_implementationOnly import Foundation

extension NSLock {
  func withLock<T>(_ closure: () throws -> T) rethrows -> T {
    lock()
    defer { unlock() }
    return try closure()
  }
}

let conformanceLock = NSLock()
var conformances:
  [ContextDescriptor: [ContextDescriptor: [ConformanceDescriptor]]] = [:]

@_cdecl("registerProtocolConformances")
func registerProtocolConformances(_ section: UnsafeRawPointer, size: Int) {
  // This section is a list of relative pointers.
  let stride = stride(
    from: section,
    to: section + size,
    by: MemoryLayout<Int32>.stride
  )
  
  for start in stride {
    let address = start.load(
      as: RelativeDirectPointer<_CRuntime.ConformanceDescriptor>.self
    ).address(from: start)
    let conformance = ConformanceDescriptor(pointer: address)
    
    // If we don't have a context descriptor, then the conforming type is an
    // ObjC class, and we don't care about those.
    if let descriptor = conformance.contextDescriptor {
      let module = getModuleDescriptor(from: descriptor)
      
      conformanceLock.withLock {
        conformances[
          conformance.protocol,
          default: [:]
        ][
          module,
          default: []
        ].append(conformance)
      }
    }
  }
}

// Helper to walk up the context descriptor parent chain to eventually get the
// module descriptor at the top.
public func getModuleDescriptor(
  from descriptor: ContextDescriptor
) -> ContextDescriptor {
  var parent = descriptor
  
  while let newParent = parent.parent {
    parent = newParent
  }
  
  return parent
}

public func getConformances(
  for protocol: ContextDescriptor,
  in module: ContextDescriptor
) -> [ConformanceDescriptor] {
  return conformanceLock.withLock {
    guard let protoEntry = conformances[`protocol`] else {
      return []
    }
    
    guard let moduleEntry = protoEntry[module] else {
      return []
    }
    
    return moduleEntry
  }
}

//===----------------------------------------------------------------------===//
// MachO Image Inspection
//===----------------------------------------------------------------------===//

#if canImport(MachO)

import MachO

#if arch(x86_64) || arch(arm64)
typealias mach_header_platform = mach_header_64
#else
typealias mach_header_platform = mach_header
#endif

@_cdecl("lookupSection")
func lookupSection(
  _ header: UnsafePointer<mach_header>?,
  segment: UnsafePointer<CChar>?,
  section: UnsafePointer<CChar>?,
  do handler: @convention(c) (UnsafeRawPointer, Int) -> ()
) {
  guard let header = header else {
    return
  }
  
  var size: UInt = 0
  
  let section = header.withMemoryRebound(
    to: mach_header_platform.self,
    capacity: 1
  ) {
    getsectiondata($0, segment, section, &size)
  }
  
  guard section != nil else {
    return
  }
  
  handler(section!, Int(size))
}

#endif
