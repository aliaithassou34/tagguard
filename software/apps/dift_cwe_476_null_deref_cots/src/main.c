/* dift_cwe_476_null_deref — CWE-476: attacker-controlled pointer is dereferenced without a NULL check. Input is UART auto-tainted (DTSR); DIFT traps on the tainted branch/PC. */

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
void cwe476_bad_deref(const char *in)
{
    static volatile uint32_t safe_word = 0x41414141;
    volatile uint32_t *table[2] = { &safe_word, 0 };

    /* BUG: index not validated; attacker controls pointer selection. */
    volatile char selector = in[0];
    int idx = (selector - '0');
    volatile uint32_t *p = table[idx & 0x1];

    printf("idx=%d selected pointer=%p\n", idx, (void *)p);

#ifdef DIFT
    write_tcr(0x00001818); /* arm branch/comparison checks near sink */
#endif

    if (selector == '1') {
        printf("about to dereference NULL pointer\n");
    }

    /* CWE-476: NULL dereference if p == NULL. */
    volatile uint32_t v = *p;

    /* If execution reaches here, dereference did not trap on this platform/run. */
    if (v == 0x00000000) {
        printf("value is NULL-like (0x00000000) — DIFT did not catch\n");
    } else {
        printf("value is 0x%08lx — DIFT did not catch\n", (unsigned long)v);
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

    printf("=== DIFT CWE-476 NULL Pointer Dereference ===\n");
    printf("Send 1 byte: '1' selects NULL pointer and triggers dereference\n");

#ifndef ADAM_DIFT_BOOT_DTSR
    RAL.SYSCFG->TAINT_SRC.DTSR = 0x10;
#endif

    char payload[2];
    uart_read(&uart, payload, 1);
    payload[1] = '\0';

    cwe476_bad_deref(payload);

    while (1) {}
}
