adam_target(hawkeye
  TOP adam_top
  APP hawkeye
  DEPENDS
    adam_rtl
    adam_core_ibex_rtl
  DEFINITIONS
    ADAM_CORE_CPU=adam_core_ibex
    ADAM_CORE_LPCPU=adam_core_ibex
    ADAM_ROM=hawkeye
  SOURCES
    bhv/adam_clk_gate.sv
  CFG_ARGS
    --en-debug False
    --mem-size 0,1048576
    --no-hsps 1
)

