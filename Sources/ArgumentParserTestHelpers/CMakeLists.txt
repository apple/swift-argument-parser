add_library(ArgumentParserTestHelpers
  TestHelpers.swift
  TestHelpers+SwiftTesting.swift)
set_target_properties(ArgumentParserTestHelpers PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_Swift_MODULE_DIRECTORY})
target_link_libraries(ArgumentParserTestHelpers PUBLIC
  ArgumentParser
  ArgumentParserToolInfo)
if(Foundation_FOUND)
  target_link_libraries(ArgumentParserTestHelpers PUBLIC
    Foundation)
endif()
if(XCTest_Found)
  target_link_libraries(ArgumentParserTestHelpers PUBLIC
    XCTest)
endif()
if(Testing_FOUND)
  target_link_libraries(ArgumentParserTestHelpers PUBLIC
    Testing)
endif()
