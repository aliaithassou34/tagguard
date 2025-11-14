cmake_minimum_required(VERSION 3.15)

separate_arguments(DEFS)
separate_arguments(INCS)
separate_arguments(SRCS)

# Clean
file(GLOB _entries "*")
if(_entries)
  file(REMOVE_RECURSE ${_entries})
endif()

# Copy sources
file(COPY ${SRCS} DESTINATION ".")

# Copy headers
set(INCLUDE_DIR "include")
file(REMOVE_RECURSE "${INCLUDE_DIR}")
file(MAKE_DIRECTORY "${INCLUDE_DIR}")
foreach(_i IN LISTS INCS)
  file(GLOB_RECURSE _svh_files "${_i}/*.svh" "${_i}/*.sv")
  foreach(_f IN LISTS _svh_files)
    file(RELATIVE_PATH _rel "${_i}" "${_f}")
    get_filename_component(_rel_dir "${_rel}" DIRECTORY)
    set(_dest "${INCLUDE_DIR}/${_rel_dir}")
    file(MAKE_DIRECTORY "${_dest}")
    file(COPY "${_f}" DESTINATION "${_dest}")
  endforeach()
endforeach()

# Build flist
set(_FLIST)
foreach(_d IN LISTS DEFS)
  list(APPEND _FLIST "+define+${_d}")
endforeach()
list(APPEND _FLIST "+incdir+include")
foreach(_s IN LISTS SRCS)
  get_filename_component(_n "${_s}" NAME)
  list(APPEND _FLIST ${_n})
endforeach()

# Write flist
string(JOIN "\n" _OUT ${_FLIST})
file(WRITE "flist.f" "${_OUT}")
