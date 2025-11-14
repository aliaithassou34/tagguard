function(adam_util_append_unique _LIST_VAR)
  foreach(_IT IN LISTS ARGN)
    list(FIND ${_LIST_VAR} "${_IT}" _IDX)
    if(_IDX EQUAL -1)
      list(APPEND ${_LIST_VAR} "${_IT}")
      set(${_LIST_VAR} "${${_LIST_VAR}}" PARENT_SCOPE)
    endif()
  endforeach()
endfunction()

function(adam_util_ensure_dir _PATH)
  get_filename_component(_dir "${_PATH}" DIRECTORY)

  # If no directory part (means path was already a dir), just use it
  if(_dir STREQUAL "")
    set(_dir "${_PATH}")
  endif()

  if(_dir AND NOT EXISTS "${_dir}")
    file(MAKE_DIRECTORY "${_dir}")
  endif()
endfunction()

function(adam_util_add_deps _NAME)
  if(ARGN)
    add_dependencies(${_NAME} ${ARGN})
  endif()
endfunction()

function(adam_util_add_cfg _NAME)
  cmake_parse_arguments(_RULE
    ""
    "OUTPUT"
    ""
    ${ARGN}
  )

  if(NOT _NAME)
    message(FATAL_ERROR "adam_util_add_cfg: missing required arg _NAME")
  endif()
  if(NOT _RULE_OUTPUT)
    message(FATAL_ERROR "adam_util_add_cfg: missing required arg OUTPUT")
  endif()

  adam_util_ensure_dir("${_RULE_OUTPUT}")

  add_custom_command(
    OUTPUT "${_RULE_OUTPUT}"
    COMMAND ${ADAM_EXECUTABLE} gen cfg
      -o ${_RULE_OUTPUT}
      ${_RULE_UNPARSED_ARGUMENTS}
    DEPENDS "${ADAM_SOURCE_DIR}/python/src/adam/cfg.py"
    VERBATIM
  )

  add_custom_target("${_NAME}" DEPENDS "${_RULE_OUTPUT}")
endfunction()

function(adam_util_add_pkg _NAME)
  cmake_parse_arguments(_RULE
    ""
    "CFG;OUTPUT"
    ""
    ${ARGN}
  )

  if(NOT _NAME)
    message(FATAL_ERROR "adam_util_add_pkg: missing required arg _NAME")
  endif()
  if(NOT _RULE_CFG)
    message(FATAL_ERROR "adam_util_add_pkg: missing required arg CFG")
  endif()
  if(NOT _RULE_OUTPUT)
    message(FATAL_ERROR "adam_util_add_pkg: missing required arg OUTPUT")
  endif()

  adam_util_ensure_dir("${_RULE_OUTPUT}")

  add_custom_command(
    OUTPUT  "${_RULE_OUTPUT}"
    COMMAND ${ADAM_EXECUTABLE} gen pkg -c ${_RULE_CFG} -o ${_RULE_OUTPUT}
    DEPENDS "${_RULE_CFG}"
    VERBATIM
  )

  adam_sv_add_library("${_NAME}" SOURCES "${_RULE_OUTPUT}")
endfunction()

function(adam_util_add_ral _NAME)
  cmake_parse_arguments(_RULE
    ""
    "CFG;OUTPUT_DIR"
    ""
    ${ARGN}
  )

  if(NOT _NAME)
    message(FATAL_ERROR "adam_util_add_ral: missing required arg _NAME")
  endif()
  if(NOT _RULE_CFG)
    message(FATAL_ERROR "adam_util_add_ral: missing required arg CFG")
  endif()
  if(NOT _RULE_OUTPUT_DIR)
    message(FATAL_ERROR "adam_util_add_ral: missing required arg OUTPUT_DIR")
  endif()

  file(MAKE_DIRECTORY "${_RULE_OUTPUT_DIR}")

  set(_out "${_RULE_OUTPUT_DIR}/adam_ral.h")

  add_custom_command(
    OUTPUT  "${_out}"
    COMMAND ${ADAM_EXECUTABLE} gen ral -c ${_RULE_CFG} -o ${_out}
    DEPENDS "${_RULE_CFG}"
    VERBATIM
  )

  add_library("${_NAME}" INTERFACE "${_out}")

  target_include_directories("${_NAME}" INTERFACE "${_RULE_OUTPUT_DIR}")

endfunction()

function(adam_util_add_stamped_target _NAME)
  cmake_parse_arguments(_RULE "ALL" "" "SOURCES" ${ARGN})

  set(_all "$<$<BOOL:${_RULE_ALL}>:ALL>")

  set(_stamp_file "${CMAKE_BINARY_DIR}/stamps/${_NAME}.stamp")

  file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/stamps")

  add_custom_command(
    OUTPUT "${_stamp_file}"
    ${_RULE_UNPARSED_ARGUMENTS}
    COMMAND ${CMAKE_COMMAND} -E touch "${_stamp_file}"
    VERBATIM
  )

  add_custom_target(${_NAME}
    ${_all}
    DEPENDS "${_stamp_file}"
    SOURCES ${_RULE_SOURCES}
  )
endfunction()

function(adam_util_add_pip _NAME _REQUIREMENTS_FILE)
  adam_util_add_stamped_target("${_NAME}"
    COMMAND "${Python3_EXECUTABLE}" -m pip install -r "${_REQUIREMENTS_FILE}"
    DEPENDS "${_REQUIREMENTS_FILE}"
    VERBATIM
    USES_TERMINAL
  )
endfunction()

function(adam_util_run)
  if(ARGC LESS 1)
    message(FATAL_ERROR "adam_util_run: requires at least one argument")
  endif()

  execute_process(
    COMMAND ${ARGV}
    RESULT_VARIABLE _res
    COMMAND_ECHO STDOUT
  )

  if (NOT _res EQUAL 0)
    string (JOIN " " _cmd ${ARGV})
    message(
      FATAL_ERROR
      "adam_util_run: command '${_cmd}' failed with exit code ${_res}"
    )
  endif()
endfunction()

function(adam_util_reorder _OUT_VAR _REGEX)
  set(_matched)
  set(_others)

  foreach(_i IN LISTS ARGN)
    if(_i MATCHES "${_REGEX}")
      list(APPEND _matched "${_i}")
    else()
      list(APPEND _others "${_i}")
    endif()
  endforeach()

  set(${_OUT_VAR} ${_matched} ${_others} PARENT_SCOPE)
endfunction()

function(adam_util_any_in_list _OUT_VAR _LIST_VAR)
  set(_out FALSE)
  set(_values ${ARGN})

  foreach(_arg ${ARGN})
    list(FIND ${_LIST_VAR} "${_arg}" _index)
    if(NOT _index EQUAL -1)
      set(_out TRUE)
      break()
    endif()
  endforeach()

  set(${_OUT_VAR} ${_out} PARENT_SCOPE)
endfunction()
