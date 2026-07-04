/* dift_cwe_122_heap — CWE-122: heap buffer overflow corrupts an adjacent admin flag. Input is UART auto-tainted (DTSR); DIFT traps on the tainted branch/PC. */

#include <stdio.h>
#include <stdlib.h>
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

/* ---- Vulnerable function ---- */

__attribute__((optnone))
void process_request(char *user_buf, volatile uint32_t *admin_flag)
{
    printf("admin_flag = 0x%08lx\n", (unsigned long)*admin_flag);

#ifdef DIFT
    write_tcr(0x00001818);
#endif

    if (*admin_flag) {
        printf("!!! Admin access GRANTED — DIFT FAILED !!!\n");
    } else {
        printf("Access denied (expected path)\n");
    }

    (void)user_buf;
}

/* ---- Constants ---- */

#define CHUNK_A_SIZE 16
#define CHUNK_B_SIZE 4

/* ---- main ---- */

int main(void)
{
    /* 1. Boot UART */
    RAL.SYSCFG->LSPA.UART[0].MR = 1;
    while (RAL.SYSCFG->LSPA.UART[0].MR);
    uart_init(&uart);

    printf("=== DIFT Heap Overflow — HW Auto-Taint ===\n");

    /* 2. TCR stays 0 during UART/HAL activity; arm it before the check */
#ifdef DIFT
    printf("DIFT ON  — TCR armed just before admin check (0x00001818)\n");
#else
    printf("DIFT OFF — no protection\n");
#endif

        /* 3. Enable HW auto-taint on LSPA peripherals */
#ifndef ADAM_DIFT_BOOT_DTSR
        RAL.SYSCFG->TAINT_SRC.DTSR = 0x10;   /* LSPA_UART0_TAINT_EN */
#endif

        /* 4. Allocate two adjacent heap buffers */
        char *chunk_a = (char *)malloc(CHUNK_A_SIZE);
        volatile uint32_t *chunk_b = (volatile uint32_t *)malloc(CHUNK_B_SIZE);

    if (!chunk_a || !chunk_b) {
        printf("malloc failed\n");
        while (1) {}
    }

    *chunk_b = 0;

    size_t overflow_len = (size_t)((uintptr_t)chunk_b - (uintptr_t)chunk_a);
    size_t payload_len = overflow_len + sizeof(*chunk_b);

    printf("chunk_a (user_buf)     @ %p\n", (void *)chunk_a);
    printf("chunk_b (admin_flag)   @ %p\n", (void *)chunk_b);
    printf("Offset between chunks  = %ld bytes\n",
           (long)((uintptr_t)chunk_b - (uintptr_t)chunk_a));
    printf("Send %lu bytes to overflow chunk_a into chunk_b\n",
           (unsigned long)payload_len);

    /* 5. Read attacker payload from UART (auto-tainted by HW) */
    printf("Waiting for %lu bytes on UART...\n", (unsigned long)payload_len);
    char payload[payload_len];
    uart_read(&uart, payload, payload_len);

    printf("admin_flag before overflow: 0x%08lx\n", (unsigned long)*chunk_b);

    /* 6. Overflow chunk_a into chunk_b */
    memcpy(chunk_a, payload, payload_len);

    printf("admin_flag after overflow:  0x%08lx\n", (unsigned long)*chunk_b);

    /* 7. Branch on the corrupted flag */
    printf("Calling process_request()...\n");
    process_request(chunk_a, chunk_b);

    printf("process_request returned — DIFT did NOT catch it!\n");
    while (1) {}
}
