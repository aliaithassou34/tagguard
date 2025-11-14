#include "adam/HAL/timer.h"

void timer_init(timer_t *self)
{
    self->ral->PE = 0;

    self->ral->PR = SYSTEM_CLOCK / self->frequency;
    self->ral->VR = 0;

    switch(self->mode) {
        case TIMER_FREE_RUNNING:
            self->ral->ARR = ~0;
            self->ral->IER = 0;
            break;

        case TIMER_AUTO_RELOAD:
            self->ral->ARR = 0;
            self->ral->IER = 1;
            break;
    }
}

bool timer_handler(timer_t *self)
{
    if (self->ral->ER) {
        if (self->callback) self->callback();
        self->ral->ER = ~0;
        return 1;
    }
    return 0;
}
