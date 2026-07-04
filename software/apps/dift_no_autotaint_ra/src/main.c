/* dift_no_autotaint_ra — same exploit as dift_autotaint_ra but DTSR=0:
 * DIFT is armed yet the exploit succeeds since nothing tags the UART data. */

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

/* Target the attacker wants to reach */
void __attribute__((noinline, section(".text.safe_target")))
safe_target(void)
{
    printf("!!! safe_target reached — DIFT FAILED (Config B) !!!\n");
    while (1) {}
}

/* Vulnerable function: small buffer, no bounds check */
__attribute__((optnone))
void vuln_read(volatile uint32_t *uart_sr_addr, uint32_t nwords)
{
    volatile uint32_t buf[2]; /* 8 bytes on stack */
    for (uint32_t i = 0; i < nwords; i++) {
        buf[i] = *uart_sr_addr;  /* HW does NOT taint these reads (DTSR=0) */
    }
    /* ret restores ra from stack; ra tag = 0 → no DIFT exception */
}

#define RA_OFFSET_WORDS 3
#define OVERFLOW_WORDS  4

int main()
{
    RAL.SYSCFG->LSPA.UART[0].MR = 1;
    while (RAL.SYSCFG->LSPA.UART[0].MR);

    RAL.SYSCFG->LSPA.GPIO[0].MR = 1;
    while (RAL.SYSCFG->LSPA.GPIO[0].MR);

    uart_init(&uart);

    printf("=== Config-B: DIFT armed, auto-taint OFF ===\n");

    /* Same DIFT check policy as Config-C */
    write_tcr(0x00200000);  /* EXECUTE_PC only */

    /* Auto-taint deliberately NOT enabled: DTSR stays at reset (0). */
    /* RAL.SYSCFG->TAINT_SRC.DTSR = 0x0; */

    printf("Auto-taint OFF. Reading from UART (untagged)...\n");

    vuln_read((volatile uint32_t *)&RAL.LSPA.UART[0]->SR, OVERFLOW_WORDS);

    /* Reaches here in Config B (exploit succeeds) */
    printf("vuln_read returned — DIFT did NOT catch it (expected in Config B)\n");

    while (1) {}
}
