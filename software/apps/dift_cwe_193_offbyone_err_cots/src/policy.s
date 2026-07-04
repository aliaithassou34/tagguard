        .section .adam_dift.protected, "a"
        .balign 4
        /* Protect if (f.auth_flag) branch in run_exploit */
        .word   run_exploit + 0x34
        .word   run_exploit + 0x36
