cmake_minimum_required(VERSION 3.10)

# Set the project name
project(as-pinctl)

add_subdirectory(pinlib)
# add_subdirectory(arm)

# Specify the C standard
set (CMAKE_CXX_STANDARD 17)

# Find the libftdi1 library
find_package(PkgConfig REQUIRED)
pkg_check_modules(LIBFTDI1 REQUIRED libftdi1)

# Include the libftdi1 headers
include_directories(pinlib ${CMAKE_BINARY_DIR}/include ${LIBFTDI1_INCLUDE_DIRS})

# Add the executable
add_executable(as-pinctl pinctl.cc)

add_dependencies(as-pinctl pinlib)

# GFlags
find_package(gflags REQUIRED)

# Link the libftdi1 library
target_link_libraries(as-pinctl pinlib ${LIBFTDI1_LIBRARIES} ${GFLAGS_LIBRARIES})

# Install target
install(TARGETS as-pinctl DESTINATION bin)

# CPack configuration for .deb package
set(CPACK_GENERATOR "DEB")
set(CPACK_PACKAGE_NAME "as-pinctl")
set(CPACK_DEBIAN_PACKAGE_MAINTAINER "Ross Newman") # Replace with your name/email
set(CPACK_PACKAGE_VERSION ${BSP_VERSION})
set(CPACK_PACKAGE_DESCRIPTION "Pin control utility for Astute Systems boards")
set(CPACK_PACKAGE_CONTACT "ross.newman@astutesys.com") # Replace with your contact
set(CPACK_DEBIAN_PACKAGE_DEPENDS "libftdi1, libgflags-dev")

include(CPack)