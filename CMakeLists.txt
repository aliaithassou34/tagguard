# project =====================================================================

cmake_minimum_required(VERSION 3.15)

project(adam)

# cmake =======================================================================

set(CMAKE_BUILD_TYPE RelWithDebInfo CACHE STRING
  "Build type")

if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX "${CMAKE_BINARY_DIR}/install" CACHE PATH
    "Install path prefix" FORCE)
endif()

option(USE_CCACHE "Enable ccache for faster rebuilds" ON)

if(USE_CCACHE)
  find_program(CCACHE_PROGRAM ccache)
  if(NOT CCACHE_PROGRAM)
    message(FATAL_ERROR "USE_CCACHE is ON but ccache was not found.")
  endif()

  set(CMAKE_C_COMPILER_LAUNCHER "${CCACHE_PROGRAM}" CACHE STRING
    "Compiler launcher for C files")
  set(CMAKE_CXX_COMPILER_LAUNCHER "${CCACHE_PROGRAM}" CACHE STRING
    "Compiler launcher for C++ files")
endif()

# adam ========================================================================

set(ADAM_SOURCE_DIR ${CMAKE_SOURCE_DIR})
set(ADAM_BUILD_DIR ${CMAKE_BUILD_DIR})

set(ADAM_JOBS 1 CACHE STRING "Number of parallel jobs")

set(ADAM_TARGETS "all" CACHE STRING
  "Semicolon-separated list of hardware targets to build")
set(ADAM_SOFTWARE_TARGETS "all" CACHE STRING
  "Semicolon-separated list of software targets to build")
option(ADAM_ENABLE_VUNIT "Enable VUnit simulation flows" ON)
option(ADAM_ENABLE_VERILATOR "Enable Verilator simulation flows" OFF)
option(ADAM_ENABLE_VIVADO "Enable Vivado bitstream generation" ON)
option(ADAM_ENABLE_VENDORIZE "Enable ADAM vendorization" ON)
option(ADAM_ENABLE_TFLM "Enable TFLM integration" OFF)
option(ADAM_ENABLE_IREE "Enable IREE integration" OFF)

if("${ADAM_SOFTWARE_TARGETS}" MATCHES "^(all|.*tflm.*)$")
  set(ADAM_ENABLE_TFLM ON)
endif()

set_property(GLOBAL PROPERTY JOB_POOLS heavy=1)

# find program ================================================================

find_package(Git REQUIRED)
find_package(Python3 REQUIRED COMPONENTS Interpreter)
find_program(ADAM_EXECUTABLE REQUIRED NAMES adam)

if(ADAM_ENABLE_VUNIT)
  find_program(VSIM_EXECUTABLE REQUIRED NAMES vsim)
endif()

if(ADAM_ENABLE_VERILATOR)
  find_program(VERILATOR_EXECUTABLE REQUIRED NAMES verilator)
endif()

if(ADAM_ENABLE_VIVADO)
  find_program(VIVADO_EXECUTABLE REQUIRED NAMES vivado)
endif()

# =============================================================================

list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")

include(ExternalProject)

include(adam_util)
include(adam_git)
include(adam_sv)

# include(adam_iree)
include(adam_software)
include(adam_vendorize)
include(adam_verilator)
include(adam_vivado)
include(adam_vunit)
include(adam_target)

include(adam_sv_libs/apb)
include(adam_sv_libs/axi)
include(adam_sv_libs/common_cells)
include(adam_sv_libs/common_verification)
include(adam_sv_libs/cv32e40p)
include(adam_sv_libs/cv32e40x)
include(adam_sv_libs/gmsv)
include(adam_sv_libs/ibex)
include(adam_sv_libs/riscv_dbg)
include(adam_sv_libs/tech_cells_generic)

add_subdirectory(docs)
add_subdirectory(rtl)
add_subdirectory(bhv)

# include(adam_targets/basys3)
# include(adam_targets/default)
# include(adam_targets/hawkeye)
include(adam_targets/nexys_video)
# include(adam_targets/nexys_video_cv32e40x)
# include(adam_targets/nexys_video_gmsv)
# include(adam_targets/zybo)

# =============================================================================

foreach(_t IN LISTS ADAM_TARGETS)
  if(NOT TARGET "${_t}" AND NOT "${_t}" STREQUAL "all")
    message(FATAL_ERROR "Required target '${_t}' does not exist.")
  endif()
endforeach()
