add_subdirectory(ArgumentParser)
if(BUILD_TESTING)
  add_subdirectory(ArgumentParserTestHelpers)
endif()

set_property(GLOBAL APPEND PROPERTY ArgumentParser_EXPORTS ArgumentParser)

 # NOTE: workaround for CMake not setting up include flags yet
 set_target_properties(ArgumentParser PROPERTIES
   INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_Swift_MODULE_DIRECTORY})