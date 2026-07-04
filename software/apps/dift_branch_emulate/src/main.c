#include <stdint.h>

volatile uint32_t dift_branch_emulate_status;
volatile uint32_t dift_branch_emulate_emulated;
volatile uint32_t dift_branch_emulate_fault_mepc;
volatile uint32_t dift_branch_emulate_fault_mcause;
volatile uint32_t dift_branch_emulate_fault_insn;
volatile uint32_t dift_branch_emulate_trusted_result;
volatile uint32_t dift_branch_emulate_mtvec_readback;

static volatile uint32_t tagged_word = 1;

extern void default_handler(void);
extern uint32_t trusted_branch_probe(uint32_t value);

static inline void install_direct_trap_handler(void)
{
    uintptr_t handler = (uintptr_t)&default_handler;
    __asm__ volatile ("csrw mtvec, %0" :: "r"(handler) : "memory");
}

static inline void p_spsw(volatile void *addr)
{
    __asm__ volatile (".insn s 0x23, 7, x0, 0(%0)" :: "r"(addr) : "memory");
}

static inline void write_tcr(uint32_t value)
{
    __asm__ volatile ("csrw 0x7C1, %0" :: "r"(value) : "memory");
}

static inline uintptr_t read_mtvec(void)
{
    uintptr_t value;
    __asm__ volatile ("csrr %0, mtvec" : "=r"(value));
    return value;
}

int main(void)
{
    dift_branch_emulate_status = 0x100u;
    dift_branch_emulate_emulated = 0;
    dift_branch_emulate_fault_mepc = 0;
    dift_branch_emulate_fault_mcause = 0;
    dift_branch_emulate_fault_insn = 0;
    dift_branch_emulate_trusted_result = 0;
    dift_branch_emulate_mtvec_readback = 0;

    tagged_word = 1;
    p_spsw(&tagged_word);

    install_direct_trap_handler();
    dift_branch_emulate_mtvec_readback = (uint32_t)read_mtvec();
    write_tcr(0x00000018u);

    dift_branch_emulate_status = 0x200u;
    dift_branch_emulate_trusted_result = trusted_branch_probe(tagged_word);
    dift_branch_emulate_status = 0x300u;

    if (dift_branch_emulate_trusted_result != 1u || dift_branch_emulate_emulated == 0u) {
        dift_branch_emulate_status = 0xBAD10000u;
        while (1) {
            __asm__ volatile ("nop");
        }
    }

    dift_branch_emulate_status = 0x400u;

    __asm__ volatile (
        "lw   a0, 0(%0)\n\t"
        "li   t0, 0\n\t"
        "beq  a0, t0, 1f\n\t"
        "nop\n"
        "1:"
        :: "r"(&tagged_word)
        : "a0", "t0", "memory"
    );

    dift_branch_emulate_status = 0xDEAD0000u;
    while (1) {
        __asm__ volatile ("nop");
    }
}