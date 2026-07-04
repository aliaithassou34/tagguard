        .section .adam_dift.protected, "a"
        .balign 4
        /* Protect if (p == 0) branch in cwe476_bad_deref */
        .word   cwe476_bad_deref + 0x42
        .word   cwe476_bad_deref + 0x44
