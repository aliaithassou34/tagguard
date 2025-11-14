function(adam_vendorize_add_target _NAME)
  cmake_parse_arguments(_RULE
    ""
    "LIBRARY;BINARY_DIR"
    ""
    ${ARGN}
  )

  adam_sv_collect("${_RULE_LIBRARY}" _defs _incs _srcs)

  adam_util_reorder(_srcs "pkg\\.sv$" ${_srcs})

  file(MAKE_DIRECTORY "${_RULE_BINARY_DIR}")

  add_custom_target("${_NAME}"
    ALL
    COMMAND ${CMAKE_COMMAND}
      "-DDEFS=$<JOIN:${_defs},;>"
      "-DINCS=$<JOIN:${_incs},;>"
      "-DSRCS=$<JOIN:${_srcs},;>"
      -P "${CMAKE_SOURCE_DIR}/cmake/adam_build/vendorize.cmake"
    DEPENDS "${_RULE_LIBRARY}"
    WORKING_DIRECTORY "${_RULE_BINARY_DIR}"
    VERBATIM
  )
endfunction()
