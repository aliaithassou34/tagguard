/* dift_cwe_120_bss — CWE-120: BSS buffer overflow corrupts an adjacent function pointer. Input is UART auto-tainted (DTSR); DIFT traps on the tainted branch/PC. */

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

/* ---- BSS-resident targets ---- */

void __attribute__((noinline))
normal_callback(void)
{
    printf("normal_callback (safe)\n");
}

void __attribute__((noinline, section(".text.shellcode_bss")))
shellcode(void)
{
    printf("!!! shellcode reached — DIFT FAILED !!!\n");
    while (1) {}
}

/* ---- BSS/Data vulnerable objects ---- */

#define BSS_BUFSIZE 16

/*
 * Keep vulnerable objects in a single aggregate to force deterministic
 * layout: overflow of buffer[] flows directly into func_ptr.
 */
typedef struct {
    uint8_t buffer[BSS_BUFSIZE * sizeof(uint32_t)];
    void (*func_ptr)(void);
} bss_vuln_t;

static bss_vuln_t g_bss;

__attribute__((optnone))
void trigger_overflow(const uint8_t *payload, int nbytes)
{
    /* BUG: no bounds check — memcpy overflows buffer into func_ptr */
    memcpy(g_bss.buffer, payload, nbytes);
}

#define FILLER_LEN  (BSS_BUFSIZE * (int)sizeof(uint32_t))
#define PAYLOAD_LEN (FILLER_LEN + 4)

int main(void)
{
    RAL.SYSCFG->LSPA.UART[0].MR = 1;
    while (RAL.SYSCFG->LSPA.UART[0].MR);

    uart_init(&uart);

#ifdef DIFT
    /*
     * TCR = EXECUTE_PC (bit 21) — fires when jalr uses a tainted
     * target address (the corrupted BSS function pointer).
     */
    write_tcr(0x00200000);
    printf("DIFT ON  — TCR = 0x00200000 (EXECUTE_PC)\n");
#else
    printf("DIFT OFF — no protection\n");
#endif

    /* Enable HW auto-taint for LSPA peripheral reads */
#ifndef ADAM_DIFT_BOOT_DTSR
    RAL.SYSCFG->TAINT_SRC.DTSR = 0x10;
#endif

    /* Initialize the BSS function pointer to safe callback */
    g_bss.func_ptr = normal_callback;

    uint32_t target = (uint32_t)(uintptr_t)shellcode;

    printf("=== DIFT BSS/Data Function-Pointer Overwrite — HW Auto-Taint ===\n");
    printf("shellcode    @ 0x%08lx\n", (unsigned long)target);
        printf("bss_buffer   = %d bytes\n", FILLER_LEN);
        printf("buffer @ %p, func_ptr @ %p, offset=%lu\n",
            (void *)g_bss.buffer,
            (void *)&g_bss.func_ptr,
            (unsigned long)((uintptr_t)&g_bss.func_ptr - (uintptr_t)g_bss.buffer));
    printf("Payload (%d B) = ['A' x %d] + [0x%02x 0x%02x 0x%02x 0x%02x]\n",
           PAYLOAD_LEN, FILLER_LEN,
           (target >>  0) & 0xFF,
           (target >>  8) & 0xFF,
           (target >> 16) & 0xFF,
           (target >> 24) & 0xFF);

    printf("Waiting for %d bytes on UART...\n", PAYLOAD_LEN);
    uint8_t payload[PAYLOAD_LEN];
    uart_read(&uart, payload, PAYLOAD_LEN);

    printf("bss_func_ptr before: %p (normal_callback)\n", (void *)g_bss.func_ptr);

    trigger_overflow(payload, PAYLOAD_LEN);

    printf("bss_func_ptr after:  %p (should be shellcode)\n", (void *)g_bss.func_ptr);
    printf("Calling bss_func_ptr()...\n");

    /* Indirect call through tainted BSS pointer → DIFT exception */
    g_bss.func_ptr();

    printf("bss_func_ptr returned — DIFT did NOT catch it!\n");

    while (1) {}
}
