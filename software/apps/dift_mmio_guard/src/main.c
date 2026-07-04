/* dift_mmio_guard — forwards a HW auto-tainted UART byte to GPIO ODR; the
 * periph guard must squash the write and set MPS.LSPA_GPIO0_GUARD_FIRED. */

#include <stdint.h>

#include "adam_ral.h"
#include "adam/HAL/uart.h"

uart_t uart = {
    .ral = RAL.LSPA.UART[0],
    .baud_rate = 115200
};

static inline void write_tcr(uint32_t val)
{
    __asm__ volatile ("csrw 0x7C1, %0" : : "r"(val) : );
}

static inline void write_tpr(uint32_t val)
{
    __asm__ volatile ("csrw 0x7C0, %0" : : "r"(val) : );
}

int main(void)
{
    RAL.SYSCFG->LSPA.UART[0].MR = 1;
    while (RAL.SYSCFG->LSPA.UART[0].MR);

    RAL.SYSCFG->LSPA.GPIO[0].MR = 1;
    while (RAL.SYSCFG->LSPA.GPIO[0].MR);

    uart_init(&uart);

    RAL.LSPA.GPIO[0]->MODER = 0x000000FF; /* 8 bits as output */
    RAL.LSPA.GPIO[0]->ODR   = 0x0000005A; /* pre-attack sentinel */

    /* TPR: route rs2 tag into the store payload (OR policy), no TCR check needed */
    write_tpr(0x0000A000);
    write_tcr(0x00000000);

    RAL.SYSCFG->TAINT_SRC.DTSR = 0x10; /* LSPA_UART0_TAINT_EN */
    RAL.SYSCFG->TAINT_SRC.MPM  = 0x1;  /* LSPA_GPIO0_GUARD_EN */
    RAL.SYSCFG->TAINT_SRC.MPS  = 0x1;  /* clear any stale GPIO0 sticky bit */

    /* read a HW auto-tainted byte from UART RX */
    register uint32_t tainted_byte __asm__("a0");
    __asm__ volatile (
        "lw   a0, 0(%[dr])\n\t"
        :  "=r"(tainted_byte)
        :  [dr] "r" (&RAL.LSPA.UART[0]->DR)
        :  "memory"
    );

    /* forward it to GPIO ODR; the guard should squash this write */
    __asm__ volatile (
        "sw   %[val], 0(%[odr])"
        :
        :  [val] "r" (tainted_byte),
           [odr] "r" (&RAL.LSPA.GPIO[0]->ODR)
        :  "memory"
    );

    volatile uint32_t odr_after = RAL.LSPA.GPIO[0]->ODR;
    volatile uint32_t mps       = RAL.SYSCFG->TAINT_SRC.MPS;

    if ((mps & 0x1) && (odr_after == 0x5A)) {
        RAL.LSPA.GPIO[0]->ODR = 0x000000A5; /* guard fired, value preserved */
    } else {
        RAL.LSPA.GPIO[0]->ODR = 0x000000F0; /* unexpected: guard did not fire */
    }

    while (1) {
        __asm__ volatile ("nop");
    }
}
