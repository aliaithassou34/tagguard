adam_sv_add_library(hawkeye_rtl
  DEPENDS
    adam_rtl
    adam_core_cv32e40p_rtl
  DEFINITIONS
    ADAM_CORE_CPU=adam_core_cv32e40p
    ADAM_CORE_LPCPU=adam_core_cv32e40p
    ADAM_ROM=bootloader_rom
  SOURCES
    bhv/adam_clk_gate.sv
    work/hawkeye/cmake/bootloader/bootloader_rom.sv
)

adam_sv_add_library(hawkeye_bhv
  DEPENDS
    hawkeye_rtl
    adam_bhv
)
