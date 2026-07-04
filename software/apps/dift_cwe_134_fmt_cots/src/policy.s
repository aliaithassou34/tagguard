        .section .adam_dift.protected, "a"
        .balign 4
        /* Protect if (auth_flag) branch in log_message */
        .word   log_message + 0x3a
        .word   log_message + 0x3c

        /* Tainted format strings must trap in the printf parser. */
        .word   _vfiprintf_r
        .word   _vfiprintf_r + 0x300
        .word   _printf_i
        .word   _printf_i + 0x300
