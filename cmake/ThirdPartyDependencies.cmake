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
