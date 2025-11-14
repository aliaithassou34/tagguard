set(IREE_SOURCE_DIR "${CMAKE_SOURCE_DIR}/third_party/iree")
set(IREE_PREFIX_DIR "${CMAKE_BINARY_DIR}/third_party/iree")
set(IREE_BINARY_DIR "${IREE_PREFIX_DIR}/build")

# Needed by software project
set(IREE_HOST_BIN_DIR "${CMAKE_BINARY_DIR}/install/bin")

if(ADAM_ENABLE_IREE)
  adam_git_submodule_ensure("${IREE_SOURCE_DIR}" RECURSIVE)

  ExternalProject_Add(iree
    PREFIX ${IREE_PREFIX_DIR}
    SOURCE_DIR ${IREE_SOURCE_DIR}
    BINARY_DIR ${IREE_BINARY_DIR}
    CMAKE_GENERATOR Ninja
    CMAKE_ARGS
      -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
      -DCMAKE_CXX_COMPILER=clang++
      -DCMAKE_CXX_COMPILER_LAUNCHER=${CMAKE_CXX_COMPILER_LAUNCHER}
      -DCMAKE_C_COMPILER=clang
      -DCMAKE_C_COMPILER_LAUNCHER=${CMAKE_C_COMPILER_LAUNCHER}
      -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
      -DIREE_BUILD_PYTHON_BINDINGS=ON
      -DIREE_ENABLE_ASSERTIONS=ON
      -DIREE_ENABLE_LLD=ON
      -DIREE_ENABLE_SPLIT_DWARF=ON
      -DIREE_ENABLE_THIN_ARCHIVES=ON
      -DPython3_EXECUTABLE=${Python3_EXECUTABLE}
    BUILD_COMMAND ${CMAKE_COMMAND} --build . --parallel ${ADAM_JOBS}
    USES_TERMINAL_CONFIGURE 1
    USES_TERMINAL_BUILD 1
  )

  ExternalProject_Add_Step(iree pip
    COMMAND ${Python3_EXECUTABLE} -m pip install -r
      "${IREE_SOURCE_DIR}/runtime/bindings/python/iree/runtime/build_requirements.txt"
    DEPENDEES download
    DEPENDERS configure
  )

  set_property(TARGET iree PROPERTY JOB_POOL_UTILITY heavy)
endif()
