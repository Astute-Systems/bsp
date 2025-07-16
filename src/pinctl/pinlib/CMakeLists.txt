cmake_minimum_required(VERSION 3.10)

# Set the project name
project(pinlib)

# Specify the C standard
set (CMAKE_CXX_STANDARD 17)

# Add the executable
add_library(pinlib pinlib.cc)

# Find the libftdi1 library
find_package(PkgConfig REQUIRED)
pkg_check_modules(LIBFTDI1 REQUIRED libftdi1)

# Include the libftdi1 headers
include_directories(${LIBFTDI1_INCLUDE_DIRS})

# Link the libftdi1 library
target_link_libraries(pinlib ${LIBFTDI1_LIBRARIES} ${GFLAGS_LIBRARIES})
target_include_directories(pinlib PUBLIC INTERFACE ${GFLAGS_LIBRARIES})

