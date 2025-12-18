# toolchain ===================================================================

if(NOT DEFINED CMAKE_TOOLCHAIN_FILE)
  include("${CMAKE_SOURCE_DIR}/cmake/toolchain.cmake")
endif()

if (NOT DEFINED ADAM_CFG OR ADAM_CFG STREQUAL "")
  message(FATAL_ERROR "ADAM_CFG must be defined before configuring.")
endif()

# project =====================================================================

cmake_minimum_required(VERSION 3.15)

project(adam_software LANGUAGES C CXX ASM)

# adam ========================================================================

set(ADAM_CFG "${ADAM_CFG}" CACHE FILEPATH
  "ADAM configuration file")
set(ADAM_SOURCE_DIR "${CMAKE_SOURCE_DIR}/.."
  CACHE FILEPATH "Root directory of the ADAM project")
set(ADAM_SOFTWARE_TARGETS "all" CACHE STRING
  "Semicolon-separated list of software targets to build")
option(ADAM_ENABLE_TFLM "Enable TFLM integration" OFF)
option(ADAM_ENABLE_IREE "Enable IREE integration" OFF)

if(CMAKE_SYSTEM_PROCESSOR MATCHES "riscv32")
  set(ADAM_ELF_FORMAT "elf32-littleriscv")
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "riscv64")
  set(ADAM_ELF_FORMAT "elf64-littleriscv")
else()
  message(FATAL_ERROR "Unsupported architecture: ${CMAKE_SYSTEM_PROCESSOR}")
endif()

# cmake =======================================================================

list(APPEND CMAKE_MODULE_PATH
  "${ADAM_SOURCE_DIR}/cmake"
  "${CMAKE_SOURCE_DIR}/cmake"
)

find_package(Git REQUIRED)
find_package(Python3 REQUIRED COMPONENTS Interpreter)
find_program(ADAM_EXECUTABLE REQUIRED NAMES adam)

include(adam_util)
include(adam_git)

include(adam_sw_util)
include(adam_sw_app)

include(adam_sw_ldscript)
include(adam_sw_riscv)
include(adam_sw_blob)

if(ADAM_ENABLE_TFLM)
  include(adam_sw_tflm)
endif()

if(ADAM_ENABLE_IREE)
  include(adam_sw_iree)
  include(adam_sw_iree_vmfb)
endif()

adam_util_add_ral(ral
  CFG "${ADAM_CFG}"
  OUTPUT_DIR "${CMAKE_BINARY_DIR}/ral"
)

add_subdirectory(lib)
add_subdirectory(apps)

# =============================================================================

add_custom_target(adam_software ALL)
adam_util_add_deps(adam_software ${ADAM_SOFTWARE_TARGETS})
