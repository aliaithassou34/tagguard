/* dift_cwe_121_var_ovf — CWE-121: stack buffer overflow overwrites an adjacent local variable. Input is UART auto-tainted (DTSR); DIFT traps on the tainted branch/PC. */

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

/* input >= 16 bytes overflows buff[15] into the adjacent "pass" */
__attribute__((optnone))
int ovf_func(const char *input)
{
    volatile int pass = 0;
    volatile char buff[15];

    /* --- Data movement: TCR = 0, taint propagates silently --- */
    strcpy((char *)buff, input);

    if (strcmp((char *)buff, "thegeekstuff")) {
        printf("Wrong Password\n");
    } else {
        printf("Correct Password\n");
        pass = 1;
    }

    /*
     * arm DIFT branch/comparison checks right before the "if (pass)" sink
     */
#ifdef DIFT
    write_tcr(0x00001818);
#endif

    if (pass) {
        /* Attacker gains root — DIFT traps HERE */
        printf("Root privileges given to the user\n");
    }

    return 0;
}

/* ---- Constants ---- */

#define INPUT_LEN 20   /* 15 (buff) + padding → overflows into pass */

/* ---- main ---- */

int main(void)
{
    /* 1. Boot UART */
    RAL.SYSCFG->LSPA.UART[0].MR = 1;
    while (RAL.SYSCFG->LSPA.UART[0].MR);
    uart_init(&uart);

    printf("=== DIFT Stack Local-Var Overwrite — HW Auto-Taint ===\n");

    /* 2. Print the payload recipe */
    printf("buff[15] at sp+0, pass at sp+16\n");
    printf("Send %d bytes to overflow buff into pass\n", INPUT_LEN);

    /* 3. Enable HW auto-taint on LSPA peripherals */
#ifndef ADAM_DIFT_BOOT_DTSR
    RAL.SYSCFG->TAINT_SRC.DTSR = 0x10;   /* LSPA_UART0_TAINT_EN */
#endif

    /* 4. Read attacker input from UART (auto-tainted by HW) */
    printf("Waiting for %d bytes on UART...\n", INPUT_LEN);
    char malicious[INPUT_LEN + 1];
    uart_read(&uart, malicious, INPUT_LEN);
    malicious[INPUT_LEN] = '\0';

    /* 5. Call vulnerable function */
    printf("Calling ovf_func...\n");
    ovf_func(malicious);

    /*
     * If DIFT is ON  → traps on "if (pass)" inside ovf_func.
     * If DIFT is OFF → "Root privileges given" prints (exploit works).
     */
    printf("ovf_func returned — DIFT did NOT catch it!\n");
    while (1) {}
}
