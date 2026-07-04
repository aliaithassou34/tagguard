#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "adam/HAL/uart.h"
#include "adam/dift_boot.h"
#include "adam_ral.h"

#define INPUT_LEN 16u
#define WORK_LEN 48u
#define COTS_PROGRESS_BASE 0xD1F70100u

uart_t uart = {
    .ral = RAL.LSPA.UART[0],
    .baud_rate = 115200
};

static volatile uint32_t sink_word;
static volatile char sink_byte;

static inline void mark_progress(uint32_t step)
{
    adam_dift_runtime_status = COTS_PROGRESS_BASE | step;
}

static void init_uart(void)
{
    RAL.SYSCFG->LSPA.UART[0].MR = 1;
    while (RAL.SYSCFG->LSPA.UART[0].MR) {
    }

    uart_init(&uart);
}

static __attribute__((noinline)) void exercise_trusted_runtime(char *input)
{
    char local[WORK_LEN];
    char mirror[WORK_LEN];
    char *heap = (char *)malloc(WORK_LEN);
    mark_progress(1u);

    if (heap == NULL) {
        printf("bench_cots_trusted_runtime: malloc failed\n");
        return;
    }

    memset(local, 0, sizeof(local));
    memset(mirror, 0, sizeof(mirror));
    mark_progress(2u);

    memcpy(local, input, INPUT_LEN);
    local[INPUT_LEN] = '\0';
    mark_progress(3u);

    strcpy(heap, local);
    mark_progress(4u);

    strncpy(mirror, heap, INPUT_LEN);
    mirror[INPUT_LEN] = '\0';
    mark_progress(5u);

    sink_word ^= (uint32_t)strlen(heap);
    mark_progress(6u);

    sink_word ^= (uint32_t)strnlen(mirror, INPUT_LEN);
    mark_progress(7u);

    sink_word ^= (uint32_t)strcmp(heap, mirror);
    mark_progress(8u);

    sink_word ^= (uint32_t)strncmp(heap, mirror, INPUT_LEN);
    mark_progress(9u);

    sink_word ^= (uint32_t)atoi(heap);
    mark_progress(10u);

    sink_byte = *(char *)memchr(heap, heap[0], INPUT_LEN);
    mark_progress(11u);

    free(heap);

    adam_dift_runtime_total_cycles = adam_dift_read_mcycle();
    adam_dift_runtime_status = ADAM_DIFT_STATUS_DONE;
    printf("trusted-runtime benign input processed\n");
}

int main(void)
{
    char input[WORK_LEN];

    init_uart();

    memset(input, 0, sizeof(input));

    printf("=== COTS trusted-runtime false-positive probe ===\n");
    printf("Send %u benign bytes on UART.\n", (unsigned int)INPUT_LEN);

    uart_read(&uart, input, INPUT_LEN);
    input[INPUT_LEN] = '\0';

    exercise_trusted_runtime(input);

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
