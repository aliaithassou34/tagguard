file(GLOB BOOTLOADER_SRCS
  ${CMAKE_CURRENT_SOURCE_DIR}/src/*.c
  ${CMAKE_CURRENT_SOURCE_DIR}/src/*.s
)

adam_add_executable(bootloader ${BOOTLOADER_SRCS})

target_include_directories(bootloader PRIVATE
  ${ADAM_ATGEN_DIR}
  ${CMAKE_CURRENT_SOURCE_DIR}/inc
)

target_link_libraries(bootloader PRIVATE ldscript rv32i ral)
