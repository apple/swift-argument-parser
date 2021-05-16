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
@_implementationOnly import Foundation

internal struct DumpHelpInfoGenerator {
  struct CommandInfo: Codable {
    internal init(command: DumpHelpInfoGenerator.CommandInfo.ArgumentInfo, subcommands: [DumpHelpInfoGenerator.CommandInfo]?, arguments: [DumpHelpInfoGenerator.CommandInfo.ArgumentInfo]?, options: [DumpHelpInfoGenerator.CommandInfo.ArgumentInfo]?) {
      self.command = command
      self.subcommands = subcommands
      self.arguments = arguments
      self.options = options
    }
    
    struct ArgumentInfo: Codable, Hashable {
      internal init(name: [String]? = nil, abstract: String, discussion: String, isRequired: Bool? = nil, defaultValue: String? = nil, valueName: String? = nil, isDefault: Bool? = nil) {
        self.name = name
        self.abstract = abstract
        self.discussion = discussion
        self.isRequired = isRequired
        self.defaultValue = defaultValue
        self.valueName = valueName
        self.isDefault = isDefault
      }
      
      // Only for options and commands
      var name: [String]?
      
      // Shared properties
      var abstract: String
      var discussion: String
      
      // Used only for arguments and options
      var isRequired: Bool?
      var defaultValue: String?
      var valueName: String?
      
      // Used only for subcommands
      var isDefault: Bool?
    }
    
    var command: ArgumentInfo
    var subcommands: [CommandInfo]?
    var arguments: [ArgumentInfo]?
    var options: [ArgumentInfo]?
  }
  var commandInfo: CommandInfo.ArgumentInfo
  var subcommandsInfo: [CommandInfo]?
  var argInfo: [CommandInfo.ArgumentInfo]?
  var optInfo: [CommandInfo.ArgumentInfo]?
  
  init(commandStack: [ParsableCommand.Type]) {
    var toolName = commandStack.map { $0._commandName }.joined(separator: " ")
    if let superName = commandStack.first!.configuration._superCommandName {
      toolName = "\(superName) \(toolName)"
    }
    let toolAbstract = commandStack.last!.configuration.abstract
    let toolDiscussion = commandStack.last!.configuration.discussion
    self.commandInfo = CommandInfo.ArgumentInfo(name: [toolName], abstract: toolAbstract, discussion: toolDiscussion)
    self.subcommandsInfo = DumpHelpInfoGenerator.getSubcommandNames(commandStack: commandStack)
    self.argInfo = DumpHelpInfoGenerator.getArgumentInfo(commandStack: commandStack)
    self.optInfo = DumpHelpInfoGenerator.getOptionInfo(commandStack: commandStack)
  }
  
  init(_ type: ParsableArguments.Type) {
    self.init(commandStack: [type.asCommand])
  }
  
  
  static func getSubcommandNames(commandStack: [ParsableCommand.Type]) -> [CommandInfo]? {
    let superCommand = commandStack.first!
    let defaultSubcommand = commandStack.last!.configuration.defaultSubcommand
    let subcommandsToShow = commandStack.last!.configuration.subcommands
      .filter { $0.configuration.shouldDisplay }
    
    guard !subcommandsToShow.isEmpty else { return nil }
    
    return subcommandsToShow
      .compactMap { CommandInfo(command: CommandInfo.ArgumentInfo(name: [$0._commandName], abstract: $0.configuration.abstract, discussion:$0.configuration.discussion, isDefault: $0 == defaultSubcommand),
                             subcommands: getSubcommandNames(commandStack: [superCommand, $0]),
                             arguments: getArgumentInfo(commandStack: [superCommand, $0]),
                             options: getOptionInfo(commandStack: [superCommand, $0]))
      }
  }
  
