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

set(PIPER_READY TRUE)
foreach(file IN ITEMS
    "${PIPER_INSTALL_DIR}/include/piper.h"
    "${PIPER_INSTALL_DIR}/${PIPER_LIB_NAME}"
    "${PIPER_INSTALL_DIR}/lib/${ONNX_LIB_NAME}"
    "${PIPER_INSTALL_DIR}/espeak-ng-data")

    if (NOT EXISTS "${file}")
        set(PIPER_READY FALSE)
    endif()
endforeach()

if (NOT PIPER_READY)
    message(STATUS "Libpiper not found. Building as external project")

    set(PIPER_PATCHES
        "${CMAKE_SOURCE_DIR}/cmake/third-party/patches/001-piper-cmake.patch"
    )

    if(WIN32)
        list(APPEND PIPER_PATCHES
            "${CMAKE_SOURCE_DIR}/cmake/third-party/patches/002-piper-dll-export-symbols-win.patch"
            "${CMAKE_SOURCE_DIR}/cmake/third-party/patches/003-piper-wchar-fix-win.patch"
            "${CMAKE_SOURCE_DIR}/cmake/third-party/patches/004-piper-add-espeak-ng-patch-win.patch"
        )
    endif()

    list(JOIN PIPER_PATCHES "|" PIPER_PATCHES_SERIALIZED) # serialize list

    ExternalProject_Add(libpiper_ext
        GIT_REPOSITORY https://github.com/OHF-Voice/piper1-gpl.git
        GIT_TAG        32b95f8c1f0dc0ce27a6acd1143de331f61af777
        PREFIX ${PIPER_PREFIX}

        SOURCE_SUBDIR libpiper

        PATCH_COMMAND
            ${CMAKE_COMMAND}
                -D MESSAGE="Patching libpiper and its deps."
                -D PATCHES=${PIPER_PATCHES_SERIALIZED}
                -P ${CMAKE_CURRENT_SOURCE_DIR}/cmake/apply_patches.cmake

        CMAKE_GENERATOR ${CMAKE_GENERATOR}
        CMAKE_ARGS
            -DLIBPIPER_EXPORT_SYMBOLS=ON
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

    set(PIPER_ASSETS_READY_STAMP "${PIPER_INSTALL_DIR}/.piper_assets_ready.stamp")

    ExternalProject_Add_Step(libpiper_ext mark_assets_ready
        COMMAND ${CMAKE_COMMAND} -E touch "${PIPER_ASSETS_READY_STAMP}"
        DEPENDEES install
        ALWAYS 0
    )
endif()

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

set(COPY_PIPER_ASSETS_DEP "")

if (TARGET libpiper_ext)
    set(COPY_PIPER_ASSETS_DEP libpiper_ext)
else()
    set(COPY_PIPER_ASSETS_DEP "${PIPER_ASSETS_READY_STAMP}")
endif()

set(PIPER_ASSETS_COPIED_STAMP "${PIPER_ASSETS_DSTDIR}/.assets_copied")

# Copy espeak-ng-data to ${app} binary dir
add_custom_command(
    OUTPUT ${PIPER_ASSETS_COPIED_STAMP}
    COMMAND ${CMAKE_COMMAND} -E make_directory "${PIPER_ASSETS_DSTDIR}"
    COMMAND ${CMAKE_COMMAND} -E copy_directory "${PIPER_ASSETS_SRCDIR}" "${PIPER_ASSETS_DSTDIR}"
    COMMAND ${CMAKE_COMMAND} -E touch "${PIPER_ASSETS_COPIED_STAMP}"
    DEPENDS ${COPY_PIPER_ASSETS_DEP}
    COMMENT "Copying Piper assets to bin/"
    VERBATIM
)
add_custom_target(copy_piper_assets ALL DEPENDS ${PIPER_ASSETS_COPIED_STAMP})

