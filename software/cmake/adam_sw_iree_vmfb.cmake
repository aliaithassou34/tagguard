function(adam_sw_iree_vmfb _NAME)
  cmake_parse_arguments(_RULE
    ""
    "SOURCE;IDENTIFIER"
    "FLAGS;DEPENDS"
    ${ARGN}
  )

  if (NOT _RULE_SOURCE)
    message(FATAL_ERROR "SOURCE (.mlir) is required")
  endif()

  if (NOT _RULE_IDENTIFIER)
    set(_RULE_IDENTIFIER "${_NAME}_vmfb")
  endif()

  get_filename_component(_SOURCE "${_RULE_SOURCE}" REALPATH)

  set(_VMFB "${_NAME}.vmfb")
  set(_VMFB_H "${_NAME}_vmfb.h")
  set(_VMFB_C "${_NAME}_vmfb.c")

  add_custom_command(
    OUTPUT "${_VMFB}"
    COMMAND ${IREE_COMPILE_TOOL}
      ${_RULE_FLAGS}
      ${_SOURCE}
      -o ${_VMFB}
    DEPENDS ${IREE_COMPILE_TOOL} ${_SOURCE} ${_RULE_DEPENDS}
    VERBATIM
  )

  add_custom_command(
    OUTPUT "${_VMFB_H}" "${_VMFB_C}"
    COMMAND ${IREE_EMBED_TOOL}
      "--output_header=${_VMFB_H}"
      "--output_impl=${_VMFB_C}"
      "--identifier=${_RULE_IDENTIFIER}"
      "--flatten"
      "${_VMFB}"
    DEPENDS ${IREE_EMBED_TOOL} "${_VMFB}"
    VERBATIM
  )

  add_library(${_NAME} STATIC EXCLUDE_FROM_ALL "${_VMFB_C}" "${_VMFB_H}")
  set_target_properties(${_NAME} PROPERTIES LINKER_LANGUAGE C)
  target_include_directories(${_NAME} PUBLIC "${CMAKE_CURRENT_BINARY_DIR}")
endfunction()
