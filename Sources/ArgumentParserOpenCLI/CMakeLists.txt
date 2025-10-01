add_library(ArgumentParserOpenCLI
  OpenCLIv0_1.swift)
# NOTE: workaround for CMake not setting up include flags yet
set_target_properties(ArgumentParserOpenCLI PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_Swift_MODULE_DIRECTORY})
target_compile_options(ArgumentParserOpenCLI PRIVATE
  $<$<BOOL:${BUILD_TESTING}>:-enable-testing>)


_install_target(ArgumentParserOpenCLI)
set_property(GLOBAL APPEND PROPERTY ArgumentParser_EXPORTS ArgumentParserOpenCLI)