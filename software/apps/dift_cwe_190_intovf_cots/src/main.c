/* dift_cwe_190_intovf — CWE-190/121: signed narrowing bypasses a length check, then overflows a buffer. Input is UART auto-tainted (DTSR); DIFT traps on the tainted branch/PC. */

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

/*
 * Vulnerable function: uses an explicit signed 8-bit type for the length,
 * which wraps at 128 → negative, bypassing the < 32 check.
 */
__attribute__((optnone))
void bad_function(const char *input)
{
    volatile uint32_t auth_flag = 0;  /* protected flag */
    char dest_buffer[32];

    /* strlen(input)=200 wraps to -56 as int8_t, bypassing the < 32 check */
    int8_t input_len = (int8_t)strlen(input);

    printf("input_len (as char) = %d\n", (int)input_len);

    if (input_len < 32) {
        /* Bounds check BYPASSED due to integer overflow */
        strcpy(dest_buffer, input);
        printf("strcpy completed (overflow occurred!)\n");
        printf("auth_flag after overflow: 0x%08lx\n", (unsigned long)auth_flag);
    } else {
        printf("Input too long (expected for safe inputs)\n");
        return;
    }

#ifdef DIFT
    /* Arm TCR only at the security-critical check to avoid false positives. */
    printf("Arming TCR now (branch on auth_flag should trap)\n");
    write_tcr(0x00001818);
#endif

    /* Branch on the corrupted auth_flag → DIFT exception */
    if (auth_flag) {
        printf("auth_flag set — exploit succeeded (DIFT off)\n");
    } else {
        printf("auth_flag still 0 (no overflow into flag)\n");
    }

    /* Large overflow may corrupt saved RA; do not return into undefined state. */
    printf("Stopping in bad_function to avoid returning with corrupted RA\n");
    while (1) {}
}

int main(void)
{
    RAL.SYSCFG->LSPA.UART[0].MR = 1;
    while (RAL.SYSCFG->LSPA.UART[0].MR);

    /* Clear any residual TCR from previous runs. */
#ifdef DIFT
    write_tcr(0x0);
#endif

    uart_init(&uart);

    printf("=== DIFT Integer Overflow (Widening) Stack Overflow Test ===\n");

#define PAYLOAD_LEN 200

    printf("Suggested payload: %d bytes (e.g., all 'X')\n", PAYLOAD_LEN);

    /* Enable HW auto-taint on LSPA after UART setup. */
#ifndef ADAM_DIFT_BOOT_DTSR
    RAL.SYSCFG->TAINT_SRC.DTSR = 0x10;
#endif

    char malicious[PAYLOAD_LEN + 1];
    printf("Waiting for %d bytes on UART...\n", PAYLOAD_LEN);
    uart_read(&uart, malicious, PAYLOAD_LEN);
    malicious[PAYLOAD_LEN] = '\0';

#ifdef DIFT
    printf("DIFT ON  — TCR will arm inside bad_function before auth check\n");
#else
    printf("DIFT OFF — no protection\n");
#endif

    printf("Input length: %d bytes (char wraps to %d)\n",
            PAYLOAD_LEN, (int)(int8_t)PAYLOAD_LEN);
    printf("Calling bad_function...\n");

    bad_function(malicious);

    printf("bad_function returned — DIFT did NOT catch it!\n");

    while (1) {}
}
