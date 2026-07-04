/* dift_cwe_824_uninit_ptr — CWE-824: an uninitialized pointer is dereferenced. Input is UART auto-tainted (DTSR); DIFT traps on the tainted branch/PC. */

#include <stdio.h>
#include <stdint.h>

#include "adam_ral.h"
#include "adam/HAL/uart.h"

uart_t uart = {
    .ral = RAL.LSPA.UART[0],
    .baud_rate = 115200
};

static inline void write_tcr(uint32_t val)
{
    __asm__ volatile ("csrw 0x7C1, %0" : : "r"(val));
}

__attribute__((optnone))
void cwe824_uninit_pointer(const char *in)
{
    volatile uint32_t *p; /* intentionally uninitialized */
    volatile uint32_t fallback = 0;

    /* Tainted condition controls dangerous use of uninitialized pointer. */
    volatile uint8_t selector = (uint8_t)in[0];

#ifdef DIFT
    write_tcr(0x00001818);
#endif

    if (selector != (uint8_t)'0') {
        /* CWE-824 core bug: uninitialized pointer access. */
        *p = 0xA5A5A5A5;
        printf("wrote through uninitialized pointer\n");
    } else {
        fallback = 1;
        printf("safe path fallback=%lu\n", (unsigned long)fallback);
    }

    while (1) {}
}

int main(void)
{
    RAL.SYSCFG->LSPA.UART[0].MR = 1;
    while (RAL.SYSCFG->LSPA.UART[0].MR);

#ifdef DIFT
    write_tcr(0x0);
#endif
    uart_init(&uart);

    printf("=== DIFT CWE-824 Uninitialized Pointer ===\n");
    printf("Send 1 byte: non-'0' triggers uninitialized pointer access\n");

#ifndef ADAM_DIFT_BOOT_DTSR
    RAL.SYSCFG->TAINT_SRC.DTSR = 0x10;
#endif

    char payload[2];
    uart_read(&uart, payload, 1);
    payload[1] = '\0';

    cwe824_uninit_pointer(payload);

    while (1) {}
}
