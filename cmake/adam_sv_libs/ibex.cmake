set(IBEX_SOURCE_DIR "${CMAKE_SOURCE_DIR}/third_party/ibex")
set(IBEX_BINARY_DIR "${CMAKE_BINARY_DIR}/third_party/ibex")

set(IBEX_BASE_DIR "${IBEX_BINARY_DIR}/src/")

set(IBEX_INCLUDES
  lowrisc_dv_crypto_prince_ref_0.1
  lowrisc_dv_dv_fcov_macros_0
  lowrisc_dv_secded_enc_0
  lowrisc_prim_util_get_scramble_params_0/rtl
  lowrisc_prim_util_memload_0/rtl
  lowrisc_dv_scramble_model_0
  lowrisc_prim_assert_0.1/rtl
  lowrisc_ibex_ibex_core_0.1/rtl
)

set(IBEX_SOURCES
  lowrisc_ibex_ibex_pkg_0.1/rtl/ibex_pkg.sv
  lowrisc_prim_abstract_prim_pkg_0.1/prim_pkg.sv
  lowrisc_prim_ram_1p_pkg_0/rtl/prim_ram_1p_pkg.sv
  lowrisc_prim_cipher_pkg_0.1/rtl/prim_cipher_pkg.sv
  lowrisc_prim_generic_buf_0/rtl/prim_generic_buf.sv
  lowrisc_prim_generic_clock_gating_0/rtl/prim_generic_clock_gating.sv
  lowrisc_prim_generic_flop_0/rtl/prim_generic_flop.sv
  lowrisc_prim_secded_0.1/rtl/prim_secded_pkg.sv
  lowrisc_prim_secded_0.1/rtl/prim_secded_22_16_dec.sv
  lowrisc_prim_secded_0.1/rtl/prim_secded_22_16_enc.sv
  lowrisc_prim_secded_0.1/rtl/prim_secded_28_22_dec.sv
  lowrisc_prim_secded_0.1/rtl/prim_secded_28_22_enc.sv
  lowrisc_prim_secded_0.1/rtl/prim_secded_39_32_dec.sv
  lowrisc_prim_secded_0.1/rtl/prim_secded_39_32_enc.sv
  lowrisc_prim_secded_0.1/rtl/prim_secded_64_57_dec.sv
  lowrisc_prim_secded_0.1/rtl/prim_secded_64_57_enc.sv
  lowrisc_prim_secded_0.1/rtl/prim_secded_72_64_dec.sv
  lowrisc_prim_secded_0.1/rtl/prim_secded_72_64_enc.sv
  lowrisc_prim_secded_0.1/rtl/prim_secded_hamming_22_16_dec.sv
  lowrisc_prim_secded_0.1/rtl/prim_secded_hamming_22_16_enc.sv
  lowrisc_prim_secded_0.1/rtl/prim_secded_hamming_39_32_dec.sv
  lowrisc_prim_secded_0.1/rtl/prim_secded_hamming_39_32_enc.sv
  lowrisc_prim_secded_0.1/rtl/prim_secded_hamming_72_64_dec.sv
  lowrisc_prim_secded_0.1/rtl/prim_secded_hamming_72_64_enc.sv
  lowrisc_prim_secded_0.1/rtl/prim_secded_hamming_76_68_dec.sv
  lowrisc_prim_secded_0.1/rtl/prim_secded_hamming_76_68_enc.sv
  lowrisc_prim_secded_0.1/rtl/prim_secded_inv_22_16_dec.sv
  lowrisc_prim_secded_0.1/rtl/prim_secded_inv_22_16_enc.sv
  lowrisc_prim_secded_0.1/rtl/prim_secded_inv_28_22_dec.sv
  lowrisc_prim_secded_0.1/rtl/prim_secded_inv_28_22_enc.sv
  lowrisc_prim_secded_0.1/rtl/prim_secded_inv_39_32_dec.sv
  lowrisc_prim_secded_0.1/rtl/prim_secded_inv_39_32_enc.sv
  lowrisc_prim_secded_0.1/rtl/prim_secded_inv_64_57_dec.sv
  lowrisc_prim_secded_0.1/rtl/prim_secded_inv_64_57_enc.sv
  lowrisc_prim_secded_0.1/rtl/prim_secded_inv_72_64_dec.sv
  lowrisc_prim_secded_0.1/rtl/prim_secded_inv_72_64_enc.sv
  lowrisc_prim_secded_0.1/rtl/prim_secded_inv_hamming_22_16_dec.sv
  lowrisc_prim_secded_0.1/rtl/prim_secded_inv_hamming_22_16_enc.sv
  lowrisc_prim_secded_0.1/rtl/prim_secded_inv_hamming_39_32_dec.sv
  lowrisc_prim_secded_0.1/rtl/prim_secded_inv_hamming_39_32_enc.sv
  lowrisc_prim_secded_0.1/rtl/prim_secded_inv_hamming_72_64_dec.sv
  lowrisc_prim_secded_0.1/rtl/prim_secded_inv_hamming_72_64_enc.sv
  lowrisc_prim_secded_0.1/rtl/prim_secded_inv_hamming_76_68_dec.sv
  lowrisc_prim_secded_0.1/rtl/prim_secded_inv_hamming_76_68_enc.sv
  lowrisc_prim_xilinx_buf_0/rtl/prim_xilinx_buf.sv
  lowrisc_prim_xilinx_clock_gating_0/rtl/prim_xilinx_clock_gating.sv
  lowrisc_prim_xilinx_clock_mux2_0/rtl/prim_xilinx_clock_mux2.sv
  lowrisc_prim_xilinx_flop_0/rtl/prim_xilinx_flop.sv
  lowrisc_ibex_ibex_icache_0.1/rtl/ibex_icache.sv
  lowrisc_prim_abstract_buf_0/prim_buf.sv
  lowrisc_prim_abstract_clock_gating_0/prim_clock_gating.sv
  lowrisc_prim_abstract_flop_0/prim_flop.sv
  lowrisc_prim_cipher_0/rtl/prim_subst_perm.sv
  lowrisc_prim_cipher_0/rtl/prim_present.sv
  lowrisc_prim_cipher_0/rtl/prim_prince.sv
  lowrisc_prim_generic_clock_mux2_0/rtl/prim_generic_clock_mux2.sv
  lowrisc_prim_generic_ram_1p_0/rtl/prim_generic_ram_1p.sv
  lowrisc_prim_lfsr_0.1/rtl/prim_lfsr.sv
  lowrisc_prim_util_0.1/rtl/prim_util_pkg.sv
  lowrisc_prim_abstract_clock_mux2_0/prim_clock_mux2.sv
  lowrisc_prim_badbit_ram_1p_0/prim_badbit_ram_1p.sv
  lowrisc_prim_onehot_check_0/rtl/prim_onehot_check.sv
  lowrisc_ibex_ibex_core_0.1/rtl/ibex_alu.sv
  lowrisc_ibex_ibex_core_0.1/rtl/ibex_branch_predict.sv
  lowrisc_ibex_ibex_core_0.1/rtl/ibex_compressed_decoder.sv
  lowrisc_ibex_ibex_core_0.1/rtl/ibex_controller.sv
  lowrisc_ibex_ibex_core_0.1/rtl/ibex_cs_registers.sv
  lowrisc_ibex_ibex_core_0.1/rtl/ibex_csr.sv
  lowrisc_ibex_ibex_core_0.1/rtl/ibex_counter.sv
  lowrisc_ibex_ibex_core_0.1/rtl/ibex_decoder.sv
  lowrisc_ibex_ibex_core_0.1/rtl/ibex_ex_block.sv
  lowrisc_ibex_ibex_core_0.1/rtl/ibex_fetch_fifo.sv
  lowrisc_ibex_ibex_core_0.1/rtl/ibex_id_stage.sv
  lowrisc_ibex_ibex_core_0.1/rtl/ibex_if_stage.sv
  lowrisc_ibex_ibex_core_0.1/rtl/ibex_load_store_unit.sv
  lowrisc_ibex_ibex_core_0.1/rtl/ibex_multdiv_fast.sv
  lowrisc_ibex_ibex_core_0.1/rtl/ibex_multdiv_slow.sv
  lowrisc_ibex_ibex_core_0.1/rtl/ibex_prefetch_buffer.sv
  lowrisc_ibex_ibex_core_0.1/rtl/ibex_pmp.sv
  lowrisc_ibex_ibex_core_0.1/rtl/ibex_wb_stage.sv
  lowrisc_ibex_ibex_core_0.1/rtl/ibex_dummy_instr.sv
  lowrisc_ibex_ibex_core_0.1/rtl/ibex_core.sv
  lowrisc_prim_abstract_ram_1p_0/prim_ram_1p.sv
  lowrisc_prim_ram_1p_adv_0.1/rtl/prim_ram_1p_adv.sv
  lowrisc_prim_ram_1p_scr_0.1/rtl/prim_ram_1p_scr.sv
  lowrisc_ibex_ibex_top_0.1/rtl/ibex_register_file_ff.sv
  lowrisc_ibex_ibex_top_0.1/rtl/ibex_register_file_fpga.sv
  lowrisc_ibex_ibex_top_0.1/rtl/ibex_register_file_latch.sv
  lowrisc_ibex_ibex_top_0.1/rtl/ibex_lockstep.sv
  lowrisc_ibex_ibex_top_0.1/rtl/ibex_top.sv
)

list(TRANSFORM IBEX_INCLUDES PREPEND "${IBEX_BASE_DIR}")
list(TRANSFORM IBEX_SOURCES PREPEND "${IBEX_BASE_DIR}")

adam_git_submodule_ensure("${IBEX_SOURCE_DIR}" RECURSIVE)

file(MAKE_DIRECTORY "${IREE_BINARY_DIR}")

adam_util_add_pip(ibex_pip "${IBEX_SOURCE_DIR}/python-requirements.txt")

adam_util_add_stamped_target(ibex_build
  COMMAND fusesoc --cores-root "${IBEX_SOURCE_DIR}" run --target=lint --setup
    --build-root "${IBEX_BINARY_DIR}" lowrisc:ibex:ibex_top
  DEPENDS ibex_pip
  BYPRODUCTS ${IBEX_SOURCES}
  VERBATIM
  USES_TERMINAL
)

adam_sv_add_library(ibex_rtl
  DEPENDS ibex_build
  BASE_DIR "${IBEX_BASE_DIR}"
  INCLUDES ${IBEX_INCLUDES}
  SOURCES ${IBEX_SOURCES}
)
