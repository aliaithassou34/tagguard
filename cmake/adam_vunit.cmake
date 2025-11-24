function(adam_vunit_add_target _NAME)
  cmake_parse_arguments(_RULE
    "GUI"
    "TOP;LIBRARY;BINARY_DIR"
    ""
    ${ARGN}
  )

  if(NOT _NAME)
    message(FATAL_ERROR "adam_vunit_add_target: missing <target> name")
  endif()

  if(NOT _RULE_LIBRARY)
    message(FATAL_ERROR "adam_vunit_add_target(${_name}): LIBRARY is required")
  endif()

  if(NOT _RULE_BINARY_DIR)
    set(_RULE_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/${_NAME}")
  endif()

  adam_sv_collect("${_RULE_LIBRARY}" _defs _incs _srcs)

  file(MAKE_DIRECTORY "${_RULE_BINARY_DIR}")
  set(_py "${_RULE_BINARY_DIR}/run.py")

  set(_cmd ${ADAM_EXECUTABLE} gen vunit
    -S "${CMAKE_SOURCE_DIR}"
    -o "${_py}"
  )

  foreach(_i IN LISTS _incs)
    list(APPEND _cmd -I "${_i}")
  endforeach()

  foreach(_d IN LISTS _defs)
    list(APPEND _cmd -D "${_d}")
  endforeach()

  list(APPEND _cmd ${_srcs})

  add_custom_command(
    OUTPUT "${_py}"
    COMMAND ${_cmd}
    VERBATIM
  )

  add_custom_target("${_NAME}_gen" DEPENDS "${_py}" "${_RULE_LIBRARY}")

  set(_run_cmd "${Python3_EXECUTABLE}" "${_py}"
    -o "${_RULE_BINARY_DIR}"
  )

  if(_RULE_GUI)
    list(APPEND _run_cmd -g)
  endif()

  if(_RULE_TOP)
    string(FIND "${_RULE_TOP}" "." _dot_pos)
    if(_dot_pos GREATER_EQUAL 0)
      list(APPEND _run_cmd "lib.${_RULE_TOP}")
    else()
      list(APPEND _run_cmd "lib.${_RULE_TOP}.*")
    endif()
  endif()

  if(VSIM_EXECUTABLE)
    add_custom_target("${_NAME}"
      COMMAND ${_run_cmd}
      DEPENDS "${_NAME}_gen"
      WORKING_DIRECTORY "${_BINARY_DIR}"
      VERBATIM
      USES_TERMINAL
    )

    set_property(TARGET "${_NAME}" PROPERTY JOB_POOL_UTILITY heavy)
  endif()
endfunction()
