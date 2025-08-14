add_library(ArgumentParserToolInfo STATIC
  ToolInfo.swift)
target_compile_options(ArgumentParserToolInfo PRIVATE
  $<$<BOOL:${BUILD_TESTING}>:-enable-testing>)


set_property(GLOBAL APPEND PROPERTY ArgumentParser_EXPORTS ArgumentParserToolInfo)
