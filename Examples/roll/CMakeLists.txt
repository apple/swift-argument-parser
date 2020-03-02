add_executable(roll
  main.swift
  SplitMix64.swift)
target_link_libraries(roll PRIVATE
  ArgumentParser)
