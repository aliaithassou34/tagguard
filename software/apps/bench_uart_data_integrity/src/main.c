#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "adam/HAL/uart.h"
#include "adam/dift_boot.h"
#include "adam_ral.h"

#define INPUT_LEN 16u
#define LSPA_UART0_TAINT_EN 0x10u

enum {
    BENCH_UART_DATA_INTEGRITY_DONE = 0xD17F0001u,
    BENCH_UART_DATA_INTEGRITY_GOLD_FLETCHER = 0x00004259u,
    BENCH_UART_DATA_INTEGRITY_GOLD_XOR = 0x767B681Au,
    BENCH_UART_DATA_INTEGRITY_GOLD_WEIGHTED = 0x000023A7u
};

uart_t uart = {
    .ral = RAL.LSPA.UART[0],
    .baud_rate = 115200
};

volatile uint32_t bench_uart_data_integrity_status;
volatile uint32_t bench_uart_data_integrity_fletcher;
volatile uint32_t bench_uart_data_integrity_xor;
volatile uint32_t bench_uart_data_integrity_weighted;
volatile uint32_t bench_uart_data_integrity_expected_fletcher = BENCH_UART_DATA_INTEGRITY_GOLD_FLETCHER;
volatile uint32_t bench_uart_data_integrity_expected_xor = BENCH_UART_DATA_INTEGRITY_GOLD_XOR;
volatile uint32_t bench_uart_data_integrity_expected_weighted = BENCH_UART_DATA_INTEGRITY_GOLD_WEIGHTED;

static volatile uint8_t input_buf[INPUT_LEN];

static void init_uart(void)
{
    RAL.SYSCFG->LSPA.UART[0].MR = 1;
    while (RAL.SYSCFG->LSPA.UART[0].MR) {
    }

    uart_init(&uart);
}

static __attribute__((noinline)) void compute_data_integrity(void)
{
    uint32_t sum1 = 0u;
    uint32_t sum2 = 0u;
    uint32_t xor_mix = 0u;
    uint32_t weighted = 0u;

    for (uint32_t i = 0u; i < INPUT_LEN; ++i) {
        uint32_t byte = input_buf[i];

        sum1 = (sum1 + byte) & 0xffu;
        sum2 = (sum2 + sum1) & 0xffu;
        xor_mix ^= byte << ((i & 3u) * 8u);
        weighted += byte * (i + 1u);
    }

    bench_uart_data_integrity_fletcher = (sum2 << 8) | sum1;
    bench_uart_data_integrity_xor = xor_mix;
    bench_uart_data_integrity_weighted = weighted;
}

int main(void)
{
    init_uart();

    memset((void *)input_buf, 0, sizeof(input_buf));
    bench_uart_data_integrity_status = 0u;
    bench_uart_data_integrity_fletcher = 0u;
    bench_uart_data_integrity_xor = 0u;
    bench_uart_data_integrity_weighted = 0u;

    printf("=== UART data-integrity DIFT benchmark ===\n");
    printf("Send %u bytes: DIFTBENCHUART123\n", (unsigned int)INPUT_LEN);

#ifndef ADAM_DIFT_BOOT_DTSR
    RAL.SYSCFG->TAINT_SRC.DTSR = LSPA_UART0_TAINT_EN;
#endif
    uart_read(&uart, (char *)input_buf, INPUT_LEN);

    compute_data_integrity();
    bench_uart_data_integrity_status = BENCH_UART_DATA_INTEGRITY_DONE;

    printf("runtime_status=0x%08lx emulated=%lu\n",
           (unsigned long)adam_dift_runtime_status,
           (unsigned long)adam_dift_runtime_emulated);
    printf("startup_cycles=%lu\n",
           (unsigned long)adam_dift_runtime_startup_cycles);
    printf("DONE\n");

    while (1) {
    }
}