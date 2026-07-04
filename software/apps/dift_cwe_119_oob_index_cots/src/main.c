/* dift_cwe_119_oob_index — CWE-119/787: negative array index writes before buf[] into auth_flag. Input is UART auto-tainted (DTSR); DIFT traps on the tainted branch/PC. */

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

typedef struct {
    volatile uint32_t auth_flag;
    volatile char buf[16];
} frame_t;

__attribute__((optnone))
void cwe119_bad_write(const char *user_input)
{
    frame_t f = {0};

    /* Payload format: "-1A" (3 bytes)
     * - atoi("-1A") => -1
     * - value byte is user_input[2] => 'A'
     */
    int idx = atoi(user_input);
    char value = user_input[2];

    printf("parsed idx = %d, value = 0x%02x\n", idx, (unsigned char)value);

    /* BUG: missing lower-bound check (idx >= 0) */
    if (idx < (int)sizeof(f.buf)) {
        f.buf[idx] = value;
        printf("write completed: buf[%d] = 0x%02x\n", idx, (unsigned char)value);
    } else {
        printf("index rejected (only upper bound checked)\n");
        return;
    }

    printf("auth_flag after write: 0x%08lx\n", (unsigned long)f.auth_flag);

#ifdef DIFT
    /* Arm only now: avoid false positives in uart_read()/atoi()/printf(). */
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

    printf("=== DIFT CWE-119 OOB Index Write (Stack) ===\n");
    printf("Send 3-byte payload, exploit example: -1A\n");

    /* Enable HW auto-taint after UART setup. */
#ifndef ADAM_DIFT_BOOT_DTSR
    RAL.SYSCFG->TAINT_SRC.DTSR = 0x10;
#endif

    char payload[4];
    printf("Waiting for 3 bytes on UART...\n");
    uart_read(&uart, payload, 3);
    payload[3] = '\0';

#ifdef DIFT
    printf("DIFT ON  — TCR will arm at final auth check\n");
#else
    printf("DIFT OFF — no protection\n");
#endif

    cwe119_bad_write(payload);

    printf("cwe119_bad_write returned — DIFT did NOT catch it!\n");
    while (1) {}
}
