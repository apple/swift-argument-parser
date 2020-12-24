add_library(UnitTests
  ParsableArgumentsValidationTests.swift
  ErrorMessageTests.swift
  HelpGenerationTests.swift
  LocalizationTests.swift
  NameSpecificationTests.swift
  SplitArgumentTests.swift
  StringSnakeCaseTests.swift
  StringWrappingTests.swift
  TreeTests.swift
  UsageGenerationTests.swift)
add_subdirectory(Resources/en.lproj)
add_subdirectory(Resources/tr.lproj)
target_link_libraries(UnitTests PRIVATE
  ArgumentParser
  ArgumentParserTestHelpers)
