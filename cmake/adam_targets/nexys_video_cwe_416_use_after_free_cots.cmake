adam_target(nexys_video_cwe_416_use_after_free_cots
  TOP adam_nexys_video
  PART xc7a200tsbg484-1
  APP dift_cwe_416_use_after_free_cots
  DEPENDS
    adam_rtl
    adam_core_cv32e40p_rtl
    adam_core_ibex_rtl
  DEFINITIONS
    ADAM_CORE_CPU=adam_core_cv32e40p
    ADAM_CORE_LPCPU=adam_core_ibex
    ADAM_ROM=dift_cwe_416_use_after_free_cots
    DIFT
  SOURCES
    bhv/adam_clk_gate.sv
    fpga/adam_nexys_video.sv
  CFG_ARGS
    --en-debug False
    --mem-size 0,1048576
  CONSTRAINTS
    "${CMAKE_SOURCE_DIR}/fpga/adam_nexys_video.xdc"
)
