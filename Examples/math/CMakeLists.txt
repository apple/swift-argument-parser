add_executable(math
  main.swift)
target_link_libraries(math PRIVATE
  ArgumentParser
  $<$<STREQUAL:${CMAKE_SYSTEM_NAME},Linux>:m>)
