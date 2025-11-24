adam_target(hawkeye
  TOP
    adam_top
  DEPENDS
    adam_rtl
    adam_core_ibex_rtl
  DEFINITIONS
    ADAM_CORE_CPU=adam_core_ibex
    ADAM_CORE_LPCPU=adam_core_ibex
    ADAM_ROM=adam_mem
  SOURCES
    bhv/adam_clk_gate.sv
)

