# Cretate a target and run the Dockerfile in a shell

project(dockerfile)

add_custom_target(dockerfile
    COMMAND cp ${CMAKE_BINARY_DIR}/*.deb ${CMAKE_CURRENT_SOURCE_DIR}/.
    COMMAND docker build -t dockerfile . --build-arg build_dir=${CMAKE_BINARY_DIR} --build-arg current_dir=${CMAKE_CURRENT_SOURCE_DIR}
    COMMAND docker run -p 5900:5900 --net=host -it --rm dockerfile 
    COMMAND rm -rf ${CMAKE_CURRENT_SOURCE_DIR}/*.deb    
    EXCLUDE_FROM_ALL
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)