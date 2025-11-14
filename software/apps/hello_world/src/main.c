#include <stdio.h>

#include "adam_ral.h"
#include "adam/HAL/uart.h"

uart_t uart = {
    .ral = RAL.LSPA.UART[0],
    .baud_rate = 115200
};

int main() {
    RAL.SYSCFG->LSPA.UART[0].MR = 1;
    while (RAL.SYSCFG->LSPA.UART[0].MR);

    uart_init(&uart);

    while (1) {
        printf("Hello, World!\n");
        for (volatile int i = 0; i < 10000; i++);
    }
}
