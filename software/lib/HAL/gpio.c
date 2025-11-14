#include "adam/HAL/gpio.h"

void gpio_init(gpio_t *self)
{
    self->ral->ODR = 0;
    self->ral->MODER = 0;
    self->ral->OTYPER = 0;
    //self->ral->FSR = 0;
    self->ral->IER = 0;
}
