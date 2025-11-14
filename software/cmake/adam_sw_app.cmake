function(adam_sw_app _NAME)
  cmake_parse_arguments(_RULE
    ""
    ""
    "SOURCES;INCLUDE;LINKER_SCRIPT;LIBRARIES"
    ${ARGN}
  )

  adam_util_any_in_list(_in_all ADAM_SOFTWARE_TARGETS ${_NAME} all)
  if(_in_all)
    set(_all ALL)
  else()
    set(_exclude_from_all EXCLUDE_FROM_ALL)
  endif()

  add_executable(${_NAME}
    ${_exclude_from_all}
    ${_RULE_SOURCES}
  )

  set_target_properties(${_NAME} PROPERTIES SUFFIX ".elf")

  target_link_libraries(${_NAME} PRIVATE riscv_base ${_RULE_LIBRARIES})

  if(_RULE_INCLUDE)
    target_include_directories(${_NAME} PRIVATE ${_RULE_INCLUDE})
  endif()

  set(_MAP ${CMAKE_CURRENT_BINARY_DIR}/${_NAME}.map)
  set(_BIN ${CMAKE_CURRENT_BINARY_DIR}/${_NAME}.bin)
  set(_HEX ${CMAKE_CURRENT_BINARY_DIR}/${_NAME}.hex)
  set(_DUMP ${CMAKE_CURRENT_BINARY_DIR}/${_NAME}.dump)
  set(_SV ${CMAKE_CURRENT_BINARY_DIR}/${_NAME}.sv)

  target_link_options(${_NAME} PRIVATE -Wl,-Map=${_MAP})

  add_custom_command(
    OUTPUT ${_BIN}
    COMMAND ${CMAKE_OBJCOPY} $<TARGET_FILE:${_NAME}> -O binary ${_BIN}
    DEPENDS ${_NAME}
    VERBATIM
  )

  add_custom_target(${_NAME}_bin DEPENDS ${_BIN})

  add_custom_command(
    OUTPUT ${_HEX}
    COMMAND ${CMAKE_OBJCOPY} $<TARGET_FILE:${_NAME}> -O ihex ${_HEX}
    DEPENDS ${_NAME}
    VERBATIM
  )

  add_custom_target(${_NAME}_hex DEPENDS ${_HEX})

  add_custom_command(
    OUTPUT ${_DUMP}
    COMMAND ${CMAKE_OBJDUMP} -S -D $<TARGET_FILE:${_NAME}> > ${_DUMP}
    DEPENDS ${_NAME}
    VERBATIM
  )

  add_custom_target(${_NAME}_dump DEPENDS ${_DUMP})

  add_custom_command(
    OUTPUT ${_SV}
    COMMAND ${ADAM_EXECUTABLE} gen rom $<TARGET_FILE:${_NAME}>
      -f sverilog -m ${_NAME} -o ${_SV}
    DEPENDS ${_NAME}
    VERBATIM
  )

  add_custom_target(${_NAME}_sv DEPENDS ${_SV})
endfunction()
