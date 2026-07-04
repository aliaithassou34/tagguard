/* dift_autotaint — reads UART DR with HW auto-taint (no p.spsw), branches on
 * it, and expects a DIFT exception before "SHOULD NOT REACH" is printed. */

#include <stdio.h>
#include <string.h>
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

int main()
{
    RAL.SYSCFG->LSPA.UART[0].MR = 1;
    while (RAL.SYSCFG->LSPA.UART[0].MR);

    RAL.SYSCFG->LSPA.GPIO[0].MR = 1;
    while (RAL.SYSCFG->LSPA.GPIO[0].MR);

    uart_init(&uart);

    /* TCR: branch checks on both operands */
    write_tcr(0x00000018);

    printf("DIFT autotaint: TCR=0x18, enabling LSPA UART0 taint...\n");

    /* enable HW auto-taint on LSPA UART0 */
    RAL.SYSCFG->TAINT_SRC.DTSR = 0x10;

    /* load UART DR (tainted by adam_dift_periph_guard) into a pinned register */
    register uint32_t tainted_val __asm__("a0");
    __asm__ volatile (
        "lw  a0, 0(%[uart])"
        : "=r"(tainted_val)
        : [uart] "r" (RAL.LSPA.UART[0])
        : "memory"
    );

    /* branch on the tainted value; TCR fires a DIFT exception here */
    __asm__ volatile (
        "li   a1, 0\n\t"
        "beq  %[val], a1, 1f\n\t"
        "1:"
        :
        : [val] "r" (tainted_val)
        : "a1"
    );

    while (1) {
        __asm__ volatile ("nop");
    }
}