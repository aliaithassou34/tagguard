        .section .adam_dift.protected, "a"
        .balign 4
        /* Protect the tainted selector branch in cwe824_uninit_pointer. */
        .word   cwe824_uninit_pointer
        .word   cwe824_uninit_pointer + 0x60
