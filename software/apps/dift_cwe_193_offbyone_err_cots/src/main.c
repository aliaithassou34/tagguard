/* dift_cwe_193_offbyone_err — CWE-193: off-by-one loop bound overflows buf[] into auth_flag by one byte. Input is UART auto-tainted (DTSR); DIFT traps on the tainted branch/PC. */

#include <stdio.h>
#include <stdint.h>
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

#define BUF_SZ 16

typedef struct {
    volatile char     buf[BUF_SZ];
    volatile uint32_t auth_flag;
} frame_t;

__attribute__((optnone))
static void cwe193_bad_copy(frame_t *f, const char *input, size_t len)
{
    /* BUG: loop condition uses <= instead of < (off-by-one).
     * When len == BUF_SZ, the last iteration writes input[BUF_SZ]
     * into buf[BUF_SZ], which aliases auth_flag's first byte.
     */
    for (size_t i = 0; i <= len; i++) {
        f->buf[i] = input[i];
    }
}

__attribute__((optnone))
void run_exploit(const char *user_input)
{
    frame_t f;
    memset((void *)&f, 0, sizeof(f));

    printf("auth_flag before copy: 0x%08lx\n", (unsigned long)f.auth_flag);

    cwe193_bad_copy(&f, user_input, BUF_SZ);   /* len = BUF_SZ → off-by-one */

    printf("auth_flag after copy:  0x%08lx\n", (unsigned long)f.auth_flag);

#ifdef DIFT
    /* Arm TCR only now — avoid false positives during uart_read/printf. */
    write_tcr(0x00001818); /* BRANCH_S1/S2 | COMP_S1/S2 */
#endif

    if (f.auth_flag) {
        printf("!!! auth_flag set — DIFT FAILED !!!\n");
    } else {
        printf("auth_flag still 0 (no corruption)\n");
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

    printf("=== DIFT CWE-193 Off-by-One Error (Stack) ===\n");
    printf("Send %d bytes; last byte overwrites auth_flag.\n", BUF_SZ + 1);
    printf("Exploit example: %d x 'A' + 'X'\n", BUF_SZ);

    /* Enable HW auto-taint on LSPA peripherals. */
#ifndef ADAM_DIFT_BOOT_DTSR
    RAL.SYSCFG->TAINT_SRC.DTSR = 0x10;   /* LSPA_UART0_TAINT_EN */
#endif

    char payload[BUF_SZ + 2];            /* +1 off-by-one byte, +1 NUL */
    printf("Waiting for %d bytes on UART...\n", BUF_SZ + 1);
    uart_read(&uart, payload, BUF_SZ + 1);
    payload[BUF_SZ + 1] = '\0';

#ifdef DIFT
    printf("DIFT ON  — TCR will arm at final auth check\n");
#else
    printf("DIFT OFF — no protection\n");
#endif

    run_exploit(payload);

    printf("run_exploit returned — DIFT did NOT catch it!\n");
    while (1) {}
}
