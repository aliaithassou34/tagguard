file(GLOB KWS_SRCS
  "${CMAKE_CURRENT_SOURCE_DIR}/src/*.c"
  "${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp"
  "${CMAKE_CURRENT_SOURCE_DIR}/src/*.s"
)

adam_sw_app(tflm_kws
  SOURCES
    ${KWS_SRCS}
  INCLUDE
    "${CMAKE_CURRENT_SOURCE_DIR}/inc"
  LIBRARIES
    ldscript
    rv32imc
    riscv_stdlib
    tflm
    ral
    hal
    tflm_ext
)
