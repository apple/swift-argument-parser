add_library(ArgumentParserTestHelpers
  StringHelpers.swift
  TestHelpers.swift)
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
