function(adam_sw_blob _NAME)
  cmake_parse_arguments(_RULE
    ""
    "SOURCE;IDENTIFIER;ALIGN"
    "DEPENDS"
    ${ARGN}
  )

  if (NOT _RULE_SOURCE)
    message(FATAL_ERROR "SOURCE is required")
  endif()

  if (NOT _RULE_IDENTIFIER)
    set(_RULE_IDENTIFIER "${_NAME}")
  endif()

  if (NOT _RULE_ALIGN)
    set(_RULE_ALIGN "64")
  endif()

  get_filename_component(_bin "${_RULE_SOURCE}" ABSOLUTE
    BASE_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
  get_filename_component(_bin_fname ${_bin} NAME)
  string(REGEX REPLACE "[^A-Za-z0-9_]" "_" _old ${_bin})

  set(_sym "${_RULE_IDENTIFIER}")
  set(_obj "${CMAKE_CURRENT_BINARY_DIR}/${_bin_fname}.obj")

  add_custom_command(
    OUTPUT "${_obj}"
    COMMAND ${CMAKE_OBJCOPY}
      -I binary
      -O ${ADAM_ELF_FORMAT}
      --rename-section .data=.rodata.${_sym},alloc,load,readonly,data,contents
      --set-section-alignment .rodata.${_sym}=64
      --redefine-sym _binary_${_old}_start=${_sym}_start
      --redefine-sym _binary_${_old}_end=${_sym}_end
      --redefine-sym _binary_${_old}_size=${_sym}_size
      ${_bin} ${_obj}
    DEPENDS "${_RULE_SOURCE}" ${_RULE_DEPENDS}
    VERBATIM
  )

  add_library(${_NAME} STATIC "${_obj}")
  set_target_properties(${_NAME} PROPERTIES LINKER_LANGUAGE C)
endfunction()
