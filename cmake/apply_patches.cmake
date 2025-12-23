message(STATUS ${MESSAGE})

if(NOT PATCHES)
    message(STATUS "No patches to apply.")
    return()
endif()

string(REPLACE "|" ";" PATCH_LIST "${PATCHES}") # deserialize list

find_package(Git QUIET REQUIRED)

foreach(patch_file IN LISTS PATCH_LIST)
    if(NOT EXISTS "${patch_file}")
        message(FATAL_ERROR "Patch file not found: ${patch_file}")
    endif()

    message(STATUS "Applying patch: ${patch_file}")

    execute_process(
        COMMAND "${GIT_EXECUTABLE}" apply 
                                    --ignore-space-change
                                    --ignore-whitespace
                                    --whitespace=nowarn
                                    ${patch_file}

        RESULT_VARIABLE patch_result
        ERROR_VARIABLE patch_error
    )

    if(NOT patch_result EQUAL 0)
        message(FATAL_ERROR "Failed to apply patch ${patch_file}: ${patch_error}")
    endif()
endforeach()

message(STATUS "All patches applied successfully.")
