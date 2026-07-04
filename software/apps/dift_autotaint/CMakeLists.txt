file(GLOB DIFT_AUTOTAINT_SRCS
  "${CMAKE_CURRENT_SOURCE_DIR}/src/*.c"
  "${CMAKE_CURRENT_SOURCE_DIR}/src/*.s"
)

adam_sw_app(dift_autotaint
  SOURCES
    ${DIFT_AUTOTAINT_SRCS}
  LIBRARIES
    ldscript
    rv32imc
    riscv_stdlib
    ral
    hal
)

target_compile_definitions(dift_autotaint PRIVATE DIFT)
