adam_sv_add_library(adam_core_cv32e40x_rtl
  DEPENDS
    adam_rtl
    cv32e40x_rtl
  SOURCES
    adam_core_cv32e40x.sv
    cv32e40x_clock_gate.sv
)
