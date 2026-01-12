cmake_minimum_required(VERSION 3.30)
project(akhenaten-tts LANGUAGES C CXX)
set(app akhenaten-tts)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    message(WARNING "CMAKE_BUILD_TYPE is not set! Defaulting to Debug")
    set(CMAKE_BUILD_TYPE "Debug" CACHE STRING "Build type" FORCE)
endif()

include(ThirdPartyDependencies)
include(CopyScripts)

set(app_sources
    src/args_parser.cpp
    src/main.cpp
    src/phrases_parser.cpp
    src/tts.cpp
    src/tts-config.cpp
)
set(app_headers
    src/phrases_parser.hpp
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
    fmt::fmt
    libpiper
    libpiper_onnx
    lua::lua51
    sol2::sol2
    libcurl
)

add_executable(${app})

target_sources(${app} PRIVATE
    ${app_sources} 
    ${app_headers}
)

target_include_directories(${app} PUBLIC ${app_include_dirs})
target_compile_features(${app} PRIVATE cxx_std_17)
target_link_libraries(${app} PUBLIC ${app_libraries})


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
if(CMAKE_SYSTEM_NAME STREQUAL "Linux" AND CMAKE_BUILD_TYPE STREQUAL "Debug")
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
endif()

if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    if(CMAKE_BUILD_TYPE STREQUAL "Debug" AND is_msvc)
        target_compile_options(${app} PRIVATE
            /Oy-
            /W4
            /permissive-
            /Zc:strictStrings
        )
    endif()
    if(is_msvc)
        target_compile_options(${app} PRIVATE /MP)
    endif()
endif()
