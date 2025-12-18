add_library(hal OBJECT
  gpio.c
  memset.c
  spi.c
  syscalls.c
  timer.c
  uart.c
)

target_include_directories(hal PUBLIC "${CMAKE_SOURCE_DIR}/include")

target_link_libraries(hal PRIVATE riscv_stdlib rv32imc ral)
