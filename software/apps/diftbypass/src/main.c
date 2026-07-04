#include <stdint.h>

/* p.spsw/p.spsh/p.spsb: S-type tag-only stores (we=1, be=0, no data write) */
static inline void p_spsw(volatile void *addr)
{
    __asm__ volatile (
        ".insn s 0x23, 7, x0, 0(%0)"
        : : "r"(addr) : "memory"
    );
}

static inline void p_spsh(volatile void *addr)
{
    __asm__ volatile (
        ".insn s 0x23, 6, x0, 0(%0)"
        : : "r"(addr) : "memory"
    );
}

static inline void p_spsb(volatile void *addr)
{
    __asm__ volatile (
        ".insn s 0x23, 5, x0, 0(%0)"
        : : "r"(addr) : "memory"
    );
}

int main()
{
    /* addresses at the end of MEM1, away from .bss/heap/stack */
    volatile uint32_t *word_addr = (volatile uint32_t *)0x410FF000;
    volatile uint16_t *half_addr = (volatile uint16_t *)0x410FF010;
    volatile uint8_t  *byte_addr = (volatile uint8_t  *)0x410FF020;

    p_spsw(word_addr);
    p_spsh(half_addr);
    p_spsb(byte_addr);

    volatile uint32_t word_val;
    volatile uint16_t half_val;
    volatile uint8_t  byte_val;

    __asm__ volatile ("lw %0, 0(%1)" : "=r"(word_val) : "r"(word_addr) : "memory");
    __asm__ volatile ("lh %0, 0(%1)" : "=r"(half_val) : "r"(half_addr) : "memory");
    __asm__ volatile ("lb %0, 0(%1)" : "=r"(byte_val) : "r"(byte_addr) : "memory");

    while (1) {}
}
