function(adam_sw_collect_targets out_var dir)
  # Collect direct targets from this directory
  get_directory_property(local_targets DIRECTORY "${dir}" BUILDSYSTEM_TARGETS)

  # Start with the local targets
  set(all_targets ${local_targets})

  # Recurse into subdirectories
  get_directory_property(subdirs DIRECTORY "${dir}" SUBDIRECTORIES)
  foreach(subdir IN LISTS subdirs)
    adam_sw_collect_targets(sub_targets "${subdir}")
    list(APPEND all_targets ${sub_targets})
  endforeach()

  # Return result to caller
  set(${out_var} "${all_targets}" PARENT_SCOPE)
endfunction()
