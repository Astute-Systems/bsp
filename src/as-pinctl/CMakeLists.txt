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
# Set the package architecture for arm64 or amd64
if(CMAKE_SYSTEM_PROCESSOR STREQUAL "aarch64")   
    set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE "arm64")
else()
    set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE "amd64")
endif()

# Get the linux version from an environment variable or default to "unknown"
if(DEFINED ENV{OS_VERSION})
    set(CPACK_DEBIAN_PACKAGE_OS_RELEASE "$ENV{OS_VERSION}")
else()
    set(CPACK_DEBIAN_PACKAGE_OS_RELEASE "_Linux")
endif()

# Set the output .deb file name to include version and architecture
set(CPACK_PACKAGE_FILE_NAME "as-pinctl-${BSP_VERSION}-${CPACK_DEBIAN_PACKAGE_ARCHITECTURE}${CPACK_DEBIAN_PACKAGE_OS_RELEASE}")


include(CPack)