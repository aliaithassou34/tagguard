/* dift_cwe_416_use_after_free — CWE-416: a freed object is read through a dangling pointer. Input is UART auto-tainted (DTSR); DIFT traps on the tainted branch/PC. */

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
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

typedef struct {
    volatile uint32_t auth_flag;
    volatile uint32_t session_id;
    volatile char name[8];
} user_ctx_t;

__attribute__((optnone))
void cwe416_uaf_check(volatile user_ctx_t *dangling)
{
    printf("dangling->auth_flag = 0x%08lx\n",
           (unsigned long)dangling->auth_flag);

#ifdef DIFT
    /* Arm only at the sink to reduce non-security false positives. */
    write_tcr(0x00001818); /* BRANCH_S1/S2 | COMP_S1/S2 */
#endif

    if (dangling->auth_flag) {
        printf("!!! UAF exploit succeeded — DIFT FAILED !!!\n");
    } else {
        printf("auth_flag is 0 (safe path)\n");
    }

    while (1) {}
}

int main(void)
{
    RAL.SYSCFG->LSPA.UART[0].MR = 1;
    while (RAL.SYSCFG->LSPA.UART[0].MR);

    /* In app-managed DIFT mode, clear stale policy between runs.
     * In COTS boot-policy mode (no DIFT define), keep boot TCR active. */
#ifdef DIFT
    write_tcr(0x0);
#endif

    uart_init(&uart);

    printf("=== DIFT CWE-416 Use-After-Free (Heap) ===\n");

    /* Enable HW auto-taint on LSPA peripherals after UART setup. */
#ifndef ADAM_DIFT_BOOT_DTSR
    RAL.SYSCFG->TAINT_SRC.DTSR = 0x10;
#endif

    user_ctx_t *obj = (user_ctx_t *)malloc(sizeof(user_ctx_t));
    if (!obj) {
        printf("malloc(obj) failed\n");
        while (1) {}
    }

    obj->auth_flag = 0;
    obj->session_id = 0x12345678;
    memset((void *)obj->name, 0, sizeof(obj->name));

    /* Free object but keep dangling pointer (CWE-416 core bug). */
    volatile user_ctx_t *dangling = obj;
    free(obj);

    /* Re-allocate a chunk of the same size to reclaim freed storage. */
    char *reuse = (char *)malloc(sizeof(user_ctx_t));
    if (!reuse) {
        printf("malloc(reuse) failed\n");
        while (1) {}
    }

    printf("dangling ptr = %p, reuse ptr = %p\n", (void *)dangling, (void *)reuse);
    printf("Send %lu bytes payload (first byte should be non-zero)\n",
           (unsigned long)sizeof(user_ctx_t));

    char payload[sizeof(user_ctx_t)];
    printf("Waiting for %lu bytes on UART...\n", (unsigned long)sizeof(user_ctx_t));
    uart_read(&uart, payload, sizeof(payload));

    /* Write tainted data into potentially reclaimed freed block. */
    memcpy(reuse, payload, sizeof(payload));

#ifdef DIFT
    printf("DIFT ON  — TCR will arm at final auth check\n");
#else
    printf("DIFT OFF — no protection\n");
#endif

    cwe416_uaf_check(dangling);

    printf("cwe416_uaf_check returned — DIFT did NOT catch it!\n");
    while (1) {}
}
