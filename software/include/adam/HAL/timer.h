#pragma once

#include <stdint.h>
#include <stdbool.h>

#include "adam_ral.h"

typedef enum {
    TIMER_FREE_RUNNING = 0,
    TIMER_AUTO_RELOAD
} timer_mode_t;

typedef struct {
    ral_timer_t *ral;
    timer_mode_t mode;
    int frequency;
    void (*callback)(void);
} timer_t;

void timer_init(timer_t *self);

bool timer_handler(timer_t *self);

static inline void timer_start(timer_t *self)
{
    self->ral->VR = 0;
    self->ral->PE = 1;
}

static inline void timer_stop(timer_t *self)
{
    self->ral->PE = 0;
}

static inline int timer_read(timer_t *self)
{
    return self->ral->VR;
}
