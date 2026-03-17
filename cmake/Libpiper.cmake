include(ExternalProject)

set(ONNX_RUNTIME_VERSION "1.22.0")

if(WIN32)
    set(PIPER_LIB_NAME piper.dll)
    set(PIPER_IMPLIB_NAME piper.lib)
    set(ONNX_LIB_NAME onnxruntime.dll)
    set(ONNX_IMPLIB_NAME onnxruntime.lib)
elseif(APPLE)
    set(PIPER_LIB_NAME libpiper${CMAKE_SHARED_LIBRARY_SUFFIX})
    # macOS runtime resolves the versioned install name (e.g. libonnxruntime.1.22.0.dylib)
    set(ONNX_LIB_NAME libonnxruntime.${ONNX_RUNTIME_VERSION}${CMAKE_SHARED_LIBRARY_SUFFIX})
else()
    set(PIPER_LIB_NAME libpiper${CMAKE_SHARED_LIBRARY_SUFFIX})
    # Linux runtime resolves SONAME libonnxruntime.so.1
    set(ONNX_LIB_NAME libonnxruntime${CMAKE_SHARED_LIBRARY_SUFFIX}.1)
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
            "${CMAKE_SOURCE_DIR}/cmake/third-party/patches/006-piper-lazy-ort-env-win.patch"
        )
    elseif(APPLE)
        list(APPEND PIPER_PATCHES
            "${CMAKE_SOURCE_DIR}/cmake/third-party/patches/005-piper-add-espeak-ng-patch-macos.patch"
        )
    endif()

    list(JOIN PIPER_PATCHES "|" PIPER_PATCHES_SERIALIZED) # serialize list

    # Set libpiper's espeak-ng dependency to a specific version to avoid breakages from upstream changes
    set(ESPEAK_NG_GIT_TAG a06074c8fd80f2fd3632164dc01ebf1135395e11 CACHE STRING "espeak-ng git tag")

    # Make library portable (can find its dependencies in the same directory)
    set(PIPER_RUNTIME_RPATH "")
    if(APPLE)
        set(PIPER_RUNTIME_RPATH "@loader_path")
    elseif(UNIX)
        set(PIPER_RUNTIME_RPATH "\$ORIGIN")
    endif()

    set(PIPER_EXTERNAL_CMAKE_ARGS
        -DLIBPIPER_EXPORT_SYMBOLS=ON
        -DONNXRUNTIME_VERSION=${ONNX_RUNTIME_VERSION}
        -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
        -DCMAKE_C_COMPILER=${CMAKE_C_COMPILER}
        -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
        -DCMAKE_INSTALL_PREFIX=${PIPER_INSTALL_DIR}
    )

    if(PIPER_RUNTIME_RPATH)
        list(APPEND PIPER_EXTERNAL_CMAKE_ARGS
            -DCMAKE_BUILD_RPATH=${PIPER_RUNTIME_RPATH}
            -DCMAKE_INSTALL_RPATH=${PIPER_RUNTIME_RPATH}
            -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=FALSE
        )
    endif()

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
            ${PIPER_EXTERNAL_CMAKE_ARGS}

        BUILD_BYPRODUCTS
            ${PIPER_INSTALL_DIR}/${PIPER_LIB_NAME}
            ${PIPER_INSTALL_DIR}/${PIPER_IMPLIB_NAME}
            ${PIPER_INSTALL_DIR}/lib/${ONNX_LIB_NAME}
            ${PIPER_INSTALL_DIR}/lib/${ONNX_IMPLIB_NAME}
    )

    file(MAKE_DIRECTORY ${PIPER_INSTALL_DIR}/include)
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
