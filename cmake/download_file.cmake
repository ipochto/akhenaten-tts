if(NOT DEFINED URL OR NOT DEFINED DEST)
    message(FATAL_ERROR "URL and DEST must be defined")
endif()

set(download_args "${URL}" "${DEST}" STATUS status INACTIVITY_TIMEOUT 30)
if(DEFINED SHA256 AND NOT SHA256 STREQUAL "")
    list(APPEND download_args EXPECTED_HASH "SHA256=${SHA256}")
endif()

file(DOWNLOAD ${download_args})

list(GET status 0 error_code)
list(GET status 1 error_msg)

if(error_code EQUAL 0)
    message(STATUS "Downloaded: ${DEST}")
else()
    message(FATAL_ERROR "Failed to download ${URL}: ${error_msg}")
endif()