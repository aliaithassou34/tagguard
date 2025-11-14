add_library(tflm_ext OBJECT GmsvConv.cpp)
target_include_directories(tflm_ext PUBLIC "${CMAKE_SOURCE_DIR}/include")
target_link_libraries(tflm_ext PUBLIC tflm tensor rv32imc)
