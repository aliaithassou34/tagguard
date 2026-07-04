file(GLOB DIFT_CWE_134_FMT_COTS_SRCS
  "${CMAKE_CURRENT_SOURCE_DIR}/src/*.c"
  "${CMAKE_CURRENT_SOURCE_DIR}/src/*.s"
)

adam_sw_app(dift_cwe_134_fmt_cots
  SOURCES
    ${DIFT_CWE_134_FMT_COTS_SRCS}
  LIBRARIES
    ldscript
    rv32imc
    riscv_stdlib
    ral
    hal
    dift_boot
)

target_compile_definitions(dift_cwe_134_fmt_cots PRIVATE
  ADAM_DIFT_BOOT_TPR=0x0000A8A2u
  ADAM_DIFT_BOOT_TCR=0x00200018u
  ADAM_DIFT_DEFAULT_EMULATE=0u
  ADAM_DIFT_USE_PROTECTED=1u
)
