#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "adam/HAL/uart.h"
#include "adam/dift_boot.h"
#include "adam_ral.h"

#define COMMAND_LEN 10u
#define LSPA_UART0_TAINT_EN 0x10u

enum {
    BENCH_UART_COMMAND_FP_INVALID = 0xBAD00000u,
    BENCH_UART_COMMAND_FP_SET_LED7 = 0xC0DE0007u,
    BENCH_UART_COMMAND_FP_ACTION_OK = 0xF00D0007u,
    BENCH_UART_COMMAND_FP_DONE = 0xD1F70077u
};

uart_t uart = {
    .ral = RAL.LSPA.UART[0],
    .baud_rate = 115200
};

volatile uint32_t bench_uart_command_fp_status;
volatile uint32_t bench_uart_command_fp_result;
volatile uint32_t bench_uart_command_fp_action;
volatile uint32_t bench_uart_command_fp_expected_result = BENCH_UART_COMMAND_FP_SET_LED7;
volatile uint32_t bench_uart_command_fp_expected_action = BENCH_UART_COMMAND_FP_ACTION_OK;

static volatile char input_buf[COMMAND_LEN + 1u];

uint32_t __attribute__((section(".text.bench_uart_command_trusted"), noinline, used))
bench_uart_command_trusted_parse(const volatile char *input)
{
    if (input[0] != 'S') {
        return BENCH_UART_COMMAND_FP_INVALID;
    }
    if (input[1] != 'E') {
        return BENCH_UART_COMMAND_FP_INVALID;
    }
    if (input[2] != 'T') {
        return BENCH_UART_COMMAND_FP_INVALID;
    }
    if (input[3] != ' ') {
        return BENCH_UART_COMMAND_FP_INVALID;
    }
    if (input[4] != 'L') {
        return BENCH_UART_COMMAND_FP_INVALID;
    }
    if (input[5] != 'E') {
        return BENCH_UART_COMMAND_FP_INVALID;
    }
    if (input[6] != 'D') {
        return BENCH_UART_COMMAND_FP_INVALID;
    }
    if (input[7] != ' ') {
        return BENCH_UART_COMMAND_FP_INVALID;
    }
    if (input[8] != '7') {
        return BENCH_UART_COMMAND_FP_INVALID;
    }

    return BENCH_UART_COMMAND_FP_SET_LED7;
}

static void init_uart(void)
{
    RAL.SYSCFG->LSPA.UART[0].MR = 1;
    while (RAL.SYSCFG->LSPA.UART[0].MR) {
    }

    uart_init(&uart);
}

int main(void)
{
    init_uart();

    memset((void *)input_buf, 0, sizeof(input_buf));
    bench_uart_command_fp_status = 0u;
    bench_uart_command_fp_result = BENCH_UART_COMMAND_FP_INVALID;
    bench_uart_command_fp_action = 0u;

    printf("=== UART command false-positive benchmark ===\n");
    printf("Send %u-byte command: SET LED 7\\n\n", (unsigned int)COMMAND_LEN);

#ifndef ADAM_DIFT_BOOT_DTSR
    RAL.SYSCFG->TAINT_SRC.DTSR = LSPA_UART0_TAINT_EN;
#endif
    uart_read(&uart, (char *)input_buf, COMMAND_LEN);
    input_buf[COMMAND_LEN] = '\0';

    bench_uart_command_fp_result = bench_uart_command_trusted_parse(input_buf);

    if (bench_uart_command_fp_result == BENCH_UART_COMMAND_FP_SET_LED7) {
        bench_uart_command_fp_action = BENCH_UART_COMMAND_FP_ACTION_OK;
    } else {
        bench_uart_command_fp_action = BENCH_UART_COMMAND_FP_INVALID;
    }

    bench_uart_command_fp_status = BENCH_UART_COMMAND_FP_DONE;

    adam_dift_runtime_total_cycles = adam_dift_read_mcycle();

    printf("runtime_status=0x%08lx emulated=%lu\n",
           (unsigned long)adam_dift_runtime_status,
           (unsigned long)adam_dift_runtime_emulated);
    printf("startup_cycles=%lu\n",
           (unsigned long)adam_dift_runtime_startup_cycles);
    printf("emulation_cycles=%lu\n",
           (unsigned long)adam_dift_runtime_emulation_cycles);
    printf("total_cycles=%lu\n",
           (unsigned long)adam_dift_runtime_total_cycles);
    printf("DONE\n");

    while (1) {
    }
}