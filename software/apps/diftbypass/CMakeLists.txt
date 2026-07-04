file(GLOB DIFTBYPASS_SRCS
  "${CMAKE_CURRENT_SOURCE_DIR}/src/*.c"
  "${CMAKE_CURRENT_SOURCE_DIR}/src/*.s"
)

adam_sw_app(diftbypass
  SOURCES
    ${DIFTBYPASS_SRCS}
  LIBRARIES
    ldscript
    rv32imc
    riscv_stdlib
    ral
    hal
)

target_compile_definitions(diftbypass PRIVATE DIFT)
