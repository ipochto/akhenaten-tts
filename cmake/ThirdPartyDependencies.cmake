include(FetchContent)

find_package(cxxopts CONFIG QUIET)
if (NOT cxxopts_FOUND)
    message(STATUS "cxxopts not found, fetching with FetchContent...")
    FetchContent_Declare(
        cxxopts
        GIT_REPOSITORY https://github.com/jarro2783/cxxopts.git
        GIT_TAG        v3.3.1
    )
    FetchContent_MakeAvailable(cxxopts)
endif()

find_package(fmt CONFIG QUIET)
if (NOT fmt_FOUND)
    message(STATUS "fmt not found, fetching with FetchContent...")
    FetchContent_Declare(
        fmt
        GIT_REPOSITORY https://github.com/fmtlib/fmt.git
        GIT_TAG        11.2.0
    )
    FetchContent_MakeAvailable(fmt)
endif()

find_package(cpr CONFIG QUIET)
if (NOT cpr_FOUND)
    message(STATUS "cpr not found, fetching with FetchContent...")

    set(CPR_BUILD_TESTS OFF CACHE BOOL "" FORCE)
    set(CPR_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
    set(CPR_CURL_USE_LIBPSL OFF CACHE BOOL "" FORCE) # requires Meson/PSL

    FetchContent_Declare(
        cpr
        GIT_REPOSITORY https://github.com/libcpr/cpr.git
        GIT_TAG        1.14.1
    )
    FetchContent_MakeAvailable(cpr)
endif()

FetchContent_Declare(
    luaSandboxes
    GIT_REPOSITORY https://github.com/ipochto/luaSandboxes.git
    GIT_TAG master
    GIT_SHALLOW TRUE
)
FetchContent_MakeAvailable(luaSandboxes)

include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/Libpiper.cmake)
