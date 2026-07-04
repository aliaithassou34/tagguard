        .section .adam_dift.protected, "a"
        .balign 4
        /* Protect if (auth_flag) branch in bad_function */
        .word   bad_function + 0x66
        .word   bad_function + 0x68
