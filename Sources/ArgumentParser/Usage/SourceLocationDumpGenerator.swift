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

/// Output format for the `--experimental-dump-arguments-source-location` option.
///
/// Text is the default when the option is provided without a value
/// (i.e., the `defaultAsFlag` mode).
enum SourceLocationDumpFormat: String {
  case text
  case json
}

/// Renders the parsed-argument tree with each value's source location.
///
/// Walks the command stack from root to leaf, listing each argument
/// definition together with its parsed value and origin. Argv-origin
/// arguments report their argv index; response-file-origin arguments
/// report the full include chain (innermost file first, outermost argv
/// last).
struct SourceLocationDumpGenerator {
  var commandStack: [ParsableCommand.Type]
  var decodedArguments: [DecodedArguments]
  var formattingContext: InputOrigin.FormattingContext
  var format: SourceLocationDumpFormat

  func rendered() -> String {
    guard let root = buildCommandNode(stack: commandStack[...]) else {
      return ""
    }
    switch format {
    case .text: return renderText(root: root)
    case .json: return renderJSON(root: root)
    }
  }
}

// MARK: - Model (also the JSON schema via Codable)

extension SourceLocationDumpGenerator {
  /// A single value parsed for one argument.
  ///
  /// The struct's field names double as the JSON schema — no separate
  /// translation layer. Access is internal so consumers (including test
  /// code) can decode the emitted JSON back into these typed values.
  struct ValueEntry: Codable {
    let value: String
    let source: InputOrigin.Element

    /// Whether this entry represents the property's default (nothing was bound from the command line).
    ///
    /// Derived from `source` — not encoded.
    var isDefault: Bool {
      if case .defaultValue = source { return true }
      return false
    }

    private enum CodingKeys: String, CodingKey { case value, source }
  }

  /// One argument (option/flag/positional) with all of its parsed values.
  struct ArgumentEntry: Codable {
    let name: String
    let values: [ValueEntry]
  }

  /// One command-level node in the tree.
  ///
  /// Encoded shape: `{"command": ..., "arguments": [...], "subcommand": {...}?}`.
  struct CommandNode: Codable {
    let command: String
    let arguments: [ArgumentEntry]
    let subcommand: Indirect<CommandNode>?
  }

  /// Reference-typed single-value box that lets `CommandNode` recurse (a struct can't hold a stored property that transitively contains itself).
  ///
  /// Encodes as the wrapped value directly.
  final class Indirect<Wrapped: Codable>: Codable {
    let value: Wrapped
    init(_ value: Wrapped) { self.value = value }

    func encode(to encoder: Encoder) throws {
      var c = encoder.singleValueContainer()
      try c.encode(value)
    }

    required init(from decoder: Decoder) throws {
      let c = try decoder.singleValueContainer()
      self.value = try c.decode(Wrapped.self)
    }
  }
}

// MARK: - Build

extension SourceLocationDumpGenerator {
  /// Walks the command stack tail-first and builds a nested `CommandNode` tree.
  ///
  /// Returns `nil` when the stack is empty.
  fileprivate func buildCommandNode(
    stack: ArraySlice<ParsableCommand.Type>
  ) -> CommandNode? {
    guard let type = stack.first else { return nil }
    let decoded = decodedArguments.first(where: { $0.type == type })
    let parsedValues = decoded?.parsedValues
    let argSet = ArgumentSet(type, visibility: .default, parent: nil)

    var args: [ArgumentEntry] = []
    var seenKeys: Set<InputKey> = []
    for def in argSet {
      let key = def.help.keys.first ?? def.help.keys[0]
      if seenKeys.contains(key) { continue }
      seenKeys.insert(key)

      // Prefer the long-form name for display so the dump is readable
      // even when the property declares `[.short, .long]` (where
      // `.short` sorts first). Fall back to whatever we have.
      let displayName: String
      let longName = def.names.first {
        switch $0 {
        case .long, .longWithSingleDash: return true
        case .short: return false
        }
      }
      if let chosen = longName ?? def.names.first {
        displayName = chosen.synopsisString
      } else {
        displayName = "<\(def.valueName)>"
      }

      let element = parsedValues?.element(forKey: key)
      let values = renderedValues(for: element, defaultFromHelp: def)
      args.append(.init(name: displayName, values: values))
    }

    let subcommand = buildCommandNode(stack: stack.dropFirst()).map {
      Indirect($0)
    }
    return CommandNode(
      command: type._commandName,
      arguments: args,
      subcommand: subcommand)
  }

