file(GLOB DIFT_BRANCH_EMULATE_SRCS
  "${CMAKE_CURRENT_SOURCE_DIR}/src/*.c"
  "${CMAKE_CURRENT_SOURCE_DIR}/src/*.s"
)

adam_sw_app(dift_branch_emulate
  SOURCES
    ${DIFT_BRANCH_EMULATE_SRCS}
  LIBRARIES
    ldscript
    rv32imc
    riscv_stdlib
)

target_compile_definitions(dift_branch_emulate PRIVATE DIFT)