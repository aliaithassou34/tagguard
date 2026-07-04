/* dift_cwe_121_rop — CWE-121: stack buffer overflow overwrites the saved return address. Input is UART auto-tainted (DTSR); DIFT traps on the tainted branch/PC. */

#include <stdio.h>
#include <string.h>
#include <stdint.h>

#include "adam_ral.h"
#include "adam/HAL/uart.h"

uart_t uart = {
    .ral = RAL.LSPA.UART[0],
    .baud_rate = 115200
};

/* ---- CSR helper ---- */

static inline void write_tcr(uint32_t val)
{
    __asm__ volatile ("csrw 0x7C1, %0" : : "r"(val));
}

/* ---- Attack target ---- */

/*
 * safe_target — the function the attacker redirects control to.
 * DIFT must trap BEFORE the CPU ever reaches here.
 */
void __attribute__((noinline, section(".text.safe_target")))
safe_target(void)
{
    printf("!!! safe_target reached — DIFT FAILED !!!\n");
    while (1) {}
}

/* payload[12..15] overwrites the saved ra at sp+12 */
__attribute__((optnone))
void ovf_ra_func(const char *src)
{
    volatile char buf[8];
    strcpy((char *)buf, src);
}

/* ---- Constants ---- */

#define RA_OFFSET   12                    /* buf(8) + saved_s0(4)  */
#define PAYLOAD_LEN (RA_OFFSET + 4)       /* 16 bytes total        */

/* ---- main ---- */

int main(void)
{
    /* 1. Boot UART */
    RAL.SYSCFG->LSPA.UART[0].MR = 1;
    while (RAL.SYSCFG->LSPA.UART[0].MR);
    uart_init(&uart);

    printf("=== DIFT Stack RA Overwrite — HW Auto-Taint ===\n");

    /* 2. Print the payload recipe so the attacker knows what to send */
    uint32_t target_addr = (uint32_t)(uintptr_t)safe_target;
    printf("safe_target   @ 0x%08lx\n", (unsigned long)target_addr);
    printf("RA offset     = %d bytes\n", RA_OFFSET);
    printf("Payload (%d B) = ['A' x %d] + [0x%02x 0x%02x 0x%02x 0x%02x]\n",
           PAYLOAD_LEN, RA_OFFSET,
           (target_addr >>  0) & 0xFF,
           (target_addr >>  8) & 0xFF,
           (target_addr >> 16) & 0xFF,
           (target_addr >> 24) & 0xFF);

    /* 3. Enable DIFT: trap on tainted PC */
#ifdef DIFT
    write_tcr(0x00200000);
    printf("DIFT ON  — TCR = 0x00200000 (EXECUTE_PC)\n");
#else
    printf("DIFT OFF — no protection\n");
#endif

    /* 4. Enable HW auto-taint on LSPA peripherals */
#ifndef ADAM_DIFT_BOOT_DTSR
    RAL.SYSCFG->TAINT_SRC.DTSR = 0x10;   /* LSPA_UART0_TAINT_EN */
#endif

    /* 5. Read attacker payload from UART (auto-tainted by HW) */
    printf("Waiting for %d bytes on UART...\n", PAYLOAD_LEN);
    char payload[PAYLOAD_LEN + 1];
    uart_read(&uart, payload, PAYLOAD_LEN);
    payload[PAYLOAD_LEN] = '\0';

    /* 6. Overflow the stack buffer → RA gets tainted value */
    printf("Calling ovf_ra_func (exploit attempt)...\n");
    ovf_ra_func(payload);

    /*
     * If DIFT is ON  → CPU traps on "ret", never reaches here.
     * If DIFT is OFF → safe_target() runs (exploit succeeds).
     */
    printf("ovf_ra_func returned — DIFT did NOT fire!\n");
    while (1) {}
}
