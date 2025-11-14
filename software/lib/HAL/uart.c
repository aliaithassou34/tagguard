#include "adam/HAL/uart.h"

void uart_init(uart_t *self)
{
    self->ral->PE = 0;

    self->ral->BRR = SYSTEM_CLOCK / self->baud_rate;

    self->ral->TE = 1;
    self->ral->RE = 1;
    self->ral->DL = 8;
    self->ral->PE = 1;
}

void uart_write(uart_t *self, const void *buf, size_t count)
{
    const char *buf_char = (const char *) buf;

    for (size_t i = 0; i < count; i++) {
        while(!self->ral->TBE);
        self->ral->DR = *buf_char++;
    }
}

void uart_read(uart_t *self, void *buf, size_t count)
{
    char *buf_char = (char *) buf;

    for (size_t i = 0; i < count; i++) {
        while(!self->ral->RBF);
        *buf_char++ = self->ral->DR;
    }
}
