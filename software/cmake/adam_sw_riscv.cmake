add_library(riscv_base OBJECT
  "${CMAKE_SOURCE_DIR}/crt0.S"
)

target_compile_options(riscv_base PUBLIC
  -g
  -O3
  -mcmodel=medany
  -static
  -Wall
  -Wextra
  -fdata-sections
  -ffunction-sections
  # -fstrict-volatile-bitfields

  $<$<COMPILE_LANGUAGE:CXX>:
    -fno-exceptions
    -fno-rtti
    -fno-threadsafe-statics
    -fno-use-cxa-atexit
  >
)

target_link_options(riscv_base PUBLIC
  "-L${CMAKE_SOURCE_DIR}"
  -Wl,--gc-sections
  -nostdlib
)

# =============================================================================

add_library(riscv_stdlib INTERFACE)

target_link_libraries(riscv_stdlib INTERFACE riscv_base)

target_link_libraries(riscv_stdlib INTERFACE
  stdc++ supc++ c_nano m gcc nosys)

target_link_options(riscv_stdlib INTERFACE
  -Wl,-u,_printf_float
  -Wl,-u,_scanf_float
)

# =============================================================================

function(_add_riscv_interface tgt)
  set(_flags ${ARGN})

  add_library(${tgt} INTERFACE)
  target_link_libraries(${tgt} INTERFACE riscv_base)
  target_compile_options(${tgt} INTERFACE ${_flags})
  target_link_options(${tgt} INTERFACE ${_flags})
endfunction()

_add_riscv_interface(rv32i    -march=rv32i_zicsr    -mabi=ilp32)
_add_riscv_interface(rv32im   -march=rv32im_zicsr   -mabi=ilp32)
_add_riscv_interface(rv32imc  -march=rv32imc_zicsr  -mabi=ilp32)
_add_riscv_interface(rv32imfc -march=rv32imfc_zicsr -mabi=ilp32f)
