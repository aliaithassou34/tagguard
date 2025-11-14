function(adam_git_apply _SOURCE_DIR)

  if(NOT _SOURCE_DIR)
    message(FATAL_ERROR "adam_git_apply: _SOURCE_DIR is required")
  endif()

  set(_patches ${ARGN})

  if(NOT _patches)
    return()
  endif()

  foreach(_patch IN LISTS _patches)
    get_filename_component(_abs "${_patch}" REALPATH)

    if(NOT EXISTS "${_abs}")
      message(FATAL_ERROR "Patch file not found: ${_abs}")
    endif()

    execute_process(
      COMMAND "${GIT_EXECUTABLE}" apply "${_abs}"
      WORKING_DIRECTORY "${_SOURCE_DIR}"
      RESULT_VARIABLE _res
      OUTPUT_VARIABLE _out
      ERROR_VARIABLE  _err
      OUTPUT_STRIP_TRAILING_WHITESPACE
      ERROR_STRIP_TRAILING_WHITESPACE
    )

    if(NOT _res EQUAL 0)
      message(FATAL_ERROR
        "adam_git_apply: failed to apply '${_abs}' in '${_rel}'.\n"
        "Exit: ${_res}\n"
        "Stdout: ${_out}\n"
        "Stderr: ${_err}"
      )
    endif()
  endforeach()
endfunction()

function(adam_git_submodule_status _SOURCE_DIR _OUT_VAR)

  if(NOT _SOURCE_DIR)
    message(FATAL_ERROR "adam_git_submodule_status: _SOURCE_DIR is required")
  endif()

  get_filename_component(_work "${_SOURCE_DIR}" DIRECTORY)
  get_filename_component(_name "${_SOURCE_DIR}" NAME)

  execute_process(
    COMMAND "${GIT_EXECUTABLE}" submodule status -- "${_name}"
    WORKING_DIRECTORY "${_work}"
    RESULT_VARIABLE _res
    OUTPUT_VARIABLE _out
    ERROR_VARIABLE  _err
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )

  if(NOT _res EQUAL 0)
    message(FATAL_ERROR
      "adam_git: '${_SOURCE_DIR}' is not a known submodule.\n"
      "Stdout: ${_out}\n"
      "Stderr: ${_err}"
    )
  endif()

  set(${_OUT_VAR} "${_out}" PARENT_SCOPE)
endfunction()

function(adam_git_submodule_update _SOURCE_DIR)
  cmake_parse_arguments(_RULE
    "INIT;RECURSIVE"
    ""
    ""
    ${ARGN}
  )

  if(NOT _SOURCE_DIR)
    message(FATAL_ERROR "adam_git_submodule_update: _SOURCE_DIR is required")
  endif()

  get_filename_component(_work "${_SOURCE_DIR}" DIRECTORY)
  get_filename_component(_name "${_SOURCE_DIR}" NAME)

  set(_cmd "${GIT_EXECUTABLE}" submodule update)

  if(_RULE_INIT)
    list(APPEND _cmd --init)
  endif()

  if(_RULE_RECURSIVE)
    list(APPEND _cmd --recursive)
  endif()

  list(APPEND _cmd -- "${_name}")

  execute_process(
    COMMAND ${_cmd}
    WORKING_DIRECTORY "${_work}"
    RESULT_VARIABLE _res
    OUTPUT_VARIABLE _out
    ERROR_VARIABLE  _err
    OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_STRIP_TRAILING_WHITESPACE
  )

  if(NOT _res EQUAL 0)
    message(FATAL_ERROR
      "adam_git_submodule_update: failed for '${_SOURCE_DIR}'.\n"
      "Exit: ${_res}\n"
      "Stdout: ${_out}\n"
      "Stderr: ${_err}"
      )
  endif()
endfunction()


function(adam_git_submodule_ensure _SOURCE_DIR)
  cmake_parse_arguments(_RULE
    "RECURSIVE"
    ""
    "PATCHES"
    ${ARGN}
  )

  if(NOT _SOURCE_DIR)
    message(FATAL_ERROR "adam_git_submodule_ensure: _SOURCE_DIR is required")
  endif()

  adam_git_submodule_status("${_SOURCE_DIR}" _status)

  if(NOT "${_status}" MATCHES "^ ")
    message(STATUS "Performing submodule init for '${_SOURCE_DIR}'")

    if(_RULE_RECURSIVE)
      adam_git_submodule_update("${_SOURCE_DIR}" INIT RECURSIVE)
    else()
      adam_git_submodule_update("${_SOURCE_DIR}" INIT)
    endif()

    adam_git_apply("${_SOURCE_DIR}" ${_RULE_PATCHES})
  endif()
endfunction()
