set(APB_SOURCE_DIR "${CMAKE_SOURCE_DIR}/third_party/apb")

adam_git_submodule_ensure("${APB_SOURCE_DIR}" RECURSIVE)

adam_sv_add_library(apb_rtl
  DEPENDS
    common_cells_rtl
  BASE_DIR
    "${APB_SOURCE_DIR}/src"
  INCLUDES
    ../include
  SOURCES
    # Level 0
    apb_pkg.sv
    # Level 1
    apb_intf.sv
    # Level 2
    apb_err_slv.sv
    apb_regs.sv
    apb_cdc.sv
    apb_demux.sv
)

adam_sv_add_library(apb_bhv
  DEPENDS
    apb_rtl
    common_cells_rtl
    common_verification_bhv
  BASE_DIR
    "${APB_SOURCE_DIR}/src"
  INCLUDES
    ../include
  SOURCES
    apb_test.sv
)
