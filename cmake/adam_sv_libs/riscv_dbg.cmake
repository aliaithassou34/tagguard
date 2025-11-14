set(RISCV_DBG_SOURCE_DIR "${CMAKE_SOURCE_DIR}/third_party/riscv-dbg")

adam_git_submodule_ensure("${RISCV_DBG_SOURCE_DIR}" RECURSIVE
  PATCHES
    "${CMAKE_SOURCE_DIR}/patches/riscv-dbg/0001-majbthrd-s-PR-remedy-endless-feedback-loop-102.patch"
)

adam_sv_add_library(riscv_dbg_rtl
  DEPENDS
    common_cells_rtl
    tech_cells_generic_rtl
  BASE_DIR
    "${RISCV_DBG_SOURCE_DIR}"
  SOURCES
    src/dm_pkg.sv
    debug_rom/debug_rom.sv
    debug_rom/debug_rom_one_scratch.sv
    src/dm_csrs.sv
    src/dm_mem.sv
    src/dm_top.sv
    src/dm_obi_top.sv
    src/dmi_cdc.sv
    src/dmi_jtag.sv
    src/dmi_jtag_tap.sv
    src/dm_sba.sv
)
