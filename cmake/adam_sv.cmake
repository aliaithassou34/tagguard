function(_adam_sv_set _NAME _KEY)
  set_property(GLOBAL PROPERTY "ADAM_SV_${_NAME}_${_KEY}" "${ARGN}")
endfunction()

function(_adam_sv_get _NAME _KEY _OUT_VAR)
  get_property(_VAL GLOBAL PROPERTY "ADAM_SV_${_NAME}_${_KEY}")

  set(${_OUT_VAR} "${_VAL}" PARENT_SCOPE)
endfunction()

function(_adam_sv_absolutize _LIST_VAR _BASE_DIR)

  # Default to current source dir if no base directory is given
  if(NOT DEFINED _BASE_DIR OR "${_BASE_DIR}" STREQUAL "")
    set(_BASE_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
  endif()
  get_filename_component(_BASE_DIR "${_BASE_DIR}" ABSOLUTE)

  # Build new absolute list
  set(_res "")
  foreach(_p IN LISTS ${_LIST_VAR})
    get_filename_component(_abs "${_p}" ABSOLUTE BASE_DIR "${_BASE_DIR}")
    list(APPEND _res "${_abs}")
  endforeach()

  # Return result to caller
  set(${_LIST_VAR} "${_res}" PARENT_SCOPE)
endfunction()

function(_adam_sv_resolve _NAME _DEFS_VAR _INCS_VAR _SRCS_VAR
  _STACK_VAR _VISITED_VAR)

  # Local copies to avoid recursion shadowing
  set(_defs "${${_DEFS_VAR}}")
  set(_incs "${${_INCS_VAR}}")
  set(_srcs "${${_SRCS_VAR}}")
  set(_stack "${${_STACK_VAR}}")
  set(_visited "${${_VISITED_VAR}}")

  # Cycle check: is _NAME on the current recursion STACK?
  list(FIND _stack "${_NAME}" _in_stack)
  if(NOT _in_stack EQUAL -1)
    message(FATAL_ERROR "adam_sv: cyclic dependency: ${_stack} -> ${_NAME}")
  endif()

  # Already fully processed?
  list(FIND _visited "${_NAME}" _seen)
  if(NOT _seen EQUAL -1)
    return()
  endif()

  # Is it an adam_sv target?
  _adam_sv_get(${_NAME} "DECLARED" _declared)
  if(NOT _declared)
    return()
  endif()

  # Push onto DFS stack; propagate to caller so child calls see the update.
  list(PREPEND _stack "${_NAME}")

  # Recurse into dependencies
  _adam_sv_get(${_NAME} "DEPENDS" _deps)
  foreach(_d IN LISTS _deps)
    _adam_sv_resolve("${_d}" _defs _incs _srcs _stack _visited)
  endforeach()

  # Get node data
  _adam_sv_get(${_NAME} "DEFINITIONS" _node_defs)
  _adam_sv_get(${_NAME} "INCLUDES" _node_incs)
  _adam_sv_get(${_NAME} "SOURCES" _node_srcs)

  # Append node data
  adam_util_append_unique(_defs ${_node_defs})
  adam_util_append_unique(_incs ${_node_incs})
  adam_util_append_unique(_srcs ${_node_srcs})

  # Mark visited
  list(APPEND _visited "${_NAME}")

  # Pop stack
  list(REMOVE_AT _stack 0)

  # Return results to caller
  set(${_DEFS_VAR} "${_defs}" PARENT_SCOPE)
  set(${_INCS_VAR} "${_incs}" PARENT_SCOPE)
  set(${_SRCS_VAR} "${_srcs}" PARENT_SCOPE)
  set(${_STACK_VAR} "${_stack}" PARENT_SCOPE)
  set(${_VISITED_VAR} "${_visited}" PARENT_SCOPE)
endfunction()

function(adam_sv_add_library _NAME)
  cmake_parse_arguments(_RULE
    ""
    "BASE_DIR"
    "DEFINITIONS;INCLUDES;SOURCES;DEPENDS"
    ${ARGN}
  )

  if(NOT _NAME)
    message(FATAL_ERROR "adam_sv_add_library: missing name")
  endif()

  _adam_sv_absolutize(_RULE_INCLUDES "${_RULE_BASE_DIR}")
  _adam_sv_absolutize(_RULE_SOURCES "${_RULE_BASE_DIR}")

  add_custom_target(${_NAME} DEPENDS ${_RULE_SOURCES})

  if(_RULE_DEPENDS)
    add_dependencies(${_NAME} ${_RULE_DEPENDS})
  endif()

  _adam_sv_set(${_NAME} "DEFINITIONS" "${_RULE_DEFINITIONS}")
  _adam_sv_set(${_NAME} "INCLUDES" ${_RULE_INCLUDES})
  _adam_sv_set(${_NAME} "SOURCES" ${_RULE_SOURCES})
  _adam_sv_set(${_NAME} "DEPENDS" ${_RULE_DEPENDS})
  _adam_sv_set(${_NAME} "DECLARED" TRUE)
endfunction()

function(adam_sv_collect _NAME _DEFINES_VAR _INCLUDES_VAR _SOURCES_VAR)
  if(NOT _NAME)
    message(FATAL_ERROR "adam_sv_get_lists: missing name")
  endif()

  set(_defs "")
  set(_incs "")
  set(_srcs "")
  set(_stack "")
  set(_visited "")

  _adam_sv_resolve("${_NAME}" _defs _incs _srcs _stack _visited)

  set(${_DEFINES_VAR}  "${_defs}" PARENT_SCOPE)
  set(${_INCLUDES_VAR} "${_incs}" PARENT_SCOPE)
  set(${_SOURCES_VAR}  "${_srcs}" PARENT_SCOPE)
endfunction()

function(adam_sv_print _NAME)
  adam_sv_collect(${_NAME} _defs _incs _srcs)
  message(STATUS "adam_sv '${_NAME}':")
  message(STATUS "  DEFINITIONS=${_defs}")
  message(STATUS "  INCLUDES=${_incs}")
  message(STATUS "  SOURCES=${_srcs}")
endfunction()
