file(GLOB IREE_VEC_MUL_SRCS
  "${CMAKE_CURRENT_SOURCE_DIR}/src/*.c"
  "${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp"
  "${CMAKE_CURRENT_SOURCE_DIR}/src/*.s"
)

adam_sw_iree_vmfb(_model
  SOURCE "${CMAKE_CURRENT_SOURCE_DIR}/vec_mul.mlir"
  IDENTIFIER vec_mul_vmfb
  FLAGS
    --iree-hal-target-device=local
    --iree-hal-local-target-device-backends=llvm-cpu
    --iree-llvmcpu-target-triple=riscv32-pc-linux-elf
    --iree-llvmcpu-target-cpu-features=+m,+f
    --iree-llvmcpu-target-abi=ilp32
    --iree-llvmcpu-debug-symbols=false
    --iree-vm-bytecode-module-strip-source-map=true
    --iree-vm-emit-polyglot-zip=false
    "--iree-hal-executable-object-search-path=${IREE_BINARY_DIR}"
)

adam_sw_app(iree_vec_mul
  SOURCES
    ${IREE_VEC_MUL_SRCS}
  INCLUDE
    "${CMAKE_CURRENT_SOURCE_DIR}/inc"
    ${CMAKE_CURRENT_BINARY_DIR}
  LIBRARIES
    rv32imc
    iree::base
    iree::hal
    iree::hal::drivers::local_sync::sync_driver
    iree::hal::local
    iree::hal::local::loaders::embedded_elf_loader
    iree::modules::hal
    iree::vm
    iree::vm::bytecode::module
    _model
    riscv_stdlib
    hal
)
