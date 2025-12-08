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

set(app_sources
    src/args_parser.cpp    
    src/main.cpp
)
set(app_headers
    src/tts.hpp
)

set(app_include_dirs
    SYSTEM
    src
)

set(app_libraries
    cxxopts::cxxopts
    fmt::fmt
)

add_executable(${app})
target_sources(${app} PRIVATE
    ${app_sources} 
    ${app_headers}
)
target_include_directories(${app} PUBLIC ${app_include_dirs})

target_compile_features(${app} PRIVATE cxx_std_17)
target_link_libraries(${app} PUBLIC ${app_libraries})

set(is_gcc "$<CXX_COMPILER_ID:GNU>")
set(is_clang "$<CXX_COMPILER_ID:Clang>")
set(is_msvc "$<OR:$<CXX_COMPILER_ID:MSVC>,$<AND:$<CXX_COMPILER_ID:Clang>,$<CXX_COMPILER_FRONTEND_VARIANT:MSVC>>>")

target_compile_definitions(${app} PUBLIC
    $<$<CONFIG:Debug>:DEBUG>
    $<$<NOT:$<CONFIG:Debug>>:NDEBUG>
)

target_compile_options(${app} PRIVATE 
    # Linux
    $<$<AND:$<PLATFORM_ID:Linux>,$<CONFIG:Debug>>:
        -fno-inline
        -fstack-protector-strong
        -fno-omit-frame-pointer
        -Wall -Wextra -Wpedantic -Wreorder
        -Wwrite-strings
        $<${is_gcc}: -ggdb>
        $<${is_clang}: -glldb>
    >

    # Windows
    $<$<AND:$<PLATFORM_ID:Windows>,$<CONFIG:Debug>,${is_msvc}>:
        /Oy-
        /W4
        /permissive-
        /Zc:strictStrings
    >
    $<$<CXX_COMPILER_ID:MSVC>:/MP>    
)