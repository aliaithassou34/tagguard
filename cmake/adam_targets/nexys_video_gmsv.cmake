adam_target(nexys_video_gmsv
  TOP adam_nexys_video
  PART xc7a200tsbg484-1
  APP tflm_lenet
  DEPENDS
    adam_rtl
    adam_core_gmsv_rtl
    adam_core_ibex_rtl
  DEFINITIONS
    ADAM_CORE_CPU=adam_core_gmsv
    ADAM_CORE_LPCPU=adam_core_ibex
    ADAM_ROM=tflm_lenet
  SOURCES
    bhv/adam_clk_gate.sv
    fpga/adam_nexys_video.sv
  CONSTRAINTS
    "${CMAKE_SOURCE_DIR}/fpga/adam_nexys_video.xdc"
  CFG_ARGS
    --en-debug False
    --mem-size 0,524288
)
