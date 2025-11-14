add_subdirectory(Binary)
add_subdirectory(HAL)
add_subdirectory(Tensor)

if(ADAM_ENABLE_TFLM)
  add_subdirectory(TFLMExt)
endif()
