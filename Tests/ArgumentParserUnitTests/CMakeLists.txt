add_library(UnitTests
  ErrorMessageTests.swift
  HelpGenerationTests.swift
  NameSpecificationTests.swift
  SplitArgumentTests.swift
  StringWrappingTests.swift
  TreeTests.swift
  UsageGenerationTests.swift)
target_link_libraries(UnitTests PRIVATE
  ArgumentParser
  ArgumentParserTestHelpers)
