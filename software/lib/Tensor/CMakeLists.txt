add_library(tensor OBJECT
    Conv2D.cpp
    Gemm.cpp
    Shape.cpp
    Tensor.cpp
    TiledConv2D.cpp
    TiledGemm.cpp
)
target_include_directories(tensor PUBLIC "${CMAKE_SOURCE_DIR}/include")
target_link_libraries(tensor PUBLIC rv32imc)
