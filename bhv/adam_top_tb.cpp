#include "Vadam_top.h"
#include "verilated.h"

typedef Vadam_top dut_t;

const int uart_div = 50000000 / 115200;

int uart_tick = 0;
int uart_bit = -1;
char uart_buffer = 0;

void rtl_init(dut_t *dut)
{
    dut->clk_i = 0;
    dut->rst_i = 1;

    dut->hsdom_din_i = {0};
    dut->hsdom_din_valid_i = 0;

    dut->hsdom_dout_ready_i = 0;

    dut->jtag_tck_i = 0;
    dut->jtag_tms_i = 0;
    dut->jtag_tdi_i = 0;

    dut->lspa_gpio_io_i = {0};
    dut->lspa_spi_miso_i = {0};
    dut->lspa_uart_rx_i = {0};

    dut->lspb_gpio_io_i = {0};
    dut->lspb_spi_miso_i = {0};
    dut->lspb_uart_rx_i = {0};
}

void rtl_read(dut_t *dut)
{
    bool tx = dut->lspa_uart_tx_o;

    if (uart_tick != 0 || tx == 0) {
        printf("%d\n", uart_tick);
        if (++uart_tick % uart_div == uart_div / 2) ++uart_bit;

        if (uart_bit >= 8) {
            printf("%c", uart_buffer);
            uart_buffer = 0;
            uart_bit = -1;
        } else if (uart_bit >= 0) {
            uart_buffer |= (tx << uart_bit);
        }
    }
}

void rtl_write(dut_t *dut)
{
    if (Verilated::time() > 10) {
        dut->rst_i = 0;
        return;
    }
}

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Vadam_top* dut = new Vadam_top;

    rtl_init(dut);

    printf("Simulation started\n");

    while (1) {
        dut->eval();

        rtl_read(dut);
        Verilated::timeInc(1);
        dut->clk_i = 1;
        dut->eval();

        rtl_write(dut);
        Verilated::timeInc(1);
        dut->clk_i = 0;
        dut->eval();
    }

    dut->final();
    delete dut;
    return 0;
}
