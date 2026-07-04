        .section .adam_dift.protected, "a"
        .balign 4
        /* Protected final auth_flag check branch: [pc, pc+2) */
        .word   cwe416_uaf_check + 0x1a
        .word   cwe416_uaf_check + 0x1c
