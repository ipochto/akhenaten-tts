include(ExternalProject)

if(WIN32)
    set(PIPER_LIB_NAME piper.dll)
    set(PIPER_IMPLIB_NAME piper.lib)
    set(ONNX_LIB_NAME onnxruntime.dll)
    set(ONNX_IMPLIB_NAME onnxruntime.lib)
else()
    set(PIPER_LIB_NAME libpiper.so)
    set(ONNX_LIB_NAME libonnxruntime.so)
endif()

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
    PATCH_COMMAND
        ${CMAKE_COMMAND} -E echo "Patching piper for fixing Windows build" &&
        ${GIT_EXECUTABLE} apply ${CMAKE_SOURCE_DIR}/cmake/third-party/patches/piper-add-espeak-patch.patch &&
        ${GIT_EXECUTABLE} apply ${CMAKE_SOURCE_DIR}/cmake/third-party/patches/piper-wchar-fix.patch

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
        ${PIPER_INSTALL_DIR}/${PIPER_LIB_NAME}
        ${PIPER_INSTALL_DIR}/${PIPER_IMPLIB_NAME}
        ${PIPER_INSTALL_DIR}/lib/${ONNX_LIB_NAME}
        ${PIPER_INSTALL_DIR}/lib/${ONNX_IMPLIB_NAME}
)

file(MAKE_DIRECTORY ${PIPER_INSTALL_DIR}/include)

# libpiper
add_library(libpiper SHARED IMPORTED)

if(WIN32)
    set_target_properties(libpiper PROPERTIES
        IMPORTED_LOCATION   ${PIPER_INSTALL_DIR}/${PIPER_LIB_NAME}
        # Import library (.lib)
        IMPORTED_IMPLIB     ${PIPER_INSTALL_DIR}/${PIPER_IMPLIB_NAME}
        INTERFACE_INCLUDE_DIRECTORIES ${PIPER_INSTALL_DIR}/include
    )
else()
    set_target_properties(libpiper PROPERTIES
        IMPORTED_LOCATION ${PIPER_INSTALL_DIR}/${PIPER_LIB_NAME}
        INTERFACE_INCLUDE_DIRECTORIES ${PIPER_INSTALL_DIR}/include
    )
endif()

# ONNX Runtime library shipped by Piper (already downloaded by ExternalProject)
if(WIN32)
    add_library(libpiper_onnx SHARED IMPORTED)
    set_target_properties(libpiper_onnx PROPERTIES
        IMPORTED_LOCATION ${PIPER_INSTALL_DIR}/lib/${ONNX_LIB_NAME}
        IMPORTED_IMPLIB ${PIPER_INSTALL_DIR}/lib/${ONNX_IMPLIB_NAME}
    )
else()
    add_library(libpiper_onnx SHARED IMPORTED)
    set_target_properties(libpiper_onnx PROPERTIES
        IMPORTED_LOCATION ${PIPER_INSTALL_DIR}/lib/${ONNX_LIB_NAME}
    )
endif()



add_dependencies(libpiper piper_ext)
add_dependencies(libpiper_onnx piper_ext)

set(PIPER_ASSETS_SRCDIR ${PIPER_INSTALL_DIR}/espeak-ng-data)
set(PIPER_ASSETS_DSTDIR ${CMAKE_BINARY_DIR}/bin/espeak-ng-data)

# Copy espeak-ng-data to ${app} binary dir
add_custom_command(
    OUTPUT ${PIPER_ASSETS_DSTDIR}
    COMMAND ${CMAKE_COMMAND} -E make_directory ${PIPER_ASSETS_DSTDIR}
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${PIPER_ASSETS_SRCDIR} ${PIPER_ASSETS_DSTDIR}
    DEPENDS piper_ext
    COMMENT "Copying Piper assets to bin/"
)

add_custom_target(copy_piper_assets ALL DEPENDS ${PIPER_ASSETS_DSTDIR})

# Copy Voice Models to ${app} binary dir
set(VOICE_FILES
    "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US/arctic/medium/en_US-arctic-medium.onnx"
)
set(VOICES_DST_DIR "${CMAKE_BINARY_DIR}/bin/voices")

foreach(voice_url IN LISTS VOICE_FILES)

    get_filename_component(filename "${voice_url}" NAME)

    string(REGEX MATCH "piper-voices/resolve/main/(.+)" _match "${voice_url}")
    if(CMAKE_MATCH_1)
        set(rel_path "${CMAKE_MATCH_1}")
        set(dest_file "${VOICES_DST_DIR}/${rel_path}")
        get_filename_component(dest_dir "${dest_file}" DIRECTORY)
    else()
        set(dest_file "${VOICES_DST_DIR}/${filename}")
        set(dest_dir "${VOICES_DST_DIR}")
    endif()

    # Download voice model
    add_custom_command(
        OUTPUT "${dest_file}"
        COMMAND ${CMAKE_COMMAND} -E make_directory "${dest_dir}"
        COMMAND ${CMAKE_COMMAND}
            -D URL=${voice_url}
            -D DEST=${dest_file}
            -P ${CMAKE_CURRENT_SOURCE_DIR}/cmake/download_file.cmake
        COMMENT "Downloading ${filename}..."
    )

    list(APPEND DOWNLOADED_VOICES "${dest_file}")

    # Download voice model config file
    add_custom_command(
        OUTPUT "${dest_file}.json"
        COMMAND ${CMAKE_COMMAND} -E make_directory "${dest_dir}"
        COMMAND ${CMAKE_COMMAND}
            -D URL=${voice_url}.json
            -D DEST=${dest_file}.json
            -P ${CMAKE_CURRENT_SOURCE_DIR}/cmake/download_file.cmake
        COMMENT "Downloading ${filename}..."
    )

    list(APPEND DOWNLOADED_VOICES "${dest_file}.json")
endforeach()

add_custom_target(copy_voices_assets ALL DEPENDS ${DOWNLOADED_VOICES})
