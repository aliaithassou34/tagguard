file(GLOB GEMMINI_SV_SRCS
  "${CMAKE_CURRENT_SOURCE_DIR}/src/*.c"
  "${CMAKE_CURRENT_SOURCE_DIR}/src/*.s"
)

adam_sw_app(gemmini_sv
  SOURCES
    ${GEMMINI_SV_SRCS}
  INCLUDE
    "${CMAKE_CURRENT_SOURCE_DIR}/inc"
  LIBRARIES
    ldscript
    rv32imc
    riscv_stdlib
    ral
)
