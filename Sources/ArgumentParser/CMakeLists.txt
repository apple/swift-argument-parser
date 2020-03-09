add_library(ArgumentParser
  "Parsable Properties/Argument.swift"
  "Parsable Properties/ArgumentHelp.swift"
  "Parsable Properties/Errors.swift"
  "Parsable Properties/Flag.swift"
  "Parsable Properties/NameSpecification.swift"
  "Parsable Properties/Option.swift"
  "Parsable Properties/OptionGroup.swift"

  "Parsable Types/CommandConfiguration.swift"
  "Parsable Types/ExpressibleByArgument.swift"
  "Parsable Types/ParsableArguments.swift"
  "Parsable Types/ParsableCommand.swift"

  Parsing/ArgumentDecoder.swift
  Parsing/ArgumentDefinition.swift
  Parsing/ArgumentSet.swift
  Parsing/ArgumentSetSequence.swift
  Parsing/CommandParser.swift
  Parsing/InputOrigin.swift
  Parsing/Name.swift
  Parsing/Parsed.swift
  Parsing/ParsedValues.swift
  Parsing/ParserError.swift
  Parsing/SplitArguments.swift

  Usage/HelpCommand.swift
  Usage/HelpGenerator.swift
  Usage/MessageInfo.swift
  Usage/UsageGenerator.swift

  Utilities/StringExtensions.swift
  Utilities/Tree.swift)
set_target_properties(ArgumentParser PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_Swift_MODULE_DIRECTORY})
target_compile_options(ArgumentParser PRIVATE
  $<$<BOOL:${BUILD_TESTING}>:-enable-testing>)
target_link_libraries(ArgumentParser PRIVATE
  $<$<NOT:$<PLATFORM_ID:Darwin>>:Foundation>)
