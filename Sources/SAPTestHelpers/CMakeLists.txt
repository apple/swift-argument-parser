add_library(SAPTestHelpers
  StringHelpers.swift
  TestHelpers.swift)
set_target_properties(SAPTestHelpers PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_Swift_MODULE_DIRECTORY})
target_link_libraries(SAPTestHelpers PUBLIC
  ArgumentParser
  XCTest)
