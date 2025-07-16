
file(STRINGS ${CMAKE_CURRENT_SOURCE_DIR}/version VERSION_CONTENTS)
list(GET VERSION_CONTENTS 0 BSP_MAJOR_VERSION)
list(GET VERSION_CONTENTS 1 BSP_MINOR_VERSION)
list(GET VERSION_CONTENTS 2 BSP_PATCH_VERSION)
list(GET VERSION_CONTENTS 3 BSP_SUFFIX)
set(BSP_SEM_VERSION ${BSP_MAJOR_VERSION}.${BSP_MINOR_VERSION}.${BSP_PATCH_VERSION})
set(BSP_VERSION ${BSP_MAJOR_VERSION}.${BSP_MINOR_VERSION}.${BSP_PATCH_VERSION}${BSP_SUFFIX})

execute_process(COMMAND git rev-parse --short HEAD OUTPUT_VARIABLE GIT_HASH OUTPUT_STRIP_TRAILING_WHITESPACE WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
execute_process(COMMAND pwd WORKING_DIRECTORY ${CMAKE_SOURCE_DIR} OUTPUT_VARIABLE TEST_DIR OUTPUT_STRIP_TRAILING_WHITESPACE)
message(STATUS TEST_DIR ${TEST_DIR})

# If githash is empty then put in dummy value
if ("${GIT_HASH}" STREQUAL "")
    message(WARNING "Could not determine git hash")
    set(GIT_HASH "unknown")
endif()

message(STATUS "Version (${PROJECT_NAME}): ${BSP_VERSION}")

# Update documentation, sed repalce %version% with the current version
file(READ ${CMAKE_CURRENT_SOURCE_DIR}/src/gui/resource/index.html.template INDEX_CONTENTS)
string(REPLACE "%version%" ${BSP_VERSION} INDEX_CONTENTS ${INDEX_CONTENTS})
string(REPLACE "%githash%" ${GIT_HASH} INDEX_CONTENTS ${INDEX_CONTENTS})
file(WRITE ${CMAKE_CURRENT_SOURCE_DIR}/src/gui/resource/index.html ${INDEX_CONTENTS})

set(VERSION_FILE ${CMAKE_CURRENT_BINARY_DIR}/include/version.h)
file(WRITE ${VERSION_FILE} "// This file it automatically generated, no not edit manually\n")
file(APPEND ${VERSION_FILE} "#include <string>\n")
file(APPEND ${VERSION_FILE} "#include <cstdint>\n")
file(APPEND ${VERSION_FILE} "const uint32_t kMajor = ${BSP_MAJOR_VERSION};\n")
file(APPEND ${VERSION_FILE} "const uint32_t kMinor = ${BSP_MINOR_VERSION};\n")
file(APPEND ${VERSION_FILE} "const uint32_t kPatch = ${BSP_PATCH_VERSION};\n")
file(APPEND ${VERSION_FILE} "const std::string kSuffix = \"${BSP_SUFFIX}\";\n")
file(APPEND ${VERSION_FILE} "const std::string kVersion = \"${BSP_VERSION}\";\n")
file(APPEND ${VERSION_FILE} "const std::string kGitHash = \"${GIT_HASH}\";\n")


