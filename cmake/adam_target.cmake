function(adam_target _NAME)
  cmake_parse_arguments(_RULE
    ""
    "TOP;PART;APP"
    "DEPENDS;DEFINITIONS;INCLUDES;SOURCES;CONSTRAINTS;CFG_ARGS"
    ${ARGN}
  )

  if(NOT _NAME)
    message(FATAL_ERROR "adam_add_target: _NAME is required.")
  endif()

  set(_binary_dir "${CMAKE_BINARY_DIR}/targets/${_NAME}")
  set(_cfg_file "${_binary_dir}/cfg.json")
  set(_pkg_file "${_binary_dir}/adam_cfg_pkg.sv")
  set(_sw_dir "${_binary_dir}/software")

  if(_RULE_APP)
    set(_app "${_RULE_APP}")
    set(_rom_target "${_app}_sv")
    set(_rom_file "${_sw_dir}/build/apps/${_app}/${_app}.sv")
    set(_rom_dep "${_NAME}_software")
  endif()

  set(_software_targets ${_rom_target} ${ADAM_SOFTWARE_TARGETS})

  set(_cfg ${_NAME}_cfg)
  adam_util_add_cfg(${_cfg} OUTPUT "${_cfg_file}" ${_RULE_CFG_ARGS})

  set(_pkg ${_NAME}_pkg)
  adam_util_add_pkg(${_pkg} CFG "${_cfg_file}" OUTPUT "${_pkg_file}")

  set(_software ${_NAME}_software)
  adam_software(${_software}
    PREFIX "${_sw_dir}"
    ADAM_CFG "${_cfg_file}"
    TARGETS ${_software_targets}
    DEPENDS ${_cfg}
    BYPRODUCTS "${_rom_file}"
  )

  set(_rtl ${_NAME}_rtl)
  adam_sv_add_library(${_rtl}
    DEPENDS ${_pkg} ${_RULE_DEPENDS} ${_rom_dep}
    DEFINITIONS ${_RULE_DEFINITIONS}
    INCLUDES ${_RULE_INCLUDES}
    SOURCES ${_pkg_file} ${_RULE_SOURCES} ${_rom_file}
  )

  set(_bhv ${_NAME}_bhv)
  adam_sv_add_library(${_bhv} DEPENDS ${_rtl} adam_bhv)

  if(ADAM_ENABLE_VUNIT)
    set(_vunit ${_NAME}_vunit)
    adam_vunit_add_target(${_vunit}
      LIBRARY ${_bhv}
      BINARY_DIR "${_binary_dir}/vunit"
    )
  endif()

  if(ADAM_ENABLE_VERILATOR)
    set(_verilator ${_NAME}_verilator)
    adam_verilator_add_target(${_verilator}
      TOP adam_top
      LIBRARY ${_rtl}
      BINARY_DIR "${_binary_dir}/verilator"
    )
  endif()

  if(
    ADAM_ENABLE_VIVADO AND
    (_RULE_TOP AND _RULE_PART AND _RULE_CONSTRAINTS)
  )
    set(_vivado ${_NAME}_vivado)
    adam_vivado_add_target(${_vivado}
      TOP "${_RULE_TOP}"
      PART "${_RULE_PART}"
      LIBRARY ${_rtl}
      BINARY_DIR "${_binary_dir}/vivado"
      CONSTRAINTS "${_RULE_CONSTRAINTS}"
    )
    adam_util_add_deps(${_vivado} ${_vunit} ${_verilator})
  endif()

  if(ADAM_ENABLE_VENDORIZE)
    set(_vendorize "${_NAME}_vendorize")
    adam_vendorize_add_target("${_vendorize}"
      LIBRARY ${_rtl}
      BINARY_DIR "${_binary_dir}/vendorize"
    )
    adam_util_add_deps(${_vendorize} ${_vunit} ${_verilator})
  endif()

  adam_util_any_in_list(_in_all ADAM_TARGETS ${_NAME} all)
  if(_in_all)
    set(_all ALL)
  endif()

  add_custom_target(${_NAME} ${_all})

  adam_util_add_deps(${_NAME}
    ${_software} ${_vendorize} ${_vunit} ${_verilator} ${_vivado})
endfunction()
