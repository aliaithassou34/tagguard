

function(adam_verilator_add_target _NAME)
  cmake_parse_arguments(_RULE
    ""
    "TOP;LIBRARY;BINARY_DIR"
    ""
    ${ARGN}
  )

  adam_sv_collect("${_RULE_LIBRARY}" _defs _incs _srcs)

  adam_util_reorder(_srcs "pkg\\.sv$" ${_srcs})

  set(_cmd
    ${VERILATOR_EXECUTABLE}
    --top-module adam_top
    --Mdir "${_RULE_BINARY_DIR}"
    -Wno-fatal --cc --exe
    -DSYNTHESIS
    "${ADAM_SOURCE_DIR}/verilator_config.vlt"
    "${ADAM_SOURCE_DIR}/bhv/adam_top_tb.cpp"
    ${_srcs}
  )

  foreach(_d IN LISTS _defs)
    list(APPEND _cmd "-D${_d}")
  endforeach()

  foreach(_i IN LISTS _incs)
    list(APPEND _cmd "-I${_i}")
  endforeach()

  file(MAKE_DIRECTORY "${_RULE_BINARY_DIR}")

  add_custom_target("${_NAME}"
    COMMAND ${_cmd}
    COMMAND make -f Vadam_top.mk
    DEPENDS "${_RULE_LIBRARY}"
    WORKING_DIRECTORY "${_RULE_BINARY_DIR}"
    VERBATIM
    USES_TERMINAL
  )

endfunction()
