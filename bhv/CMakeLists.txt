adam_sv_add_library(adam_bhv
  DEPENDS
    adam_rtl
    axi_bhv
    apb_bhv
  INCLUDES
    ../include
  SOURCES
    adam_clk_gate.sv

    adam_seq_bhv.sv

    pause/adam_pause_bhv.sv

    stream/adam_stream_mst_bhv.sv
    stream/adam_stream_slv_bhv.sv

    axil/adam_axil_mst_bhv.sv
    axil/adam_axil_slv_bhv.sv

    axil/adam_axil_apb_bridge_tb.sv
    axil/adam_axil_skid_tb.sv
    axil/adam_axil_pause_tb.sv
    axil/adam_axil_xbar_tb.sv
    axil/adam_axil_slv_simple_bhv.sv

    fabric/adam_fabric_hsdom_tb.sv
    fabric/adam_fabric_lsdom_tb.sv
    fabric/adam_fabric_lspx_tb.sv
    fabric/adam_fabric_tb.sv

    jtag/adam_jtag_mst_bhv.sv

    adam_dbg_mst_bhv.sv

    obi/adam_obi_from_axil_tb.sv

    pause/adam_pause_demux_tb.sv
    pause/adam_pause_mux_tb.sv

    periph/gpio/adam_periph_gpio_tb.sv
    periph/spi/adam_periph_spi_phy_tb.sv
    periph/spi/adam_periph_spi_tb.sv
    periph/timer/adam_periph_timer_tb.sv
    periph/uart/adam_periph_uart_rx_tb.sv
    periph/uart/adam_periph_uart_tx_tb.sv
    periph/uart/adam_periph_uart_tb.sv

    stream/adam_stream_skid_tb.sv

    syscfg/adam_syscfg_tgt_tb.sv
    syscfg/adam_syscfg_tb.sv

    adam_clk_div_tb.sv
    adam_tb.sv
)
