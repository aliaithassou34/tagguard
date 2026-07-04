        .section .adam_dift.protected, "a"
        .balign 4
        /* Protect indirect jalr in main: [jalr_pc, jalr_pc+2) */
        .word   main + 0xf0
        .word   main + 0xf2
