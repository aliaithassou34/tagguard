/* bench_taint_compare — cycles/byte of software p.spsb tagging (A) vs a
 * zero-op reference loop standing in for free HW auto-taint (B). */

#include <stdio.h>
#include <string.h>
#include <stdint.h>

#include "adam_ral.h"
#include "adam/HAL/uart.h"

uart_t uart = {
    .ral       = RAL.LSPA.UART[0],
    .baud_rate = 115200
};

/* p.spsb  funct3=101 → tags 1 byte at the addressed byte.
 * Guarded: without DIFT hardware the custom opcode is illegal. */
#ifdef DIFT
static inline void p_spsb(volatile void *addr)
{
    __asm__ volatile (".insn s 0x23, 5, x0, 0(%0)" :: "r"(addr) : "memory");
}
#else
static inline void p_spsb(volatile void *addr) { (void)addr; }
#endif

static inline uint32_t read_mcycle(void)
{
    uint32_t c;
    __asm__ volatile ("csrr %0, mcycle" : "=r"(c));
    return c;
}

static inline void enable_mcycle(void)
{
    __asm__ volatile ("csrw 0x320, zero");
    __asm__ volatile ("csrw mcycle,  zero");
    __asm__ volatile ("csrw mcycleh, zero");
}

#define FRAME_LEN 200u
#define NUM_ITER  5

static volatile uint8_t frame[FRAME_LEN];

/* (A) software tagging: p.spsb on every byte */
static __attribute__((noinline)) uint32_t tag_sw(volatile uint8_t *buf,
                                                 uint32_t len)
{
    uint32_t sink = 0;
    for (uint32_t i = 0; i < len; i++) {
        p_spsb(&buf[i]);
        sink ^= buf[i];          /* force a load so the byte is really
                                    touched after tagging */
    }
    __asm__ volatile ("" :: "r"(sink) : "memory");
    return sink;
}

/* (B) reference loop, no p.spsb: what firmware runs when DTSR tags for free */
static __attribute__((noinline)) uint32_t tag_hw_ref(volatile uint8_t *buf,
                                                     uint32_t len)
{
    uint32_t sink = 0;
    for (uint32_t i = 0; i < len; i++) {
        sink ^= buf[i];
    }
    __asm__ volatile ("" :: "r"(sink) : "memory");
    return sink;
}

int main(void)
{
    RAL.SYSCFG->LSPA.UART[0].MR = 1;
    while (RAL.SYSCFG->LSPA.UART[0].MR);
    uart_init(&uart);

    enable_mcycle();

    printf("=== Benchmark: HW auto-taint vs SW p.spsb ===\n");

    /* Deterministic content so the XOR sink value is reproducible. */
    for (uint32_t i = 0; i < FRAME_LEN; i++) frame[i] = (uint8_t)(i * 7 + 3);

    uint32_t cyc_sw[NUM_ITER];
    uint32_t cyc_hw[NUM_ITER];
    uint32_t sink_sw = 0, sink_hw = 0;

    /* ---- (A) SW tagging ---- */
    for (int k = 0; k < NUM_ITER; k++) {
        uint32_t t0 = read_mcycle();
        sink_sw = tag_sw(frame, FRAME_LEN);
        uint32_t t1 = read_mcycle();
        cyc_sw[k] = t1 - t0;
    }

    /* ---- (B) HW auto-taint reference (same loop, no p.spsb) ---- */
    for (int k = 0; k < NUM_ITER; k++) {
        uint32_t t0 = read_mcycle();
        sink_hw = tag_hw_ref(frame, FRAME_LEN);
        uint32_t t1 = read_mcycle();
        cyc_hw[k] = t1 - t0;
    }

    printf("frame_len: %lu bytes\n", (unsigned long)FRAME_LEN);
    printf("sink:      sw=0x%02lx hw=0x%02lx (must match)\n",
           (unsigned long)sink_sw, (unsigned long)sink_hw);

    for (int k = 0; k < NUM_ITER; k++) {
        long delta = (long)cyc_sw[k] - (long)cyc_hw[k];
        printf("  iter %d: sw=%lu  hw=%lu  delta=%ld  per-byte=%ld\n",
               k,
               (unsigned long)cyc_sw[k],
               (unsigned long)cyc_hw[k],
               delta,
               delta / (long)FRAME_LEN);
    }

    printf("Done.\n");
    while (1) { __asm__ volatile ("nop"); }
}