  static func getHelpInfo(commandStack: [ParsableCommand.Type], isPositional: Bool) -> [CommandInfo.ArgumentInfo] {
    guard let commandType = commandStack.last else { return [] }
    let args = Array(ArgumentSet(commandType, creatingHelp: true))
    
    var i = 0
    return args.compactMap { arg in
      defer { i += 1 }
      guard arg.help.help?.shouldDisplay != false else { return nil }
      let description: String
      
      if arg.help.isComposite {
        var groupedArgs = [arg]
        let defaultValue = arg.help.defaultValue.map { "(default: \($0))" } ?? ""
        while i < args.count - 1 && args[i + 1].help.keys == arg.help.keys {
          groupedArgs.append(args[i + 1])
          i += 1
        }
        var descriptionString: String?
        for arg in groupedArgs {
          if let desc = arg.help.help?.abstract {
            descriptionString = desc
            break
          }
        }
        description = [descriptionString, defaultValue]
          .compactMap { $0 }
          .joined(separator: " ")
      } else {
        let defaultValue = arg.help.defaultValue.flatMap { $0.isEmpty ? nil : "(default: \($0))" } ?? ""
        //synopsis = arg.synopsisForHelp ?? ""
        description = [arg.help.help?.abstract, defaultValue]
          .compactMap { $0 }
          .joined(separator: " ")
      }
      
      let name:[String]? = arg.preferredNameForSynopsis?.synopsisString.split(separator: ",").compactMap { String($0) }
      
      guard arg.isPositional == isPositional else { return nil }
      return CommandInfo.ArgumentInfo(name: name, abstract: description, discussion: arg.help.help?.discussion ?? "", isRequired: !arg.help.options.contains(.isOptional), defaultValue: arg.help.defaultValue, valueName: arg.valueName)
    }
  }
  
  static func getArgumentInfo(commandStack: [ParsableCommand.Type]) -> [CommandInfo.ArgumentInfo]? {
    var alreadySeenElements = Set<CommandInfo.ArgumentInfo>()
    let helpInfo = DumpHelpInfoGenerator.getHelpInfo(commandStack: commandStack, isPositional: true)
    
    let helpInfoArray = helpInfo
      .filter { !alreadySeenElements.contains($0) }
      .map { (info) -> CommandInfo.ArgumentInfo in
        alreadySeenElements.insert(info)
        return info
      }

    return helpInfoArray.count > 0 ? helpInfoArray : nil
  }
  
  static func getOptionInfo(commandStack: [ParsableCommand.Type]) -> [CommandInfo.ArgumentInfo]? {
    var alreadySeenElements = Set<CommandInfo.ArgumentInfo>()
    let helpInfo = DumpHelpInfoGenerator.getHelpInfo(commandStack: commandStack, isPositional: false)
    
    var helpInfoArray = helpInfo
      .filter { !alreadySeenElements.contains($0) }
      .map { (info) -> CommandInfo.ArgumentInfo in
        alreadySeenElements.insert(info)
        return info
      }

    if commandStack.contains(where: { !$0.configuration.version.isEmpty }) {
      helpInfoArray.append(CommandInfo.ArgumentInfo(name: ["--version"], abstract: "Show the version.", discussion: "",isRequired: false))
    }
    
    let helpLabels = commandStack
      .getHelpNames()
      .map { $0.synopsisString }

    if !helpLabels.isEmpty {
      helpInfoArray.append(CommandInfo.ArgumentInfo(name: helpLabels, abstract: "Show help information.", discussion: "",isRequired: false))
    }

    return helpInfoArray.count > 0 ? helpInfoArray : nil
  }

  func generateHelpInfo() -> CommandInfo {
    return CommandInfo(command: self.commandInfo, subcommands: self.subcommandsInfo, arguments:self.argInfo, options: self.optInfo)
  }
  
  func rendered() -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    
    guard let encoded = try? encoder.encode(generateHelpInfo()) else { return "" }
    return String(data: encoded, encoding: .utf8) ?? ""
  }
}
