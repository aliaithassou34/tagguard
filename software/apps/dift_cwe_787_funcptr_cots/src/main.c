/* dift_cwe_787_funcptr — CWE-787: stack buffer overflow overwrites a function pointer. Input is UART auto-tainted (DTSR); DIFT traps on the tainted branch/PC. */

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

/* ---- Target functions ---- */

void __attribute__((noinline))
normal_handler(void)
{
    printf("normal_handler called (safe)\n");
}

void __attribute__((noinline, section(".text.evil_admin")))
evil_admin(void)
{
    printf("!!! evil_admin reached — DIFT FAILED !!!\n");
    while (1) {}
}

/* ---- Vulnerable structure ---- */

typedef void (*callback_t)(void);

struct device_ctx {
    char name[12];          /* 12-byte buffer */
    callback_t on_event;    /* function pointer right after buffer */
};

__attribute__((optnone))
void process_input(struct device_ctx *ctx, const char *input, int len)
{
    /* BUG: no bounds check — overflows name[] into on_event */
    memcpy(ctx->name, input, len);
}

/* ---- Constants ---- */

#define NAME_SIZE   12
#define PAYLOAD_LEN (NAME_SIZE + 4)       /* 16 bytes total */

/* ---- main ---- */

int main(void)
{
    /* 1. Boot UART */
    RAL.SYSCFG->LSPA.UART[0].MR = 1;
    while (RAL.SYSCFG->LSPA.UART[0].MR);
    uart_init(&uart);

    printf("=== DIFT Struct Function-Pointer Overwrite — HW Auto-Taint ===\n");

    /* 2. Print the payload recipe */
    uint32_t target = (uint32_t)(uintptr_t)evil_admin;
    printf("evil_admin     @ 0x%08lx\n", (unsigned long)target);
    printf("normal_handler @ 0x%08lx\n", (unsigned long)(uintptr_t)normal_handler);
    printf("name[%d] + on_event(4) = %d bytes\n", NAME_SIZE, PAYLOAD_LEN);
    printf("Payload (%d B) = ['B' x %d] + [0x%02x 0x%02x 0x%02x 0x%02x]\n",
           PAYLOAD_LEN, NAME_SIZE,
           (target >>  0) & 0xFF,
           (target >>  8) & 0xFF,
           (target >> 16) & 0xFF,
           (target >> 24) & 0xFF);

    /* 3. Enable DIFT (set once) */
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
    char payload[PAYLOAD_LEN];
    uart_read(&uart, payload, PAYLOAD_LEN);

    /* 6. Set up device context and overflow */
    struct device_ctx dev;
    dev.on_event = normal_handler;

    printf("dev.on_event before: %p\n", (void *)dev.on_event);
    process_input(&dev, payload, PAYLOAD_LEN);
    printf("dev.on_event after:  %p\n", (void *)dev.on_event);

    /* 7. Indirect call — tainted PC → DIFT exception */
    printf("Calling dev.on_event()...\n");
    dev.on_event();

    /*
     * If DIFT is ON  → traps on jalr (tainted function pointer).
     * If DIFT is OFF → evil_admin() runs (exploit works).
     */
    printf("on_event returned — DIFT did NOT catch the hijack!\n");
    while (1) {}
}
