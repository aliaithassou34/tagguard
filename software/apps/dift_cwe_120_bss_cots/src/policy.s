        .section .adam_dift.protected, "a"
        .balign 4
        /* Protect indirect call through corrupted BSS function pointer */
        .word   main + 0x106
        .word   main + 0x108
