#ifndef ADAM_DIFT_BOOT_H
#define ADAM_DIFT_BOOT_H

#include <stdint.h>

typedef struct {
    uintptr_t start;
    uintptr_t end;
} adam_dift_range_t;

enum {
    ADAM_DIFT_STATUS_BOOTED = 0xD1F70010u,
    ADAM_DIFT_STATUS_EMULATED = 0x0000E001u,
    ADAM_DIFT_STATUS_DONE = 0xD1F70020u,
    ADAM_DIFT_STATUS_ATTACK = 0xD1F70002u
};

extern volatile uint32_t adam_dift_runtime_status;
extern volatile uint32_t adam_dift_runtime_emulated;
extern volatile uint32_t adam_dift_runtime_fault_mepc;
extern volatile uint32_t adam_dift_runtime_fault_mcause;
extern volatile uint32_t adam_dift_runtime_fault_insn;
extern volatile uint32_t adam_dift_runtime_mtvec_readback;
extern volatile uint32_t adam_dift_runtime_boot_tpr;
extern volatile uint32_t adam_dift_runtime_boot_tcr;
extern volatile uint32_t adam_dift_runtime_startup_cycles;
extern volatile uint32_t adam_dift_runtime_emulation_cycles;
extern volatile uint32_t adam_dift_runtime_total_cycles;

static inline uint32_t adam_dift_read_mcycle(void)
{
    uint32_t value;
    __asm__ volatile ("csrr %0, mcycle" : "=r"(value));
    return value;
}

uint32_t adam_dift_should_emulate_branch(uintptr_t branch_pc);

#endif
