cmake_minimum_required(VERSION 3.16.0)

project(swift-argument-parser
  LANGUAGES Swift)

option(BUILD_EXAMPLES "Build Example Programs" TRUE)

include(CTest)

set(CMAKE_Swift_MODULE_DIRECTORY ${CMAKE_BINARY_DIR}/swift)

find_package(Foundation QUIET)
find_package(XCTest QUIET)

add_subdirectory(Sources)
if(BUILD_EXAMPLES)
  add_subdirectory(Examples)
endif()
if(BUILD_TESTING)
  add_subdirectory(Tests)
endif()

export(TARGETS ArgumentParser
  FILE swift-argument-parser-config.cmake)
