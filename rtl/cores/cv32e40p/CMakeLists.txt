adam_sv_add_library(adam_core_cv32e40p_rtl
  DEPENDS
    adam_rtl
    cv32e40p_rtl
  SOURCES
    adam_core_cv32e40p.sv
    cv32e40p_clock_gate.sv
)
