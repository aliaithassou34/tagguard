#pragma once

#include <stddef.h>

#include "adam_ral.h"

typedef struct {
    ral_spi_t *ral;
    int baud_rate;
} spi_t;

void spi_init(spi_t *self);
void spi_write(spi_t *self, const void *buf, size_t count);
void spi_read(spi_t *self, void *buf, size_t count);
