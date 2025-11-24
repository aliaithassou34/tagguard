adam_target(nexys_video_cv32e40x
  TOP adam_nexys_video
  PART xc7a200tsbg484-1
  DEPENDS
    adam_rtl
    adam_core_cv32e40x_rtl
    adam_core_ibex_rtl
  DEFINITIONS
    ADAM_CORE_CPU=adam_core_cv32e40x
    ADAM_CORE_LPCPU=adam_core_ibex
    ADAM_ROM=adam_mem
  SOURCES
    bhv/adam_clk_gate.sv
    fpga/adam_nexys_video.sv
  CONSTRAINTS
    "${CMAKE_SOURCE_DIR}/fpga/adam_nexys_video.xdc"
)
