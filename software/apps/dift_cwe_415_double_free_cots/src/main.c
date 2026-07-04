/* dift_cwe_415_double_free — CWE-415: the same heap pointer is freed twice. Input is UART auto-tainted (DTSR); DIFT traps on the tainted branch/PC. */

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

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

typedef struct {
    volatile uint32_t auth_flag;
    volatile uint32_t cookie;
    volatile char buf[8];
} ctx_t;

__attribute__((optnone))
void cwe415_double_free(const char *payload)
{
    ctx_t *p = (ctx_t *)malloc(sizeof(ctx_t));
    if (!p) {
        printf("malloc failed\n");
        while (1) {}
    }

    p->auth_flag = 0;
    p->cookie = 0xCAFEBABE;
    memset((void *)p->buf, 0, sizeof(p->buf));

    free(p);

    /* CWE-415: second free on same pointer. */
    free(p);

    /* Continue with a branch sink that consumes tainted data. */
    volatile uint32_t tainted_decision = (uint8_t)payload[0];

#ifdef DIFT
    write_tcr(0x00001818);
#endif

    if (tainted_decision) {
        printf("branch on tainted post-double-free path\n");
    } else {
        printf("zero path\n");
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

    printf("=== DIFT CWE-415 Double Free ===\n");
    printf("Send 1 byte payload\n");

#ifndef ADAM_DIFT_BOOT_DTSR
    RAL.SYSCFG->TAINT_SRC.DTSR = 0x10;
#endif

    char payload[2];
    uart_read(&uart, payload, 1);
    payload[1] = '\0';

    cwe415_double_free(payload);

    while (1) {}
}
