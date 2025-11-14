set(TECH_CELLS_GENERIC_SOURCE_DIR
  "${CMAKE_SOURCE_DIR}/third_party/tech_cells_generic")

adam_git_submodule_ensure("${TECH_CELLS_GENERIC_SOURCE_DIR}" RECURSIVE)

adam_sv_add_library(tech_cells_generic_rtl
  BASE_DIR
    "${TECH_CELLS_GENERIC_SOURCE_DIR}/src"
  SOURCES
    rtl/tc_clk.sv
    deprecated/cluster_clk_cells.sv
    deprecated/pulp_clk_cells.sv
)
