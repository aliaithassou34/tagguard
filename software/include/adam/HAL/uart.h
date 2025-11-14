#pragma once

#include <stddef.h>

#include "adam_ral.h"

typedef struct {
    ral_uart_t *ral;
    int baud_rate;
} uart_t;

void uart_init(uart_t *self);
void uart_write(uart_t *self, const void *buf, size_t count);
void uart_read(uart_t *self, void *buf, size_t count);
