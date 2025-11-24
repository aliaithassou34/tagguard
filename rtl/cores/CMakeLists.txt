add_subdirectory(cv32e40p)
add_subdirectory(cv32e40x)
add_subdirectory(ibex)

if (ADAM_ENABLE_GMSV)
    add_subdirectory(gmsv)
endif()