  /// Renders the value(s) for one argument key.
  ///
  /// Splits arrays into one entry per element so each gets its own source.
  fileprivate func renderedValues(
    for element: ParsedValues.Element?,
    defaultFromHelp def: ArgumentDefinition
  ) -> [ValueEntry] {
    guard let element = element, let raw = element.value else {
      return [
        .init(
          value: def.help.defaultValue.map(formatRaw) ?? "nil",
          source: .defaultValue)
      ]
    }

    let origins = element.inputOrigin.elements.filter {
      if case .argumentIndex = $0 { return true }
      return false
    }

    // If nothing was parsed from argv, treat this as a default. Covers
    // both scalars whose element was populated only from the property's
    // default and arrays whose declared default (e.g., `[]`) fired.
    if origins.isEmpty {
      return [
        .init(
          value: def.help.defaultValue.map(formatRaw) ?? formatRaw(raw),
          source: .defaultValue)
      ]
    }

    if let array = raw as? [Any] {
      // Sort origins by argv position so we can pair them with values in
      // their input order.
      let sortedOrigins = origins.sorted()

      // Positional array (`@Argument var files: [String]`) — each value
      // has exactly one origin (its own token). One-to-one match.
      if !array.isEmpty, sortedOrigins.count == array.count {
        return zip(array, sortedOrigins).map { (v, origin) in
          .init(
            value: formatRaw(v),
            source: classifySource(origin: origin))
        }
      }

      // Repeating named option (`@Option var tags: [String]`). Origins
      // include both option-name tokens (`--tag`) and value tokens
      // (a bare value or an attached `--tag=v`). Keep only the
      // value-carrying origins so the count matches the array.
      let valueOrigins = sortedOrigins.filter(isValueCarryingOrigin)
      if !array.isEmpty, valueOrigins.count == array.count {
        return zip(array, valueOrigins).map { (v, origin) in
          .init(
            value: formatRaw(v),
            source: classifySource(origin: origin))
        }
      }

      // Fallback for shapes we don't recognize (e.g., joined `-D`-style
      // parsing where origins may not have a clean 1:1 or 2:1 mapping).
      // Attach the last (max-argv) origin to each entry rather than
      // lose information.
      return array.map { v in
        .init(
          value: formatRaw(v),
          source: sortedOrigins.last.map(classifySource(origin:))
            ?? .defaultValue)
      }
    }

    // Scalar. Use the last origin — for a `--name value` pair the input
    // origin records both tokens; the value token is at the later index.
    if let origin = origins.last {
      return [
        .init(value: formatRaw(raw), source: classifySource(origin: origin))
      ]
    }
    return [.init(value: formatRaw(raw), source: .defaultValue)]
  }

  /// Returns `true` if the argv token at this origin's position carries a value: either a bare value token, or an option-with-value like `--name=foo`.
  ///
  /// Bare option-name tokens (`--name`) return `false`.
  fileprivate func isValueCarryingOrigin(
    _ origin: InputOrigin.Element
  ) -> Bool {
    // Sub-indexed origins (unpacked short options) are always name-only.
    guard case .argumentIndex(let idx) = origin,
      case .complete = idx.subIndex,
      let token = formattingContext.rawToken(at: origin)
    else {
      return false
    }
    if token.contains("=") { return true }
    if token.hasPrefix("-") && token.count > 1 { return false }
    return true
  }

