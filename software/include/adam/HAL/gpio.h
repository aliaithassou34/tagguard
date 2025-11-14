#pragma once

#include <stdint.h>
#include <stdbool.h>

#include "adam_ral.h"

typedef enum {
  GPIO_MODE_INPUT = 0,
  GPIO_MODE_OUTPUT,
  GPIO_MODE_ODRAIN
} gpio_mode_t;

typedef struct {
  ral_gpio_t *ral;
} gpio_t;

void gpio_init(gpio_t *self);

static inline void gpio_set_mode(gpio_t *self, int pin, gpio_mode_t mode)
{
    if (pin < 0) return;

    int mask = (1 << pin);

    if (mode != GPIO_MODE_INPUT) {
        self->ral->MODER |= mask;
    } else {
        self->ral->MODER &= ~mask;
    }

    if (mode == GPIO_MODE_ODRAIN) {
        self->ral->OTYPER |= mask;
    } else {
        self->ral->OTYPER &= ~mask;
    }
}

static inline void gpio_write(gpio_t *self, int pin, bool value)
{
    if (pin < 0) return;

    int mask = (1 << pin);

    if (value) {
        self->ral->ODR |= mask;
    } else {
        self->ral->ODR &= ~mask;
    }
}

static inline bool gpio_read(gpio_t *self, int pin)
{
    if (pin < 0) return 0;

    int mask = (1 << pin);

    return (self->ral->IDR & mask) ? 1 : 0;
}
