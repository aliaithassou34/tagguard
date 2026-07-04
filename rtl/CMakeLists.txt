adam_sv_add_library(adam_rtl
  DEPENDS
    axi_rtl
    apb_rtl
    riscv_dbg_rtl
  DEFINITIONS
    VERILATOR=
  INCLUDES
    ../include
  SOURCES
    intf/adam_intf_io.sv
    intf/adam_intf_jtag.sv
    intf/adam_intf_pause.sv
    intf/adam_intf_seq.sv
    intf/adam_intf_stream.sv

    pause/adam_pause_demux.sv
    pause/adam_pause_mux.sv

    stream/adam_stream_skid.sv

    axil/adam_axil_apb_bridge.sv
    axil/adam_axil_pause.sv
    axil/adam_axil_skid.sv
    axil/adam_axil_to_mem.sv
    axil/adam_axil_xbar.sv

    debug/adam_debug.sv

    obi/adam_obi_from_axil.sv
    obi/adam_obi_to_axil.sv

    periph/gpio/adam_periph_gpio.sv
    periph/spi/adam_periph_spi.sv
    periph/spi/adam_periph_spi_phy.sv
    periph/timer/adam_periph_timer.sv
    periph/uart/adam_periph_uart_rx.sv
    periph/uart/adam_periph_uart_tx.sv
    periph/uart/adam_periph_uart.sv
    periph/adam_periph.sv
    periph/adam_periph_hawkeye.sv

    syscfg/adam_syscfg_tgt.sv
    syscfg/adam_syscfg.sv

    fabric/adam_fabric_hsdom.sv
    fabric/adam_fabric_lsdom.sv
    fabric/adam_fabric_lspx.sv
    fabric/adam_fabric.sv

    adam_dift_periph_guard.sv
    adam_mem.sv
    adam.sv
    adam_clk_div.sv
    adam_top.sv
)

add_subdirectory(cores)
