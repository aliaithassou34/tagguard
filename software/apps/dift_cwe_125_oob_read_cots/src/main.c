/* dift_cwe_125_oob_read — CWE-125: unchecked upper bound reads past buf[] into a secret field. Input is UART auto-tainted (DTSR); DIFT traps on the tainted branch/PC. */

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

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

#define BUF_SZ 16

typedef struct {
    volatile char     buf[BUF_SZ];
    volatile uint32_t secret;        /* adjacent field — OOB read target */
} frame_t;

__attribute__((optnone))
void cwe125_bad_read(const char *user_input)
{
    frame_t f;

    /* Initialize buf with known safe values. */
    for (int i = 0; i < BUF_SZ; i++)
        f.buf[i] = (char)i;

    /* Place a non-zero sentinel adjacent to buf so OOB read returns != 0. */
    f.secret = 0xDEADBEEF;

    int idx = atoi(user_input);
    printf("parsed idx = %d\n", idx);
    printf("secret = 0x%08lx\n", (unsigned long)f.secret);

    /* BUG: missing upper-bound check (idx < BUF_SZ).
     * idx = BUF_SZ (16) reads buf[16] = secret's first byte = 0xEF.
     */
    if (idx >= 0) {
        volatile char leaked = f.buf[idx];   /* tainted idx → tainted result */
        printf("buf[%d] = 0x%02x (leaked byte)\n", idx, (unsigned char)leaked);

#ifdef DIFT
        /* Arm TCR only now — tainted leaked value will trigger the branch. */
        write_tcr(0x00001818); /* BRANCH_S1/S2 | COMP_S1/S2 */
#endif

        if (leaked) {
            printf("!!! OOB read exposed secret — DIFT FAILED !!!\n");
        } else {
            printf("leaked byte is 0 (no sensitive data exposed)\n");
        }
    } else {
        printf("index rejected (negative)\n");
    }

    while (1) {}
}

int main(void)
{
    RAL.SYSCFG->LSPA.UART[0].MR = 1;
    while (RAL.SYSCFG->LSPA.UART[0].MR);

    /* Clear stale policy between runs. */
#ifdef DIFT
    write_tcr(0x0);
#endif

    uart_init(&uart);

    printf("=== DIFT CWE-125 Out-of-Bounds Read (Stack) ===\n");
    printf("buf[0..%d] are safe; buf[%d] aliases secret[0] = 0xEF\n",
           BUF_SZ - 1, BUF_SZ);
    printf("Send 3-byte payload, exploit example: 16A\n");

    /* Enable HW auto-taint on LSPA peripherals. */
#ifndef ADAM_DIFT_BOOT_DTSR
    RAL.SYSCFG->TAINT_SRC.DTSR = 0x10;   /* LSPA_UART0_TAINT_EN */
#endif

    char payload[4];
    printf("Waiting for 3 bytes on UART...\n");
    uart_read(&uart, payload, 3);
    payload[3] = '\0';

#ifdef DIFT
    printf("DIFT ON  — TCR will arm at final leaked-byte check\n");
#else
    printf("DIFT OFF — no protection\n");
#endif

    cwe125_bad_read(payload);

    printf("cwe125_bad_read returned — DIFT did NOT catch it!\n");
    while (1) {}
}
