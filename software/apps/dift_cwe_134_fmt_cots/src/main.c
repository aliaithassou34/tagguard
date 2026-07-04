/* dift_cwe_134_fmt — CWE-134: attacker format string with %n corrupts a stack auth flag. Input is UART auto-tainted (DTSR); DIFT traps on the tainted branch/PC. */

#include <stdio.h>
#include <string.h>
#include <stdint.h>

#include "adam_ral.h"
#include "adam/HAL/uart.h"

uart_t uart = {
    .ral = RAL.LSPA.UART[0],
    .baud_rate = 115200
};

static inline void write_tcr(uint32_t val)
{
    __asm__ volatile ("csrw 0x7C1, %0" : : "r"(val) : );
}

/* Simulate a vulnerable logging function */
__attribute__((optnone))
void log_message(const char *user_input)
{
    volatile int auth_flag = 0;

    printf("auth_flag before: %d\n", auth_flag);



    /* BUG: user input used directly as format string; %n writes to stack */
    printf(user_input, &auth_flag);
    printf("\n");

    printf("auth_flag after:  %d\n", auth_flag);

#ifdef DIFT
    /* Arm TCR here — after all printf activity — so the only remaining
     * branch on tainted data is the security-critical if (auth_flag). */
    write_tcr(0x00001818);
#endif

    if (auth_flag) {
        printf("!!! Control flow hijacked via %%n — DIFT FAILED !!!\n");
    } else {
        printf("Access denied (expected path)\n");
    }
}

#define PAYLOAD_LEN 6

int main(void)
{
    RAL.SYSCFG->LSPA.UART[0].MR = 1;
    while (RAL.SYSCFG->LSPA.UART[0].MR);

    /* Clear any residual TCR from a previous run (CSR persists across resets) */
#ifdef DIFT
    write_tcr(0x0);
#endif

    uart_init(&uart);

    printf("=== DIFT Format String %%n Stack Write — HW Auto-Taint ===\n");
    printf("Suggested payload (%d B): AAAA%%n\n", PAYLOAD_LEN);

    /* Enable HW auto-taint on LSPA after setup */
#ifndef ADAM_DIFT_BOOT_DTSR
    RAL.SYSCFG->TAINT_SRC.DTSR = 0x10;
#endif

    printf("Waiting for %d bytes on UART...\n", PAYLOAD_LEN);
    char malicious[PAYLOAD_LEN + 1];
    uart_read(&uart, malicious, PAYLOAD_LEN);
    malicious[PAYLOAD_LEN] = '\0';

#ifdef DIFT
    printf("DIFT ON  — TCR will arm inside log_message before the sink\n");
#else
    printf("DIFT OFF — no protection\n");
#endif

    printf("Calling log_message with attacker input...\n");

    log_message(malicious);

    printf("log_message returned — DIFT did NOT catch format string!\n");

    while (1) {}
}
