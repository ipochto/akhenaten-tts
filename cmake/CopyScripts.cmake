set(SCRIPTS_SRC_DIR "${CMAKE_SOURCE_DIR}/src/scripts")
set(SCRIPTS_DST_DIR "${CMAKE_BINARY_DIR}/bin")

file(MAKE_DIRECTORY "${SCRIPTS_DST_DIR}")

set(FILES
    "tts-config.lua"
)
set(DST_FILES "")

foreach(FILE_NAME IN LISTS FILES)

    set(DST_FILE "${SCRIPTS_DST_DIR}/${FILE_NAME}")

    add_custom_command(
        OUTPUT "${DST_FILE}"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different "${SCRIPTS_SRC_DIR}/${FILE_NAME}" "${DST_FILE}"
        DEPENDS "${SCRIPTS_SRC_DIR}/${FILE_NAME}"
        COMMENT "Copying asset: ${FILE_NAME}"
    )
    list(APPEND DST_FILES "${DST_FILE}")
endforeach()

add_custom_target(copy_scripts ALL DEPENDS ${DST_FILES})