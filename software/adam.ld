STACK_SIZE = DEFINED(STACK_SIZE) ? STACK_SIZE : 0x2000;

ENTRY(reset_handler)

SECTIONS
{
    .mem0 :
    {
        . = ALIGN(64);
        __mem0_start = .;

        KEEP(*(.vectors))          /* Trap-vector table */
        *(.text .text.*)           /* Code */
        *(.gnu.linkonce.t.*)       /* Deduplicated code */
        KEEP(*(.context))          /* Context switch tables */
        *(.rodata .rodata.*)       /* Read-only data */
        *(.rodata.fp .rodata.fp.*) /* Read-only FP tables */
        *(.gcc_except_table.*)     /* Exception handling tables */

        . = ALIGN(64);
        __mem0_end = .;
    } > MEM0

    .mem1_load :
    {
        . = ALIGN(64);
        __mem1_load_start = .;

        PROVIDE(__global_pointer$ = . + 0x800);

        *(vtable)              /* C++ vtables */
        *(.data .data.*)       /* Data */
        *(.gnu.linkonce.d.*)   /* Deduplicated data */
        *(.sdata .sdata.*)     /* Small data */
        *(.srodata .srodata.*) /* Small read-only data */

        *(.got .got.*) /* Global offset table */

        /* Early init pointers */
        . = ALIGN(64);
        PROVIDE(__preinit_array_start = .);
        KEEP(*(.preinit_array))
        PROVIDE(__preinit_array_end   = .);

        /* C++ constructor pointers */
        . = ALIGN(64);
        PROVIDE(__init_array_start = .);
        KEEP(*(SORT(.init_array.*)))
        KEEP(*(.init_array))
        PROVIDE(__init_array_end = .);

        /* C++ destructor pointers */
        . = ALIGN(64);
        PROVIDE(__fini_array_start = .);
        KEEP(*(SORT(.fini_array.*)))
        KEEP(*(.fini_array))
        PROVIDE(__fini_array_end = .);

        . = ALIGN(64);
        __mem1_load_end = .;
    } > MEM1 AT> MEM0

    .mem1_noload (NOLOAD) :
    {
        . = ALIGN(64);
        __bss_start = .;

        /* Zero-initialized data */
        *(.bss*)
        *(.sbss*)
        *(COMMON)

        . = ALIGN(64);
        __bss_end = .;
        __heap_start = .;

        . = ORIGIN(MEM1) + LENGTH(MEM1) - STACK_SIZE - 255;
        . = ALIGN(64);
        __heap_end = .;
        __stack_start = .;

        . = . + STACK_SIZE;
        . = ALIGN(64);
        __stack_end = .;
    } > MEM1
}
