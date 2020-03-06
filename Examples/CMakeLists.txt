add_executable(math
  math/main.swift)
target_link_libraries(math PRIVATE
  ArgumentParser)

add_executable(repeat
  repeat/main.swift)
target_link_libraries(repeat PRIVATE
  ArgumentParser)

add_executable(roll
  roll/main.swift
  roll/SplitMix64.swift)
target_link_libraries(roll PRIVATE
  ArgumentParser)
