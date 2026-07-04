        .section .adam_dift.trusted, "a"
        .balign 4

        .macro ADAM_DIFT_TRUST_FUNC name, size
        .weak   \name
        .word   \name
        .word   \name + \size
        .endm

        /* Trust everything between two global symbols; use for a LOCAL
           clone (e.g. an -O2 IPA-SRA split) that can't be named directly. */
        .macro ADAM_DIFT_TRUST_RANGE start_name, end_name
        .weak   \start_name
        .weak   \end_name
        .word   \start_name
        .word   \end_name
        .endm

        /* HAL I/O: keep these tight because app code is linked right after UART. */
        ADAM_DIFT_TRUST_FUNC uart_init,  0x5c
        ADAM_DIFT_TRUST_FUNC uart_write, 0x1e
        ADAM_DIFT_TRUST_FUNC uart_read,  0x22
        ADAM_DIFT_TRUST_FUNC _read,      0x78
        ADAM_DIFT_TRUST_FUNC _write,     0x62

        /* String/memory routines branch while scanning or copying data. */
        ADAM_DIFT_TRUST_FUNC strcpy,  0x12
        ADAM_DIFT_TRUST_FUNC strncpy, 0x40
        ADAM_DIFT_TRUST_FUNC memcpy,  0x16
        ADAM_DIFT_TRUST_FUNC memmove, 0x26
        ADAM_DIFT_TRUST_FUNC memset,  0x80
        ADAM_DIFT_TRUST_FUNC strlen,  0x12
        ADAM_DIFT_TRUST_FUNC strnlen, 0x40
        ADAM_DIFT_TRUST_FUNC strcmp,  0x18
        ADAM_DIFT_TRUST_FUNC strncmp, 0x2c
        ADAM_DIFT_TRUST_FUNC strchr,  0x40
        ADAM_DIFT_TRUST_FUNC memchr,  0x1a
        ADAM_DIFT_TRUST_FUNC memcmp,  0x40

        /* Parsers and formatted I/O walk tainted bytes but should preserve tags. */
        ADAM_DIFT_TRUST_FUNC atoi,              0x300
        ADAM_DIFT_TRUST_FUNC strtol,            0x400
        ADAM_DIFT_TRUST_FUNC strtoul,           0x400
        /* -O2 IPA-SRA clones strtol into a LOCAL _strtol_l.isra.0 symbol */
        ADAM_DIFT_TRUST_RANGE _strtod_r, strtol
        ADAM_DIFT_TRUST_FUNC iprintf,           0x80
        ADAM_DIFT_TRUST_FUNC _iprintf_r,        0x80
        ADAM_DIFT_TRUST_FUNC printf,            0x800
        ADAM_DIFT_TRUST_FUNC vprintf,           0x800
        ADAM_DIFT_TRUST_FUNC puts,              0x200
        ADAM_DIFT_TRUST_FUNC putchar,           0x100
        ADAM_DIFT_TRUST_FUNC _printf_r,         0x800
        ADAM_DIFT_TRUST_FUNC _printf_common,    0x200
        ADAM_DIFT_TRUST_FUNC _printf_i,         0x400
        ADAM_DIFT_TRUST_FUNC __ssputs_r,        0x100
        ADAM_DIFT_TRUST_FUNC _svfiprintf_r,     0x300
        ADAM_DIFT_TRUST_FUNC __sfputc_r,        0x40
        ADAM_DIFT_TRUST_FUNC __sfputs_r,        0x60
        ADAM_DIFT_TRUST_FUNC __ascii_mbtowc,    0x40
        ADAM_DIFT_TRUST_FUNC __ascii_wctomb,    0x40
        ADAM_DIFT_TRUST_FUNC _vfprintf_r,       0x1000
        ADAM_DIFT_TRUST_FUNC _vfiprintf_r,      0x1000
        ADAM_DIFT_TRUST_FUNC __vfprintf_internal, 0x1000

        /* Allocator internals branch on heap metadata, not on app policy sinks. */
        ADAM_DIFT_TRUST_FUNC malloc,   0x800
        ADAM_DIFT_TRUST_FUNC free,     0x800
        ADAM_DIFT_TRUST_FUNC calloc,   0x800
        ADAM_DIFT_TRUST_FUNC realloc,  0x800
        ADAM_DIFT_TRUST_FUNC _malloc_r, 0x800
        ADAM_DIFT_TRUST_FUNC _free_r,   0x800

        /* libgcc arithmetic helpers may branch over tainted scalar values. */
        ADAM_DIFT_TRUST_FUNC __mulsi3,  0x200
        ADAM_DIFT_TRUST_FUNC __divsi3,  0x300
        ADAM_DIFT_TRUST_FUNC __udivsi3, 0x300
        ADAM_DIFT_TRUST_FUNC __modsi3,  0x300
        ADAM_DIFT_TRUST_FUNC __umodsi3, 0x300
