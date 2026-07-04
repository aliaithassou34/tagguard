file(GLOB DIFT_MMIO_GUARD_SRCS
  "${CMAKE_CURRENT_SOURCE_DIR}/src/*.c"
  "${CMAKE_CURRENT_SOURCE_DIR}/src/*.s"
)

adam_sw_app(dift_mmio_guard
  SOURCES
    ${DIFT_MMIO_GUARD_SRCS}
  LIBRARIES
    ldscript
    rv32imc
    riscv_stdlib
    ral
    hal
)

target_compile_definitions(dift_mmio_guard PRIVATE DIFT)
