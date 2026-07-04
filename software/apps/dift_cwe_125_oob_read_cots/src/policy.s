        .section .adam_dift.protected, "a"
        .balign 4
        /* Protect if (leaked) branch in cwe125_bad_read */
        .word   cwe125_bad_read + 0x82
        .word   cwe125_bad_read + 0x84
