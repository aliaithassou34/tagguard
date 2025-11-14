file(GLOB HAWKEYE_SRCS
  "${CMAKE_CURRENT_SOURCE_DIR}/src/*.c"
  "${CMAKE_CURRENT_SOURCE_DIR}/src/*.s"
)

adam_add_executable(hawkeye ${HAWKEYE_SRCS})

target_include_directories(hawkeye PRIVATE
  ${ADAM_ATGEN_DIR}
  "${CMAKE_CURRENT_SOURCE_DIR}/inc"
)

target_link_libraries(hawkeye PRIVATE rv32imc)
