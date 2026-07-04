/* bench_matmul — 32x32 uint8 matrix multiply; compares mcycle count with
 * and without DIFT to check for false positives on untagged compute. */

#include <stdio.h>
#include <string.h>
#include <stdint.h>

#include "adam_ral.h"
#include "adam/HAL/uart.h"

uart_t uart = {
    .ral = RAL.LSPA.UART[0],
    .baud_rate = 115200
};

static inline uint32_t read_mcycle(void)
{
    uint32_t c;
    __asm__ volatile ("csrr %0, mcycle" : "=r"(c));
    return c;
}

/* CV32E40P: mcountinhibit[0]=cy inhibits mcycle. Clear it. */
static inline void enable_mcycle(void)
{
    __asm__ volatile ("csrw 0x320, zero");
    __asm__ volatile ("csrw mcycle,  zero");
    __asm__ volatile ("csrw mcycleh, zero");
}

#define N 32
#define L 32
#define M 32

static uint8_t mA[N * L];
static uint8_t mB[L * M];
static uint8_t mC[N * M];

static void matmul(const uint8_t *A, const uint8_t *B, uint8_t *C,
                   int n, int l, int m)
{
    for (int i = 0; i < n; i++) {
        const uint8_t *rA = A + l * i;
        uint8_t *rC = C + m * i;
        for (int j = 0; j < m; j++) {
            const uint8_t *cB = B + j;
            uint8_t sum = 0;
            for (int k = 0; k < l; k++) {
                sum += rA[k] * cB[m * k];
            }
            rC[j] = sum;
        }
    }
}

static void init(uint8_t *mat, int len)
{
    for (int i = 0; i < len; i++)
        mat[i] = i % 4;
}

#define NUM_ITER 5

int main()
{
    RAL.SYSCFG->LSPA.UART[0].MR = 1;
    while (RAL.SYSCFG->LSPA.UART[0].MR);
    uart_init(&uart);

    enable_mcycle();

    printf("=== Benchmark: Matmul 32x32 (uint8) ===\n");

    init(mA, N * L);
    init(mB, L * M);

    uint32_t cycles[NUM_ITER];

    for (int n = 0; n < NUM_ITER; n++) {
        memset(mC, 0, sizeof(mC));

        uint32_t start = read_mcycle();
        matmul(mA, mB, mC, N, L, M);
        uint32_t end = read_mcycle();

        cycles[n] = end - start;

        /* Consume the output so the compiler cannot DCE the kernel. */
        uint32_t chk = 0;
        for (int i = 0; i < N * M; i++) chk += mC[i];
        __asm__ volatile ("" :: "r"(chk) : "memory");
        if (n == 0) printf("  checksum: 0x%08lx\n", (unsigned long)chk);
    }

    for (int n = 0; n < NUM_ITER; n++) {
        printf("  iter %d: %lu cycles\n", n, (unsigned long)cycles[n]);
    }

    printf("Done.\n");
    while (1) {}
}
