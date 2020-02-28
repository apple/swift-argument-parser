//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift Argument Parser open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

internal struct HelpGenerator {
  static var helpIndent = 2
  static var labelColumnWidth = 26
  static var screenWidth: Int {
    _screenWidthOverride ?? _terminalWidth()
  }
  
  internal static var _screenWidthOverride: Int? = nil
  
  struct Usage {
    public var components: [String]
    
    public init(components: [String]) {
      self.components = components
    }
    
    var rendered: String {
      components
        .joined(separator: "\n")
    }
  }
  
  struct Section {
    struct Element {
      public var label: String
      public var abstract: String
      public var discussion: String
      
      public init(label: String, abstract: String = "", discussion: String = "") {
        self.label = label
        self.abstract = abstract
        self.discussion = discussion
      }
      
      var paddedLabel: String {
        String(repeating: " ", count: HelpGenerator.helpIndent) + label
      }
      
      var rendered: String {
        let paddedLabel = self.paddedLabel
        let wrappedAbstract = self.abstract
          .wrapped(to: HelpGenerator.screenWidth, wrappingIndent: HelpGenerator.labelColumnWidth)
        let wrappedDiscussion = self.discussion.isEmpty
          ? ""
          : self.discussion.wrapped(to: HelpGenerator.screenWidth, wrappingIndent: HelpGenerator.helpIndent * 4) + "\n"
        
        if paddedLabel.count < HelpGenerator.labelColumnWidth {
          return paddedLabel
            + wrappedAbstract.dropFirst(paddedLabel.count) + "\n"
            + wrappedDiscussion
        } else {
          return paddedLabel + "\n"
            + wrappedAbstract + "\n"
            + wrappedDiscussion
        }
      }
    }
    
    enum Header: CustomStringConvertible, Equatable {
      case positionalArguments
      case subcommands
      case options
      
      var description: String {
        switch self {
        case .positionalArguments:
          return "Arguments"
        case .subcommands:
          return "Subcommands"
        case .options:
          return "Options"
        }
      }
    }
    
    var header: Header
    var elements: [Element]
    var discussion: String
    var isSubcommands: Bool
    
    init(header: Header, elements: [Element], discussion: String = "", isSubcommands: Bool = false) {
      self.header = header
      self.elements = elements
      self.discussion = discussion
      self.isSubcommands = isSubcommands
    }
    
    var rendered: String {
      guard !elements.isEmpty else { return "" }
      
      let renderedElements = elements.map { $0.rendered }.joined()
      return "\(String(describing: header).uppercased()):\n"
        + renderedElements
    }
  }
  
  struct DiscussionSection {
    var title: String
    var content: String
    
    init(title: String = "", content: String) {
      self.title = title
      self.content = content
    }
  }
  
  var abstract: String
  var usage: Usage
  var sections: [Section]
  var discussionSections: [DiscussionSection]
  
  init(commandStack: [ParsableCommand.Type]) {
    guard let currentCommand = commandStack.last else {
      fatalError()
    }
    
    let currentArgSet = ArgumentSet(currentCommand)
    
    let toolName = commandStack.map { $0._commandName }.joined(separator: " ")
    var usageString = UsageGenerator(toolName: toolName, definition: [currentArgSet]).synopsis
    if !currentCommand.configuration.subcommands.isEmpty {
      if usageString.last != " " { usageString += " " }
      usageString += "<subcommand>"
    }
    
    self.abstract = currentCommand.configuration.abstract
    if !currentCommand.configuration.discussion.isEmpty {
      self.abstract += "\n\n\(currentCommand.configuration.discussion)"
    }
    
    self.usage = Usage(components: [usageString])
    self.sections = HelpGenerator.generateSections(commandStack: commandStack)
    self.discussionSections = []
  }
  
  static func generateSections(commandStack: [ParsableCommand.Type]) -> [Section] {
    var positionalElements: [Section.Element] = []
    var optionElements: [Section.Element] = []
    
    for commandType in commandStack {
      let args = Array(ArgumentSet(commandType))
      
      var i = 0
      while i < args.count {
        defer { i += 1 }
        let arg = args[i]
        
        guard arg.help.help?.shouldDisplay != false else { continue }
        
        let synopsis: String
        let description: String
        
        if i < args.count - 1 && args[i + 1].help.keys == arg.help.keys {
          // If the next argument has the same keys as this one, output them together
          let nextArg = args[i + 1]
          let defaultValue = arg.help.defaultValue.map { "(default: \($0))" } ?? ""
          synopsis = "\(arg.synopsisForHelp ?? "")/\(nextArg.synopsisForHelp ?? "")"
          description = [arg.help.help?.abstract ?? nextArg.help.help?.abstract ?? "", defaultValue].joined(separator: " ")
          i += 1
          
        } else {
          let defaultValue = arg.help.defaultValue.flatMap {
            return $0 == "true" || $0 == "false"
              ? nil
              : "(default: \($0))"
            } ?? ""
          synopsis = arg.synopsisForHelp ?? ""
          description = [arg.help.help?.abstract ?? "", defaultValue].joined(separator: " ")
        }
        
        let element = Section.Element(label: synopsis, abstract: description, discussion: arg.help.help?.discussion ?? "")
        if case .positional = arg.kind {
          positionalElements.append(element)
        } else {
          optionElements.append(element)
        }
      }
    }
    
    let helpLabels = commandStack
      .first!
      .getHelpNames()
      .map { $0.synopsisString }
      .joined(separator: ", ")
    if !helpLabels.isEmpty {
      optionElements.append(.init(label: helpLabels, abstract: "Show help information."))
    }
    
    let subcommandElements: [Section.Element] =
      commandStack.last!.configuration.subcommands.compactMap { command in
        guard command.configuration.shouldDisplay else { return nil }
        return Section.Element(
          label: command._commandName,
          abstract: command.configuration.abstract)
    }
    
    return [
      Section(header: .positionalArguments, elements: positionalElements),
      Section(header: .options, elements: optionElements),
      Section(header: .subcommands, elements: subcommandElements),
    ]
  }
  
  var usageMessage: String {
    "Usage: \(usage.rendered)"
  }
  
  var rendered: String {
    let renderedSections = sections
      .map { $0.rendered }
      .filter { !$0.isEmpty }
      .joined(separator: "\n")
    let renderedAbstract = abstract.isEmpty
      ? ""
      : "OVERVIEW: \(abstract)".wrapped(to: HelpGenerator.screenWidth) + "\n\n"
    
    return """
    \(renderedAbstract)\
    USAGE: \(usage.rendered)
    
    \(renderedSections)
    """
  }
}

internal extension ParsableCommand {
  static func getHelpNames() -> [Name] {
    return self.configuration
      .helpNames
      .makeNames(InputKey(rawValue: "help"))
      .sorted(by: >)
  }
}

#if canImport(Glibc)
import Glibc
func ioctl(_ a: Int32, _ b: Int32, _ p: UnsafeMutableRawPointer) -> Int32 {
  ioctl(CInt(a), UInt(b), p)
}
#else
import Darwin
#endif

func _terminalWidth() -> Int {
  var w = winsize()
  let err = ioctl(STDOUT_FILENO, TIOCGWINSZ, &w)
  let result = Int(w.ws_col)
  return err == 0 && result > 0 ? result : 80
}

func _terminalHeight() -> Int {
  var w = winsize()
  let err = ioctl(STDOUT_FILENO, TIOCGWINSZ, &w)
  let result = Int(w.ws_row)
  return err == 0 && result > 0 ? result : 25
}