  /// Turns a raw argv origin into the `InputOrigin.Element` value that
  /// belongs in a `ValueEntry.source`.
  ///
  /// If the parser recorded a response-file include chain, the result
  /// is a nested `.responseFile(step:referencedFrom:)` linked list
  /// terminated by an `.argumentIndex` at the outermost argv position.
  /// Argv-only origins return an `.argumentIndex` whose input index is
  /// the *pre-expansion* argv index recorded on the chain — that's the
  /// position in the user-typed argv, not the internal post-expansion
  /// slot.
  fileprivate func classifySource(
    origin: InputOrigin.Element
  ) -> InputOrigin.Element {
    guard case .argumentIndex = origin,
      let chain = formattingContext.responseFileChain(for: origin)
    else {
      return origin
    }
    let hasFile = chain.contains {
      if case .file = $0 { return true } else { return false }
    }
    if hasFile {
      return foldChainIntoElement(chain)
    }
    // Argv-only chain: use the argv step so the encoded index reflects
    // the pre-expansion argv position.
    if case .argv(let idx) = chain.first {
      return .argumentIndex(
        SplitArguments.Index(
          inputIndex: SplitArguments.InputIndex(rawValue: idx)))
    }
    return origin
  }

  /// Folds a flat include-chain step array into a nested
  /// `.responseFile(step:referencedFrom:)` linked list.
  ///
  /// The last step is expected to be `.argv(_)` — it becomes the
  /// `.argumentIndex(_)` terminator.
  fileprivate func foldChainIntoElement(
    _ chain: [InputOrigin.ResponseFileStep]
  ) -> InputOrigin.Element {
    guard let last = chain.last, case .argv(let idx) = last else {
      return .defaultValue
    }
    var current: InputOrigin.Element = .argumentIndex(
      SplitArguments.Index(
        inputIndex: SplitArguments.InputIndex(rawValue: idx)))
    for step in chain.dropLast().reversed() {
      current = .responseFile(step: step, referencedFrom: current)
    }
    return current
  }

  fileprivate func formatRaw(_ value: Any) -> String {
    if let s = value as? String { return "\"\(s)\"" }
    if let b = value as? Bool { return b ? "true" : "false" }
    return String(describing: value)
  }
}

// MARK: - Text rendering

extension SourceLocationDumpGenerator {
  fileprivate func renderText(root: CommandNode) -> String {
    var lines: [String] = []
    renderTextCommand(node: root, depth: 0, into: &lines)
    return lines.joined(separator: "\n")
  }

  fileprivate func renderTextCommand(
    node: CommandNode,
    depth: Int,
    into lines: inout [String]
  ) {
    let indent = String(repeating: "    ", count: depth)
    if depth == 0 {
      lines.append(node.command)
    } else {
      lines.append("\(indent)\(node.command)  (subcommand)")
    }

    let childIndent = String(repeating: "    ", count: depth + 1)
    let hasSubcommand = node.subcommand != nil
    for (idx, arg) in node.arguments.enumerated() {
      let isLastArg = idx == node.arguments.count - 1 && !hasSubcommand
      let connector = isLastArg ? "└── " : "├── "
      let leafPrefix = childIndent + connector

      if arg.values.isEmpty {
        lines.append("\(leafPrefix)\(arg.name)")
        continue
      }
      for (vidx, value) in arg.values.enumerated() {
        let label =
          vidx == 0
          ? "\(arg.name) = \(value.value)"
          : "\(arg.name)[\(vidx)] = \(value.value)"

        if value.isDefault {
          lines.append("\(leafPrefix)\(label)   (default)")
          continue
        }

        lines.append("\(leafPrefix)\(label)")
        let metaIndent = childIndent + "      "
        // Walk the source's chain directly — the linked list carries
        // the whole ancestry.
        let steps = value.source.chainAsSteps()
        for (i, step) in steps.enumerated() {
          let prefix = i == 0 ? "at " : "included from "
          lines.append("\(metaIndent)\(prefix)\(formatStep(step))")
        }
      }
    }

    if let next = node.subcommand?.value {
      renderTextCommand(node: next, depth: depth + 1, into: &lines)
    }
  }

  fileprivate func formatStep(_ step: InputOrigin.ResponseFileStep) -> String {
    switch step {
    case .file(let path, let line): return "\(path):\(line)"
    case .argv(let index): return "argv[\(index)]"
    }
  }
}

// MARK: - JSON rendering

extension SourceLocationDumpGenerator {
  fileprivate func renderJSON(root: CommandNode) -> String {
    JSONEncoder.encode(root)
  }
}
