#include "adam/dift_boot.h"

#ifndef ADAM_DIFT_BOOT_TPR
#define ADAM_DIFT_BOOT_TPR 0x0000A8A2u
#endif

#ifndef ADAM_DIFT_BOOT_TCR
#define ADAM_DIFT_BOOT_TCR 0x00200018u
#endif

#ifndef ADAM_DIFT_DEFAULT_EMULATE
#define ADAM_DIFT_DEFAULT_EMULATE 1u
#endif

#ifndef ADAM_DIFT_USE_PROTECTED
#define ADAM_DIFT_USE_PROTECTED 1u
#endif

#ifndef ADAM_DIFT_BOOT_DTSR
#define ADAM_DIFT_BOOT_DTSR 0u
#endif

#if ADAM_DIFT_BOOT_DTSR != 0
#include "adam_ral.h"
#endif

extern void default_handler(void);
extern const adam_dift_range_t __adam_dift_trusted_start[];
extern const adam_dift_range_t __adam_dift_trusted_end[];
extern const adam_dift_range_t __adam_dift_protected_start[];
extern const adam_dift_range_t __adam_dift_protected_end[];

volatile uint32_t adam_dift_runtime_status;
volatile uint32_t adam_dift_runtime_emulated;
volatile uint32_t adam_dift_runtime_fault_mepc;
volatile uint32_t adam_dift_runtime_fault_mcause;
volatile uint32_t adam_dift_runtime_fault_insn;
volatile uint32_t adam_dift_runtime_mtvec_readback;
volatile uint32_t adam_dift_runtime_boot_tpr;
volatile uint32_t adam_dift_runtime_boot_tcr;
volatile uint32_t adam_dift_runtime_startup_cycles;
volatile uint32_t adam_dift_runtime_emulation_cycles;
volatile uint32_t adam_dift_runtime_total_cycles;

static inline void adam_dift_reset_mcycle(void)
{
    __asm__ volatile ("csrw 0x320, zero" ::: "memory");
    __asm__ volatile ("csrw mcycle, zero" ::: "memory");
    __asm__ volatile ("csrw mcycleh, zero" ::: "memory");
}

static inline void adam_dift_write_tpr(uint32_t value)
{
    __asm__ volatile ("csrw 0x7C0, %0" :: "r"(value) : "memory");
}

static inline void adam_dift_write_tcr(uint32_t value)
{
    __asm__ volatile ("csrw 0x7C1, %0" :: "r"(value) : "memory");
}

static inline void adam_dift_write_mtvec(uintptr_t value)
{
    __asm__ volatile ("csrw mtvec, %0" :: "r"(value) : "memory");
}

static inline uintptr_t adam_dift_read_mtvec(void)
{
    uintptr_t value;
    __asm__ volatile ("csrr %0, mtvec" : "=r"(value));
    return value;
}

static uint32_t adam_dift_pc_in_ranges(uintptr_t pc,
                                       const adam_dift_range_t *start,
                                       const adam_dift_range_t *end)
{
    for (const adam_dift_range_t *range = start; range < end; ++range) {
        if (range->start == 0u || range->end <= range->start) {
            continue;
        }

        if (pc >= range->start && pc < range->end) {
            return 1u;
        }
    }

    return 0u;
}

uint32_t adam_dift_should_emulate_branch(uintptr_t branch_pc)
{
#if ADAM_DIFT_USE_PROTECTED != 0
    if (adam_dift_pc_in_ranges(branch_pc,
                               __adam_dift_protected_start,
                               __adam_dift_protected_end)) {
        return 0u;
    }
#endif

    if (adam_dift_pc_in_ranges(branch_pc,
                               __adam_dift_trusted_start,
                               __adam_dift_trusted_end)) {
        return 1u;
    }

    return ADAM_DIFT_DEFAULT_EMULATE != 0u;
}

__attribute__((constructor(101), used))
static void adam_dift_boot_init(void)
{
    adam_dift_reset_mcycle();

    uintptr_t handler = (uintptr_t)&default_handler;

    adam_dift_runtime_status = 0u;
    adam_dift_runtime_emulated = 0u;
    adam_dift_runtime_emulation_cycles = 0u;
    adam_dift_runtime_total_cycles = 0u;
    adam_dift_runtime_fault_mepc = 0u;
    adam_dift_runtime_fault_mcause = 0u;
    adam_dift_runtime_fault_insn = 0u;

    adam_dift_write_mtvec(handler);
    adam_dift_runtime_mtvec_readback = (uint32_t)adam_dift_read_mtvec();

    adam_dift_runtime_boot_tpr = ADAM_DIFT_BOOT_TPR;
    adam_dift_runtime_boot_tcr = ADAM_DIFT_BOOT_TCR;
    adam_dift_write_tpr(ADAM_DIFT_BOOT_TPR);
    adam_dift_write_tcr(ADAM_DIFT_BOOT_TCR);

#if ADAM_DIFT_BOOT_DTSR != 0
    RAL.SYSCFG->TAINT_SRC.DTSR = ADAM_DIFT_BOOT_DTSR;
#endif

    adam_dift_runtime_startup_cycles = adam_dift_read_mcycle();
    adam_dift_runtime_status = ADAM_DIFT_STATUS_BOOTED;
}
