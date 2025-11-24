if (ADAM_ENABLE_GMSV)
  set(GMSV_SOURCE_DIR "${CMAKE_SOURCE_DIR}/third_party/gemmini-sv")

  adam_git_submodule_ensure("${GMSV_SOURCE_DIR}" RECURSIVE)

  adam_sv_add_library(gmsv_rtl
    BASE_DIR
      "${GMSV_SOURCE_DIR}/rtl"
    SOURCES
      gmsv_pkg.sv
      gmsv_isa_pkg.sv
      gmsv_ram.sv
      gmsv_shifter.sv
      gmsv_mac.sv
      gmsv_pe.sv
      gmsv_tile.sv
      gmsv_mesh.sv
      gmsv_mesh_decoupled.sv
      gmsv_queue.sv
      gmsv_flow.sv
      gmsv_flow_cut.sv
      gmsv_flow_pass.sv
      gmsv_flow_skid.sv
      gmsv_req_rsp_demux.sv
      gmsv_req_rsp_mux.sv
      gmsv_req_rsp_xbar.sv
      gmsv_csr.sv
      gmsv_dma_aw_ar.sv
      gmsv_dma_controller.sv
      gmsv_dma_w_r.sv
      gmsv_dma.sv
      gmsv_matmul.sv
      gmsv_matmul_loader.sv
      gmsv_matmul_storer.sv
      gmsv_matmul_controller.sv
      gmsv_transposer.sv
      gmsv_spad_bank.sv
      gmsv_spad.sv
      gmsv_decoder.sv
      gmsv.sv
  )
endif()
