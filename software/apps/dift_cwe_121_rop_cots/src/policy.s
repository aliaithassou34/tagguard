        .section .adam_dift.protected, "a"
        .balign 4
        /* Protect ret in ovf_ra_func: [ret_pc, ret_pc+2) */
        .word   ovf_ra_func + 0x12
        .word   ovf_ra_func + 0x14
