file(GLOB DIFT_AUTOTAINT_RA_SRCS
  "${CMAKE_CURRENT_SOURCE_DIR}/src/*.c"
  "${CMAKE_CURRENT_SOURCE_DIR}/src/*.s"
)

adam_sw_app(dift_autotaint_ra
  SOURCES
    ${DIFT_AUTOTAINT_RA_SRCS}
  LIBRARIES
    ldscript
    rv32imc
    riscv_stdlib
    ral
    hal
)

target_compile_definitions(dift_autotaint_ra PRIVATE DIFT)
