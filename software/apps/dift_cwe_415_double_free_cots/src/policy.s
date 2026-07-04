        .section .adam_dift.protected, "a"
        .balign 4
        /* Protect branch on tainted_decision in cwe415_double_free */
        .word   cwe415_double_free + 0x52
        .word   cwe415_double_free + 0x54
