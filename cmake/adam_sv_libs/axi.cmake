set(AXI_SOURCE_DIR "${CMAKE_SOURCE_DIR}/third_party/axi")

adam_git_submodule_ensure("${AXI_SOURCE_DIR}" RECURSIVE
  PATCHES
    "${CMAKE_SOURCE_DIR}/patches/axi/0001-Fix-Questa-Typedef.patch"
)

adam_sv_add_library(axi_rtl
  DEPENDS
    common_cells_rtl
  BASE_DIR
    "${AXI_SOURCE_DIR}/src"
  INCLUDES
    ../include
  SOURCES
    # Level 0
    axi_pkg.sv
    # Level 1
    axi_intf.sv
    # Level 2
    axi_atop_filter.sv
    axi_burst_splitter.sv
    axi_cdc_dst.sv
    axi_cdc_src.sv
    axi_cut.sv
    axi_delayer.sv
    axi_demux.sv
    axi_dw_downsizer.sv
    axi_dw_upsizer.sv
    axi_fifo.sv
    axi_id_remap.sv
    axi_id_prepend.sv
    axi_isolate.sv
    axi_join.sv
    axi_lite_demux.sv
    axi_lite_join.sv
    axi_lite_lfsr.sv
    axi_lite_mailbox.sv
    axi_lite_mux.sv
    axi_lite_regs.sv
    axi_lite_to_apb.sv
    axi_lite_to_axi.sv
    axi_modify_address.sv
    axi_mux.sv
    axi_serializer.sv
    axi_throttle.sv
    # axi_to_mem.sv
    # Level 3
    axi_cdc.sv
    axi_err_slv.sv
    axi_dw_converter.sv
    axi_id_serialize.sv
    axi_lfsr.sv
    axi_multicut.sv
    axi_to_axi_lite.sv
    axi_to_mem_banked.sv
    axi_to_mem_interleaved.sv
    axi_to_mem_split.sv
    # Level 4
    axi_iw_converter.sv
    axi_lite_xbar.sv
    axi_xbar.sv
    # Level 5
    axi_xp.sv
)

adam_sv_add_library(axi_bhv
  DEPENDS
    axi_rtl
    common_cells_rtl
    common_verification_bhv
  BASE_DIR
    "${AXI_SOURCE_DIR}/src"
  SOURCES
    axi_dumper.sv
    axi_sim_mem.sv
    axi_test.sv
)
