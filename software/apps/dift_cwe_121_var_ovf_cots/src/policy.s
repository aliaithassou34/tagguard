        .section .adam_dift.protected, "a"
        .balign 4
        /* Protect final if (pass) branch in ovf_func */
        .word   ovf_func + 0x48
        .word   ovf_func + 0x4a
