        .section .adam_dift.protected, "a"
        .balign 4
        /* Protect if (f.auth_flag) branch in cwe119_bad_write */
        .word   cwe119_bad_write + 0x82
        .word   cwe119_bad_write + 0x84
