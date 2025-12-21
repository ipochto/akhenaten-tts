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

set(PIPER_PREFIX ${CMAKE_BINARY_DIR}/_deps/libpiper_ext)

set(PIPER_INSTALL_DIR ${PIPER_PREFIX}/install)

#if(WIN32)
    find_package(Git REQUIRED)
    set(PIPER_PATCH_MSG "Patching espeak-ng for fixing Windows build")
    set(PIPER_PATCH_CMD
        ${GIT_EXECUTABLE} apply --ignore-space-change
                                --ignore-whitespace
                                --whitespace=nowarn
                                ${CMAKE_SOURCE_DIR}/cmake/third-party/patches/piper_n_espeak-patches-win.patch)
#endif()

ExternalProject_Add(libpiper_ext
    GIT_REPOSITORY https://github.com/OHF-Voice/piper1-gpl.git
    GIT_TAG        main
    PREFIX ${PIPER_PREFIX}

    SOURCE_SUBDIR libpiper

    PATCH_COMMAND
        ${CMAKE_COMMAND} -E echo ${PIPER_PATCH_MSG}
        COMMAND ${PIPER_PATCH_CMD}

    CMAKE_GENERATOR ${CMAKE_GENERATOR}
    CMAKE_ARGS
        -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
        -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
        -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
        -DCMAKE_INSTALL_PREFIX=${PIPER_INSTALL_DIR}

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
add_library(libpiper_onnx SHARED IMPORTED)

if(WIN32)
    set_target_properties(libpiper_onnx PROPERTIES
        IMPORTED_LOCATION ${PIPER_INSTALL_DIR}/lib/${ONNX_LIB_NAME}
        IMPORTED_IMPLIB ${PIPER_INSTALL_DIR}/lib/${ONNX_IMPLIB_NAME}
    )
else()
    set_target_properties(libpiper_onnx PROPERTIES
        IMPORTED_LOCATION ${PIPER_INSTALL_DIR}/lib/${ONNX_LIB_NAME}
    )
endif()

add_dependencies(libpiper libpiper_ext)
add_dependencies(libpiper_onnx libpiper_ext)

set(PIPER_ASSETS_SRCDIR ${PIPER_INSTALL_DIR}/espeak-ng-data)
set(PIPER_ASSETS_DSTDIR ${CMAKE_BINARY_DIR}/bin/espeak-ng-data)

# Copy espeak-ng-data to ${app} binary dir
add_custom_command(
    OUTPUT ${PIPER_ASSETS_DSTDIR}
    COMMAND ${CMAKE_COMMAND} -E make_directory ${PIPER_ASSETS_DSTDIR}
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${PIPER_ASSETS_SRCDIR} ${PIPER_ASSETS_DSTDIR}
    DEPENDS libpiper_ext
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
