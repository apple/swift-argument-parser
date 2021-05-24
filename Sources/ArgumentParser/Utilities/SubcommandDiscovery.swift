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

import _Runtime
@_implementationOnly import Foundation

let subcommandLock = NSLock()
var discoveredSubcommands: [UnsafeRawPointer: [ParsableCommand.Type]] = [:]

// Use runtime metadata information to find nested subcommands automatically.
// When getting the subcommands for a ParsableCommand, we look at all types who
// conform to ParsableCommand within the same module. If we find one who
// is nested in the base command that we're looking at now, we add it as a
// subcommand.
//
//      struct Base: ParsableCommand {}
//
//      extension Base {
//        // This is considered an automatic subcommand!
//        struct Sub: ParsableCommand {}
//      }
//
func discoverSubcommands(for type: Any.Type) -> [ParsableCommand.Type] {
  // Make sure that only classes, structs, and enums are checked for.
  guard let selfMetadata = metadata(for: type),
        selfMetadata.kind != .existential else {
    return []
  }
  
  subcommandLock.lock()
  
  defer {
    subcommandLock.unlock()
  }
  
  guard !discoveredSubcommands.keys.contains(selfMetadata.pointer) else {
    return discoveredSubcommands[selfMetadata.pointer].unsafelyUnwrapped
  }
  
  let module = getModuleDescriptor(from: selfMetadata.descriptor)
  
  let parsableCommand: ContextDescriptor
  
  // If the swift_getExistentialTypeConstraints function is available, use that.
  // Otherwise, fallback to using an earlier existential metadata layout.
  if #available(macOS 9999, iOS 9999, watchOS 9999, tvOS 9999, *) {
    // FIXME: Implement this function
    fatalError("swift_getExistentialTypeConstraints not implemented")
  } else {
    let parsableCommandMetadata = metadata(
      for: ParsableCommand.self
    ) as! ExistentialMetadata
    
    parsableCommand = parsableCommandMetadata.protocols[0]
  }
  
  // Grab all of the conformances to ParsableCommand in the same module that
  // this ParsableCommand was defined in.
  let conformances = _Runtime.getConformances(for: parsableCommand, in: module)
  
  // FIXME: Maybe we want to reserve some initial space here?
  var subcommands: [ParsableCommand.Type] = []
  
  for conformance in conformances {
    // If we don't have a context descriptor, then an ObjC class somehow
    // conformed to a Swift protocol (not sure that's possible).
    guard let descriptor = conformance.contextDescriptor else {
      continue
    }
    
    // This is okay because modules can't conform to protocols, so the type
    // being referenced here is at least a child deep in the declaration context
    // tree.
    let parent = descriptor.parent.unsafelyUnwrapped
    
    // We're only interested in conformances where the parent is ourselves
    // (the parent ParsableCommand).
    guard parent == selfMetadata.descriptor else {
      continue
    }
    
    // If a subcommand is generic, we can't add it as a default because we have
    // no idea what type substitution they want for the generic parameter.
    guard !descriptor.flags.isGeneric else {
      continue
    }
    
    // We found a subcommand! Use the access function to get the metadata for
    // it and add it to the list!
    let subcommand = descriptor.accessor() as! ParsableCommand.Type
    subcommands.append(subcommand)
  }
  
  // Remember to cache the results!
  discoveredSubcommands[selfMetadata.pointer] = subcommands
  
  return subcommands
}
