/* dift_autotaint_ra — HW auto-tainted UART reads overflow a stack buffer
 * and overwrite the return address; EXECUTE_PC traps on the tainted ret. */

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
    printf("!!! safe_target reached — DIFT FAILED !!!\n");
    while (1) {}
}

/* Vulnerable function: small buffer, no bounds check */
__attribute__((optnone))
void vuln_read(volatile uint32_t *uart_sr_addr, uint32_t nwords)
{
    volatile uint32_t buf[2]; /* nwords > 2 overflows into saved s0/ra */
    for (uint32_t i = 0; i < nwords; i++) {
        buf[i] = *uart_sr_addr;  /* each read is HW auto-tainted */
    }
}

#define RA_OFFSET_WORDS 3  /* buf[0], buf[1], saved_s0, saved_ra */
#define OVERFLOW_WORDS  4  /* enough to overwrite ra */

int main()
{
    RAL.SYSCFG->LSPA.UART[0].MR = 1;
    while (RAL.SYSCFG->LSPA.UART[0].MR);

    RAL.SYSCFG->LSPA.GPIO[0].MR = 1;
    while (RAL.SYSCFG->LSPA.GPIO[0].MR);

    uart_init(&uart);

    printf("=== DIFT HW Auto-Taint + RA Overwrite ===\n");

    /* Enable DIFT: EXECUTE_PC check only */
    write_tcr(0x00200000);

    /* Enable HW auto-taint on LSPA peripherals */
    RAL.SYSCFG->TAINT_SRC.DTSR = 0x10;

    printf("Auto-taint ON. Reading from UART (tainted by HW)...\n");

    vuln_read((volatile uint32_t *)&RAL.LSPA.UART[0]->SR, OVERFLOW_WORDS);

    printf("vuln_read returned — DIFT did NOT catch it!\n");

    while (1) {}
}
