include(ExternalProject)

set(PIPER_PREFIX ${CMAKE_BINARY_DIR}/_deps/piper_ext)
set(PIPER_INSTALL_DIR ${PIPER_PREFIX}/install)
set(PIPER_SOURCE_DIR ${PIPER_PREFIX}/src/piper_ext)
set(PIPER_LIB_SOURCE_DIR ${PIPER_SOURCE_DIR}/libpiper)

set(PIPER_BUILD_DIR ${PIPER_PREFIX}/build)

ExternalProject_Add(piper_ext
    PREFIX ${PIPER_PREFIX}
    GIT_REPOSITORY https://github.com/OHF-Voice/piper1-gpl.git
    GIT_TAG main

    UPDATE_COMMAND ""
    PATCH_COMMAND  ""

    SOURCE_DIR ${PIPER_SOURCE_DIR}
    BINARY_DIR ${PIPER_BUILD_DIR}
    
    CONFIGURE_COMMAND
        ${CMAKE_COMMAND}
            -S ${PIPER_LIB_SOURCE_DIR}
            -B ${PIPER_BUILD_DIR}
            -DCMAKE_INSTALL_PREFIX=${PIPER_INSTALL_DIR}
            -DCMAKE_BUILD_TYPE=Release

    BUILD_COMMAND
        ${CMAKE_COMMAND} --build ${PIPER_BUILD_DIR} --parallel

    INSTALL_COMMAND
        ${CMAKE_COMMAND} --build ${PIPER_BUILD_DIR} --target install

    BUILD_BYPRODUCTS
        ${PIPER_INSTALL_DIR}/libpiper.so
        ${PIPER_INSTALL_DIR}/lib/libonnxruntime.so
)

file(MAKE_DIRECTORY ${PIPER_INSTALL_DIR}/include)

# libpiper
add_library(libpiper SHARED IMPORTED)

set_target_properties(libpiper PROPERTIES
    IMPORTED_LOCATION ${PIPER_INSTALL_DIR}/libpiper.so
    INTERFACE_INCLUDE_DIRECTORIES ${PIPER_INSTALL_DIR}/include
)

# ONNX Runtime library shipped by Piper (already downloaded by ExternalProject)
set(ONNXRT_LIB ${PIPER_INSTALL_DIR}/lib/libonnxruntime.so)

add_library(libpiper_onnx SHARED IMPORTED)
set_target_properties(libpiper_onnx PROPERTIES
    IMPORTED_LOCATION ${ONNXRT_LIB}
)

add_dependencies(libpiper piper_ext)
add_dependencies(libpiper_onnx piper_ext)

set(TARGET_ASSETS_DIR ${CMAKE_BINARY_DIR}/bin/espeak-ng-data)
set(PIPER_ASSETS_DIR ${PIPER_INSTALL_DIR}/espeak-ng-data)

# Copy espeak-ng-data to ${app} binary dir
add_custom_command(
    OUTPUT ${TARGET_ASSETS_DIR}
    COMMAND ${CMAKE_COMMAND} -E make_directory ${TARGET_ASSETS_DIR}
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${PIPER_ASSETS_DIR} ${TARGET_ASSETS_DIR}
    DEPENDS piper_ext
    COMMENT "Copying Piper assets to bin/"
)

add_custom_target(copy_piper_assets ALL DEPENDS ${TARGET_ASSETS_DIR})
