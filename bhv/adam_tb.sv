`timescale 1ns/1ps
`include "adam/macros_bhv.svh"
`include "vunit_defines.svh"

module adam_tb;
    import adam_dbg_mst_bhv::*;

    `ADAM_BHV_CFG_LOCALPARAMS;

    // lsdom ==================================================================

    ADAM_SEQ   lsdom_seq ();
    ADAM_PAUSE lsdom_pause_ext ();

    adam_seq_bhv #(
        `ADAM_BHV_CFG_PARAMS_MAP
    ) lsdom_adam_seq_bhv (
        .seq (lsdom_seq)
    );

    `ADAM_PAUSE_MST_TIE_ON(lsdom_pause_ext);

    // hsdom ==================================================================

    ADAM_SEQ hsdom_seq ();

    adam_seq_bhv #(
        `ADAM_BHV_CFG_PARAMS_MAP
    ) hsdom_adam_seq_bhv (
        .seq (hsdom_seq)
    );

    din_t hsdom_din;
    logic hsdom_din_valid;
    logic hsdom_din_ready;

    assign hsdom_din = 'hDEAD_BEEF;
    assign hsdom_din_valid = 1;

    dout_t hsdom_dout;
    logic  hsdom_dout_valid;
    logic  hsdom_dout_ready;

    assign hsdom_dout_ready = 1;

    // lspa io ================================================================

    ADAM_IO     lspa_gpio_io   [NO_LSPA_GPIOS*GPIO_WIDTH+1] ();
    logic [1:0] lspa_gpio_func [NO_LSPA_GPIOS*GPIO_WIDTH+1];

    ADAM_IO lspa_spi_sclk [NO_LSPA_SPIS+1] ();
    ADAM_IO lspa_spi_mosi [NO_LSPA_SPIS+1] ();
    ADAM_IO lspa_spi_miso [NO_LSPA_SPIS+1] ();
    ADAM_IO lspa_spi_ss_n [NO_LSPA_SPIS+1] ();

    ADAM_IO lspa_uart_tx [NO_LSPA_UARTS+1] ();
    ADAM_IO lspa_uart_rx [NO_LSPA_UARTS+1] ();

    for (genvar i = 0; i < NO_LSPA_GPIOS; i++) begin
        `ADAM_IO_SLV_TIE_OFF(lspa_gpio_io[i]);
    end
    for (genvar i = 0; i < NO_LSPA_SPIS; i++) begin
        `ADAM_IO_SLV_TIE_OFF(lspa_spi_sclk[i]);
        `ADAM_IO_SLV_TIE_OFF(lspa_spi_mosi[i]);
        `ADAM_IO_SLV_TIE_OFF(lspa_spi_miso[i]);
        `ADAM_IO_SLV_TIE_OFF(lspa_spi_ss_n[i]);
    end
    for (genvar i = 0; i < NO_LSPA_UARTS; i++) begin
        `ADAM_IO_SLV_TIE_OFF(lspa_uart_tx[i]);
        `ADAM_IO_SLV_TIE_OFF(lspa_uart_rx[i]);
    end

    // lspb io ================================================================

    ADAM_IO     lspb_gpio_io   [NO_LSPB_GPIOS*GPIO_WIDTH+1] ();
    logic [1:0] lspb_gpio_func [NO_LSPB_GPIOS*GPIO_WIDTH+1];

    ADAM_IO lspb_spi_sclk [NO_LSPB_SPIS+1] ();
    ADAM_IO lspb_spi_mosi [NO_LSPB_SPIS+1] ();
    ADAM_IO lspb_spi_miso [NO_LSPB_SPIS+1] ();
    ADAM_IO lspb_spi_ss_n [NO_LSPB_SPIS+1] ();

    ADAM_IO lspb_uart_tx [NO_LSPB_UARTS+1] ();
    ADAM_IO lspb_uart_rx [NO_LSPB_UARTS+1] ();

    for (genvar i = 0; i < NO_LSPB_GPIOS; i++) begin
        `ADAM_IO_SLV_TIE_OFF(lspb_gpio_io[i]);
    end
    for (genvar i = 0; i < NO_LSPB_SPIS; i++) begin
        `ADAM_IO_SLV_TIE_OFF(lspb_spi_sclk[i]);
        `ADAM_IO_SLV_TIE_OFF(lspb_spi_mosi[i]);
        `ADAM_IO_SLV_TIE_OFF(lspb_spi_miso[i]);
        `ADAM_IO_SLV_TIE_OFF(lspb_spi_ss_n[i]);
    end
    for (genvar i = 0; i < NO_LSPB_UARTS; i++) begin
        `ADAM_IO_SLV_TIE_OFF(lspb_uart_tx[i]);
        `ADAM_IO_SLV_TIE_OFF(lspb_uart_rx[i]);
    end

    // debug ==================================================================

    ADAM_JTAG jtag ();

    adam_dbg_mst_bhv #(
       `ADAM_BHV_CFG_PARAMS_MAP
    ) dbg_bhv;

    // dut ====================================================================

    adam #(
        `ADAM_CFG_PARAMS_MAP
    ) dut (
        .lsdom_seq       (lsdom_seq),
        .lsdom_pause_ext (lsdom_pause_ext),

        .hsdom_seq (hsdom_seq),

        .hsdom_din_i       (hsdom_din),
        .hsdom_din_valid_i (hsdom_din_valid),
        .hsdom_din_ready_o (hsdom_din_ready),

        .hsdom_dout_o       (hsdom_dout),
        .hsdom_dout_valid_o (hsdom_dout_valid),
        .hsdom_dout_ready_i (hsdom_dout_ready),

        .jtag (jtag),

        .lspa_gpio_io   (lspa_gpio_io),
        .lspa_gpio_func (lspa_gpio_func),

        .lspa_spi_sclk (lspa_spi_sclk),
        .lspa_spi_mosi (lspa_spi_mosi),
        .lspa_spi_miso (lspa_spi_miso),
        .lspa_spi_ss_n (lspa_spi_ss_n),

        .lspa_uart_tx (lspa_uart_tx),
        .lspa_uart_rx (lspa_uart_rx),

        .lspb_gpio_io   (lspb_gpio_io),
        .lspb_gpio_func (lspb_gpio_func),

        .lspb_spi_sclk (lspb_spi_sclk),
        .lspb_spi_mosi (lspb_spi_mosi),
        .lspb_spi_miso (lspb_spi_miso),
        .lspb_spi_ss_n (lspb_spi_ss_n),

        .lspb_uart_tx (lspb_uart_tx),
        .lspb_uart_rx (lspb_uart_rx)
    );

    // test ===================================================================

    initial begin
        #1000us $error("timeout");
    end

    `TEST_SUITE begin
        `TEST_CASE("minimal") begin
            dbg_bhv = new(jtag);
            #10us;
        end
        `TEST_CASE("debug") begin
            ADDR_T  addr;
            DATA_T  wdata;
            DATA_T  rdata;

            addr  = 32'h0100_0000;
            wdata = 32'hDEAD_BEEF;

            dbg_bhv = new(jtag);

            if (EN_DEBUG) begin
                dbg_bhv.dtm_init();
                dbg_bhv.dm_init();
                dbg_bhv.dm_select('d1); // HART 1 aka CPU0
                dbg_bhv.dm_halt();
                if (EN_BOOTSTRAP_MEM0) begin
                    dbg_bhv.dm_sb_write(addr, wdata);
                    dbg_bhv.dm_sb_read(addr, rdata);
                    assert(rdata == wdata);
                end
                dbg_bhv.dm_resume();
            end
        end
    end
endmodule
