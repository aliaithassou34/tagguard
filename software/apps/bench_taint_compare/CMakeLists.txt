file(GLOB BENCH_TAINT_COMPARE_SRCS
  "${CMAKE_CURRENT_SOURCE_DIR}/src/*.c"
  "${CMAKE_CURRENT_SOURCE_DIR}/src/*.s"
)

adam_sw_app(bench_taint_compare
  SOURCES
    ${BENCH_TAINT_COMPARE_SRCS}
  LIBRARIES
    ldscript
    rv32imc
    riscv_stdlib
    ral
    hal
)

target_compile_definitions(bench_taint_compare PRIVATE DIFT)
