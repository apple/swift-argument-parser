cmake_minimum_required(VERSION 3.19)

# Due to a bug in CMake, we need to enable the C language before we can use
# GNUInstallDirs.
project(swift-argument-parser
  LANGUAGES C Swift)

option(BUILD_EXAMPLES "Build Example Programs" TRUE)
option(BUILD_SHARED_LIBS "Build shared libraries by default" YES)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules)

include(CTest)

include(GNUInstallDirs)
include(SwiftSupport)

find_package(dispatch CONFIG)
find_package(Foundation CONFIG)
find_package(XCTest CONFIG)

add_subdirectory(Sources)
if(BUILD_EXAMPLES)
  add_subdirectory(Examples)
endif()
if(BUILD_TESTING)
  add_subdirectory(Tests)
endif()

add_subdirectory(cmake/modules)
