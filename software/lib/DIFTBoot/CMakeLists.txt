add_library(dift_boot INTERFACE)

target_sources(dift_boot INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/src/adam_dift_boot.c"
  "${CMAKE_CURRENT_SOURCE_DIR}/src/adam_dift_handler.s"
  "${CMAKE_CURRENT_SOURCE_DIR}/src/adam_dift_trusted.s"
)

target_include_directories(dift_boot INTERFACE "${CMAKE_SOURCE_DIR}/include")

target_compile_definitions(dift_boot INTERFACE
  # Trusted startup enables UART0 hardware auto-taint (DTSR bit 4) before main.
  ADAM_DIFT_BOOT_DTSR=0x10u
)

target_link_libraries(dift_boot INTERFACE riscv_base rv32imc ral)
