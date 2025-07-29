cmake_minimum_required(VERSION 3.19)

## Language
enable_language(CXX)

## Gnu locations
include(GNUInstallDirs)

project(SystemX LANGUAGES CXX)

include(scripts/cmake/version.cmake)
include(scripts/cmake/doxygen.cmake)
include(scripts/cmake/cpp.cmake)
include(scripts/cmake/githooks.cmake)
# include(scripts/cmake/cpack.cmake)

add_subdirectory(scripts)
add_subdirectory(src)

# Uninstall target
if(NOT TARGET uninstall)
  configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/scripts/cmake/uninstall.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake"
    IMMEDIATE @ONLY)

  add_custom_target(uninstall
    COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake)
endif()

