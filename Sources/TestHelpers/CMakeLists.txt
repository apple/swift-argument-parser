add_library(TestHelpers
  StringHelpers.swift
  TestHelpers.swift)
set_target_properties(TestHelpers PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_Swift_MODULE_DIRECTORY})
target_link_libraries(TestHelpers PUBLIC
  ArgumentParser
  XCTest)
