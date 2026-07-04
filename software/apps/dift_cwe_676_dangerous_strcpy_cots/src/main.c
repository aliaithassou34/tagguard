/* dift_cwe_676_dangerous_strcpy — CWE-676: unchecked strcpy() overflows buf[] into auth_flag. Input is UART auto-tainted (DTSR); DIFT traps on the tainted branch/PC. */

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
static void cwe676_strcpy_overflow(frame_t *f, const char *user_input)
{
    /* BUG: strcpy() has no bounds checking.
     * When user_input is longer than BUF_SZ (16), it writes
     * past the end of f->buf into f->auth_flag.
     */
    strcpy((char *)f->buf, user_input);
}

__attribute__((optnone))
void run_exploit(const char *user_input)
{
    frame_t f = {0};

    printf("auth_flag before strcpy: 0x%08lx\n", (unsigned long)f.auth_flag);

    cwe676_strcpy_overflow(&f, user_input);

    printf("auth_flag after strcpy:  0x%08lx\n", (unsigned long)f.auth_flag);

#ifdef DIFT
    /* Arm only now — avoid false positives during uart_read/printf. */
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

    printf("=== DIFT CWE-676 Dangerous strcpy (Stack) ===\n");
    printf("strcpy has no bounds check — send exactly %d bytes to overflow\n", BUF_SZ + 1);
    printf("Exploit example: 16 x 'A' + 'X'  (just type them in PuTTY)\n");

    /* Enable HW auto-taint on LSPA peripherals. */
#ifndef ADAM_DIFT_BOOT_DTSR
    RAL.SYSCFG->TAINT_SRC.DTSR = 0x10;   /* LSPA_UART0_TAINT_EN */
#endif

#define PAYLOAD_LEN (BUF_SZ + 1)   /* 17 bytes: 16 fill + 1 overflow */
    char payload[PAYLOAD_LEN + 1];
    printf("Waiting for %d bytes on UART...\n", PAYLOAD_LEN);
    uart_read(&uart, payload, PAYLOAD_LEN);
    payload[PAYLOAD_LEN] = '\0';   /* NUL-terminate in firmware */

    printf("Read %d bytes\n", PAYLOAD_LEN);

#ifdef DIFT
    printf("DIFT ON  — TCR will arm at final auth check\n");
#else
    printf("DIFT OFF — no protection\n");
#endif

    run_exploit(payload);

    printf("run_exploit returned — DIFT did NOT catch it!\n");
    while (1) {}
}
