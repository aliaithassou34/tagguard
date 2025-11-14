adam_sv_add_library(default_rtl
  DEPENDS
    adam_rtl
    adam_core_cv32e40p_rtl
    adam_core_ibex_rtl
  DEFINITIONS
    ADAM_CORE_CPU=adam_core_cv32e40p
    ADAM_CORE_LPCPU=adam_core_ibex
    ADAM_ROM=bootloader_rom
  SOURCES
    work/default/cmake/bootloader/bootloader_rom.sv
)

adam_sv_add_library(default_bhv
  DEPENDS
    default_rtl
    adam_bhv
)
