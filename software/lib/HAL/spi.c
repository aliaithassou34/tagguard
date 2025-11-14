#include "adam/HAL/spi.h"

void spi_init(spi_t *self)
{
    self->ral->PE = 0;

    self->ral->BRR = SYSTEM_CLOCK / self->baud_rate;

    self->ral->DL = 15;
    self->ral->DO = 1;
    self->ral->CPOL = 0;
    self->ral->CPHA = 0;
    self->ral->MS = 1;
    self->ral->RE = 1;
    self->ral->TE = 1;
    self->ral->PE = 1;
}

void spi_write(spi_t *self, const void *buf, size_t count)
{
    const char *buf_char = (const char *) buf;

    for (size_t i = 0; i < count; i++) {
        while(!self->ral->TBE);
        self->ral->DR = *buf_char++;
    }
}

void spi_read(spi_t *self, void *buf, size_t count)
{
    char *buf_char = (char *) buf;

    for (size_t i = 0; i < count; i++) {
        while(!self->ral->RBF);
        *buf_char++ = self->ral->DR;
    }
}
