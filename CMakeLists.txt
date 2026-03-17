cmake_minimum_required(VERSION 3.30)
project(akhenaten-tts LANGUAGES C CXX)
set(app akhenaten-tts)

option(BUILD_SHARED_LIBS "Build using shared libraries" OFF)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")

if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    message(WARNING "CMAKE_BUILD_TYPE is not set! Defaulting to Debug")
    set(CMAKE_BUILD_TYPE "Debug" CACHE STRING "Build type" FORCE)
endif()

include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/ThirdPartyDependencies.cmake)

set(app_sources
    src/args_parser.cpp
    src/main.cpp
    src/tts.cpp
    src/tts-config.cpp
)
set(app_headers
    src/script.hpp
    src/tts.hpp
    src/tts-config.hpp
)

set(app_include_dirs
    SYSTEM
    src
)

set(app_libraries
    cxxopts::cxxopts
    libpiper
    libpiper_onnx
    cpr::cpr
    luaSandboxes::luaSandboxes
)

add_executable(${app})

target_sources(${app} PRIVATE
    ${app_sources} 
    ${app_headers}
)

target_include_directories(${app} PUBLIC ${app_include_dirs})
target_compile_features(${app} PRIVATE cxx_std_20)
target_link_libraries(${app} PUBLIC ${app_libraries})

# Ensure portable binary can resolve bundled shared libraries from ./lib.
if(APPLE)
    set_property(TARGET ${app} APPEND PROPERTY BUILD_RPATH "@executable_path/lib")
elseif(UNIX)
    set_property(TARGET ${app} APPEND PROPERTY BUILD_RPATH "\$ORIGIN/lib")
endif()


# Debug vs Release definitions
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    target_compile_definitions(${app} PUBLIC DEBUG)
else()
    target_compile_definitions(${app} PUBLIC NDEBUG)
endif()

# Compiler detection
set(is_gcc   ${CMAKE_CXX_COMPILER_ID} STREQUAL "GNU")
set(is_clang ${CMAKE_CXX_COMPILER_ID} STREQUAL "Clang")
set(is_msvc  ${CMAKE_CXX_COMPILER_ID} STREQUAL "MSVC")

# Handle Clang in MSVC compatibility mode (clang-cl)
if(is_clang AND CMAKE_CXX_SIMULATE_ID STREQUAL "MSVC")
    set(is_msvc TRUE)
endif()

# Platform- and config-specific compile options
if(UNIX AND CMAKE_BUILD_TYPE STREQUAL "Debug")
    target_compile_options(${app} PRIVATE
        -fno-inline
        -fstack-protector-strong
        -fno-omit-frame-pointer
        -Wall
        -Wextra
        -Wpedantic
        -Wreorder
        -Wwrite-strings
    )
    if(is_gcc)
        target_compile_options(${app} PRIVATE -ggdb)
    elseif(is_clang)
        target_compile_options(${app} PRIVATE -glldb)
    endif()
elseif(WIN32)
    if(CMAKE_BUILD_TYPE STREQUAL "Debug" AND is_msvc)
        target_compile_options(${app} PRIVATE
            /Oy-
            /W4
            /permissive-
            /Zc:strictStrings
        )
    endif()
    if(is_msvc AND NOT is_clang)
        target_compile_options(${app} PRIVATE /MP)
    endif()
endif()

set(APP_PORTABLE_DIR "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/portable")
if(UNIX)
    set(APP_PORTABLE_LIBS_DIR "${APP_PORTABLE_DIR}/lib")
else()
    set(APP_PORTABLE_LIBS_DIR "${APP_PORTABLE_DIR}")
endif()

add_custom_target(portable_package
    COMMAND ${CMAKE_COMMAND} -E make_directory "${APP_PORTABLE_DIR}"
    COMMAND ${CMAKE_COMMAND} -E make_directory "${APP_PORTABLE_LIBS_DIR}"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "$<TARGET_FILE:${app}>"
        "${APP_PORTABLE_DIR}/"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${CMAKE_SOURCE_DIR}/src/scripts/tts-config.lua"
        "${APP_PORTABLE_DIR}/"    
    COMMAND ${CMAKE_COMMAND} -E copy_directory
        "${PIPER_INSTALL_DIR}/espeak-ng-data"
        "${APP_PORTABLE_DIR}/espeak-ng-data"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "$<TARGET_PROPERTY:libpiper,IMPORTED_LOCATION>"
        "${APP_PORTABLE_LIBS_DIR}/"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "$<TARGET_PROPERTY:libpiper_onnx,IMPORTED_LOCATION>"
        "${APP_PORTABLE_LIBS_DIR}/"
    DEPENDS ${app}
    VERBATIM
)
