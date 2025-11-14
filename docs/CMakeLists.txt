adam_util_add_pip(docs_pip "${CMAKE_CURRENT_SOURCE_DIR}/requirements.txt")

add_custom_target(docs ALL
    COMMAND ${Python3_EXECUTABLE} -m sphinx -b html
            ${CMAKE_CURRENT_SOURCE_DIR}
            ${CMAKE_CURRENT_BINARY_DIR}
    DEPENDS docs_pip
)
