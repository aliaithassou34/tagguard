set(CPPUTEST_SOURCE_DIR "${ADAM_SOURCE_DIR}/third_party/cpputest")
set(CPPUTEST_BINARY_DIR "${CMAKE_BINARY_DIR}/third_party/cpputest")

adam_git_submodule_ensure("${CPPUTEST_SOURCE_DIR}" RECURSIVE)

set(CPPUTEST_MEM_LEAK_DETECTION_DISABLED ON CACHE BOOL "" FORCE)

add_subdirectory("${CPPUTEST_SOURCE_DIR}" "${CPPUTEST_BINARY_DIR}")

target_link_libraries(CppUTest PRIVATE riscv_base)

add_library(cpputest ALIAS CppUTest)
