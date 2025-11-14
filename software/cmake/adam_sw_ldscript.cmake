set(ADAM_BASE_LDSCRIPT "${CMAKE_SOURCE_DIR}/adam.ld")
set(ADAM_LDSCRIPT "${CMAKE_BINARY_DIR}/ldscript.ld")

add_custom_command(
    OUTPUT "${ADAM_LDSCRIPT}"
    COMMAND ${ADAM_EXECUTABLE} gen ldscript
        -c ${ADAM_CFG}
        -o ${ADAM_LDSCRIPT}
    DEPENDS "${_RULE_CFG}" "${ADAM_BASE_LDSCRIPT}"
    VERBATIM
)

add_custom_target(ldscript_gen DEPENDS "${ADAM_LDSCRIPT}")

add_library(ldscript INTERFACE)
add_dependencies(ldscript ldscript_gen)

target_link_options(ldscript INTERFACE
    "-L${CMAKE_SOURCE_DIR}"
    "-T${ADAM_LDSCRIPT}"
)

