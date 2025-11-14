set(COMMON_VERIFICATION_SOURCE_DIR
  "${CMAKE_SOURCE_DIR}/third_party/common_verification")

adam_git_submodule_ensure("${COMMON_VERIFICATION_SOURCE_DIR}" RECURSIVE)

adam_sv_add_library(common_verification_bhv
  BASE_DIR
    "${COMMON_VERIFICATION_SOURCE_DIR}/src"
  SOURCES
    # Level 0
    clk_rst_gen.sv
    rand_id_queue.sv
    rand_stream_mst.sv
    rand_synch_holdable_driver.sv
    rand_verif_pkg.sv
    sim_timeout.sv
    # Level 1
    rand_synch_driver.sv
    # Level 2
    rand_stream_slv.sv
)
