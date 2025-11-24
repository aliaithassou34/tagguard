adam_sw_app(test_tensor
  SOURCES
    ../main.cpp
    test_conv2d.cpp
    test_gemm.cpp
    test_tiled_conv2d.cpp
    test_tiled_gemm.cpp
  LIBRARIES
    ldscript
    rv32imc
    riscv_stdlib
    ral
    hal
    tensor
    cpputest
)

add_test(
  NAME test_tensor
  COMMAND "${ADAM_EXECUTABLE}" run gdb
    --emulate --batch --semihost
    --spike-exe "${CMAKE_SPIKE}"
    --openocd-exe "${CMAKE_OPENOCD}"
    --gdb-exe "${CMAKE_GDB}"
    "$<TARGET_FILE:test_tensor>"
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
)
