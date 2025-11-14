function(adam_vivado_add_target _NAME)
  cmake_parse_arguments(_RULE
    ""
    "TOP;PART;LIBRARY;BINARY_DIR"
    "CONSTRAINTS"
    ${ARGN}
  )

  if(NOT _NAME)
    message(FATAL_ERROR "adam_vivado_add_target: missing <name>")
  endif()

  if(NOT _RULE_TOP)
    message(FATAL_ERROR "adam_vivado_add_target(${_NAME}): TOP is required")
  endif()

  if(NOT _RULE_PART)
    message(FATAL_ERROR "adam_vivado_add_target(${_NAME}): PART is required")
  endif()

  if(NOT _RULE_LIBRARY)
    message(FATAL_ERROR "adam_vivado_add_target(${_NAME}): LIBRARY is required")
  endif()

  if(NOT _RULE_BINARY_DIR)
    set(_RULE_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/${_NAME}")
  endif()

  adam_sv_collect("${_RULE_LIBRARY}" _defs _incs _srcs)

  get_filename_component(_xdc "${_RULE_CONSTRAINTS}" ABSOLUTE)

  file(MAKE_DIRECTORY "${_RULE_BINARY_DIR}")
  set(_tcl "${_RULE_BINARY_DIR}/vivado.tcl")

  set(_cmd ${ADAM_EXECUTABLE} gen vivado
    -S "${CMAKE_SOURCE_DIR}"
    --part "${_RULE_PART}"
    --top "${_RULE_TOP}"
    --jobs "${ADAM_JOBS}"
    -X "${_xdc}"
    -o "${_tcl}"
  )

  foreach(_i IN LISTS _incs)
    list(APPEND _cmd -I "${_i}")
  endforeach()

  foreach(_d IN LISTS _defs)
    list(APPEND _cmd -D "${_d}")
  endforeach()

  foreach(_x IN LISTS _V_CONSTRS)
    list(APPEND _cmd -X "${_x}")
  endforeach()

  list(APPEND _cmd ${_srcs})

  add_custom_command(
    OUTPUT  "${_tcl}"
    COMMAND ${_cmd}
    VERBATIM
  )

  add_custom_target("${_NAME}_gen" ALL DEPENDS "${_tcl}" "${_RULE_LIBRARY}")

  add_custom_target("${_NAME}"
    ALL
    COMMAND "${VIVADO_EXECUTABLE}" -mode batch -source "${_tcl}"
    DEPENDS "${_NAME}_gen"
    WORKING_DIRECTORY "${_RULE_BINARY_DIR}"
    VERBATIM
    USES_TERMINAL
  )

  set_property(TARGET "${_NAME}" PROPERTY JOB_POOL_UTILITY heavy)
endfunction()
