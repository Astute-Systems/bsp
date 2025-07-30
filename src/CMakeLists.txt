
add_subdirectory(as-pinctl)

# store the githash in a variable0
execute_process(
    COMMAND git rev-parse HEAD
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    OUTPUT_VARIABLE GIT_HASH
    OUTPUT_STRIP_TRAILING_WHITESPACE
)

execute_process(
    COMMAND git rev-parse --short HEAD
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    OUTPUT_VARIABLE GIT_HASH_SHORT
    OUTPUT_STRIP_TRAILING_WHITESPACE
)

# Store todays date in a variable
execute_process(
    COMMAND date 
    OUTPUT_VARIABLE BUILD_DATE
    OUTPUT_STRIP_TRAILING_WHITESPACE
)

message(STATUS "Git Hash ${GIT_HASH}")

# Create a header file in the build dir with the git hash and date
file(WRITE ${CMAKE_BINARY_DIR}/include/info.h "#define GIT_HASH \"#${GIT_HASH}\"\n")
file(APPEND ${CMAKE_BINARY_DIR}/include/info.h "#define GIT_HASH_SHORT \"#${GIT_HASH_SHORT}\"\n")
file(APPEND ${CMAKE_BINARY_DIR}/include/info.h "#define BUILD_DATE \"${BUILD_DATE}\"\n")
