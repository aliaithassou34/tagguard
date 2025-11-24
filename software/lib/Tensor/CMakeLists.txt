add_library(tensor OBJECT
    Shape.cpp
)
target_include_directories(tensor PUBLIC "${CMAKE_SOURCE_DIR}/include")
target_link_libraries(tensor PUBLIC rv32imc)
