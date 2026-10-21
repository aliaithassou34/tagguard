`timescale 1ns/1ps
`include "adam/macros_bhv.svh"
`include "vunit_defines.svh"

module adam_dift_tb;
    import adam_dbg_mst_bhv::*;

    `ADAM_BHV_CFG_LOCALPARAMS;

    localparam int unsigned LSPA_GPIO0_DIFT_BIT = 0;
    localparam int unsigned LSPA_UART0_DIFT_BIT =
        NO_LSPA_GPIOS + NO_LSPA_SPIS + NO_LSPA_TIMERS;

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
    logic   lspa_uart_rx0_i = 1'b1;

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
        if (i == 0) begin : gen_lspa_uart_rx0
            assign lspa_uart_rx[i].i = lspa_uart_rx0_i;
        end else begin : gen_lspa_uart_rx_tieoff
            `ADAM_IO_SLV_TIE_OFF(lspa_uart_rx[i]);
        end
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
        #300000us $error("global timeout");
    end

    // Drive each bit for an exact number of UART (LSPA) clock cycles so the
    // waveform is phase-locked to the RX's cycle counting. The count matches
    // the RX effective cycles-per-bit (`ADAM_UART_SIM_CYCLES_PER_BIT`).
    task automatic send_lspa_uart_byte(input logic [7:0] data);
        lspa_uart_rx0_i = 1'b0;
        repeat (`ADAM_UART_SIM_CYCLES_PER_BIT) @(posedge lsdom_seq.clk);
        for (int bit_idx = 0; bit_idx < 8; bit_idx++) begin
            lspa_uart_rx0_i = data[bit_idx];
            repeat (`ADAM_UART_SIM_CYCLES_PER_BIT) @(posedge lsdom_seq.clk);
        end
        lspa_uart_rx0_i = 1'b1;
        repeat (2 * `ADAM_UART_SIM_CYCLES_PER_BIT) @(posedge lsdom_seq.clk);
    endtask

    localparam int PAYLOAD_NEG1A         = 1;
    localparam int PAYLOAD_BSS_FUNCPTR   = 2;
    localparam int PAYLOAD_20_A          = 3;
    localparam int PAYLOAD_16A_1X        = 4;
    localparam int PAYLOAD_FMT_AAAA_PCTN = 5;
    localparam int PAYLOAD_200_X         = 6;
    localparam int PAYLOAD_ONE_A         = 7;
    localparam int PAYLOAD_ONE_1         = 8;
    localparam int PAYLOAD_16A           = 9;
    localparam int PAYLOAD_UART_DATA_INTEGRITY = 10;
    localparam int PAYLOAD_UART_COMMAND_SET_LED7 = 11;
    localparam int PAYLOAD_64_A          = 12;  // CWE-122 heap overflow
    localparam int PAYLOAD_ROP_A_TGT     = 13;  // CWE-121: 12*'A' + target
    localparam int PAYLOAD_ROP_B_TGT     = 14;  // CWE-787: 12*'B' + target
    localparam int PAYLOAD_UAF_NONZERO   = 15;  // CWE-416: 01 00 00 00 + 12*0x55

    task automatic send_uart_benchmark_payload(input int payload_kind);
        case (payload_kind)
            PAYLOAD_UART_DATA_INTEGRITY: begin
                send_lspa_uart_byte(8'h44); // 'D'
                send_lspa_uart_byte(8'h49); // 'I'
                send_lspa_uart_byte(8'h46); // 'F'
                send_lspa_uart_byte(8'h54); // 'T'
                send_lspa_uart_byte(8'h42); // 'B'
                send_lspa_uart_byte(8'h45); // 'E'
                send_lspa_uart_byte(8'h4e); // 'N'
                send_lspa_uart_byte(8'h43); // 'C'
                send_lspa_uart_byte(8'h48); // 'H'
                send_lspa_uart_byte(8'h55); // 'U'
                send_lspa_uart_byte(8'h41); // 'A'
                send_lspa_uart_byte(8'h52); // 'R'
                send_lspa_uart_byte(8'h54); // 'T'
                send_lspa_uart_byte(8'h31); // '1'
                send_lspa_uart_byte(8'h32); // '2'
                send_lspa_uart_byte(8'h33); // '3'
            end
            PAYLOAD_UART_COMMAND_SET_LED7: begin
                send_lspa_uart_byte(8'h53); // 'S'
                send_lspa_uart_byte(8'h45); // 'E'
                send_lspa_uart_byte(8'h54); // 'T'
                send_lspa_uart_byte(8'h20); // ' '
                send_lspa_uart_byte(8'h4c); // 'L'
                send_lspa_uart_byte(8'h45); // 'E'
                send_lspa_uart_byte(8'h44); // 'D'
                send_lspa_uart_byte(8'h20); // ' '
                send_lspa_uart_byte(8'h37); // '7'
                send_lspa_uart_byte(8'h0a); // '\n'
            end
            default: begin
                send_lspa_uart_byte(8'h41);
            end
        endcase
    endtask

    task automatic run_cots_attack_case(
        input string tname,
        input logic [31:0] pc_main,
        input logic [31:0] pc_uart_read_call,
        input logic [31:0] pc_protected,
        input int payload_kind,
        input logic [31:0] bss_target,
        input bit allow_boot_fallback = 1'b1,
        input logic [31:0] runtime_status_addr = 32'h410002c0
    );
        automatic logic [31:0] addr_status;
        automatic logic [31:0] addr_fault_mepc;
        automatic logic [31:0] addr_fault_mcause;
        automatic logic [31:0] addr_mtvec_readback;
        automatic logic [31:0] addr_boot_tpr;
        automatic logic [31:0] addr_boot_tcr;

        localparam logic [31:0] STATUS_BOOTED       = 32'hd1f70010;
        localparam logic [31:0] STATUS_ATTACK       = 32'hd1f70002;
        localparam logic [31:0] BOOT_TPR            = 32'h0000a8a2;
        localparam logic [31:0] BOOT_TCR            = 32'h00200018;

        automatic logic seen_boot          = 0;
        automatic logic seen_main          = 0;
        automatic logic seen_uart_read     = 0;
        automatic logic seen_payload_sent  = 0;
        automatic logic seen_protected_pc  = 0;
        automatic logic seen_handler       = 0;
        automatic logic seen_status_attack = 0;
        automatic logic seen_fault_mepc    = 0;
        automatic logic seen_fault_mcause  = 0;
        automatic logic seen_mtvec         = 0;
        automatic logic seen_boot_tpr      = 0;
        automatic logic seen_boot_tcr      = 0;

        automatic int exception_count = 0;
        automatic int handler_entries = 0;

        dbg_bhv = new(jtag);
        lspa_uart_rx0_i = 1'b1;
        addr_status         = runtime_status_addr;
        addr_fault_mepc     = runtime_status_addr + 32'h10;
        addr_fault_mcause   = runtime_status_addr + 32'h14;
        addr_mtvec_readback = runtime_status_addr + 32'h1c;
        addr_boot_tpr       = runtime_status_addr + 32'h20;
        addr_boot_tcr       = runtime_status_addr + 32'h24;

        $display("[TB] =============================================");
        $display("[TB] %0s - boot-time DIFT policy", tname);
        $display("[TB] =============================================");

        fork
            begin : wd
                #30000000ns;
                $display("[TB] TIMEOUT at 30ms");
            end

            begin : milestones
                forever begin
                    @(posedge hsdom_seq.clk);
                    if (dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.is_decoding &&
                        dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.id_valid) begin
                        automatic logic [31:0] pc;
                        automatic logic [31:0] mtvec_base;
                        pc = dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.pc_id;
                        mtvec_base = {dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.cs_registers_i.mtvec_q, 8'h00};

                        if (!seen_main && pc == pc_main) begin
                            seen_main = 1;
                            $display("[TB %0t] MAIN PC=%08h", $time, pc);
                        end

                        if (!seen_uart_read && pc == pc_uart_read_call) begin
                            seen_uart_read = 1;
                            $display("[TB %0t] UART read call PC=%08h", $time, pc);
                        end

                        if (!seen_protected_pc && pc == pc_protected) begin
                            seen_protected_pc = 1;
                            $display("[TB %0t] sink PC=%08h", $time, pc);
                        end

                        if (seen_mtvec && mtvec_base != 32'h00000000 && pc == mtvec_base) begin
                            handler_entries++;
                            seen_handler = 1;
                            if (handler_entries <= 8 || (handler_entries % 256) == 0) begin
                                $display("[TB %0t] handler entry #%0d PC=%08h", $time, handler_entries, pc);
                            end
                        end
                    end
                end
            end

            begin : uart_payload
                if (allow_boot_fallback) begin
                    // Prefer the exact UART-read PC milestone when available.
                    // Fall back to a delayed send after boot status so tests keep
                    // working when code layout shifts and absolute PCs drift.
                    fork
                        begin : wait_uart_pc
                            wait (seen_uart_read);
                        end
                        begin : wait_boot_fallback
                            wait (seen_boot);
                            #2000000ns;
                        end
                    join_any
                    disable fork;
                end else begin
                    wait (seen_uart_read);
                end

                if (!seen_uart_read) begin
                    $display("[TB %0t] UART read PC milestone not observed; using boot-time payload fallback", $time);
                end

                #20000ns;
                for (int payload_attempt = 1; payload_attempt <= 24; payload_attempt++) begin
                    if (seen_status_attack || (seen_fault_mcause && seen_fault_mepc)) begin
                        break;
                    end

                    case (payload_kind)
                        PAYLOAD_NEG1A: begin
                            send_lspa_uart_byte(8'h2d); // '-'
                            send_lspa_uart_byte(8'h31); // '1'
                            send_lspa_uart_byte(8'h41); // 'A'
                        end
                        PAYLOAD_BSS_FUNCPTR: begin
                            for (int i = 0; i < 64; i++) begin
                                send_lspa_uart_byte(8'h41);
                            end
                            send_lspa_uart_byte(bss_target[7:0]);
                            send_lspa_uart_byte(bss_target[15:8]);
                            send_lspa_uart_byte(bss_target[23:16]);
                            send_lspa_uart_byte(bss_target[31:24]);
                        end
                        PAYLOAD_20_A: begin
                            for (int i = 0; i < 20; i++) begin
                                send_lspa_uart_byte(8'h41);
                            end
                        end
                        PAYLOAD_16A_1X: begin
                            for (int i = 0; i < 16; i++) begin
                                send_lspa_uart_byte(8'h41);
                            end
                            send_lspa_uart_byte(8'h58);
                        end
                        PAYLOAD_16A: begin
                            send_lspa_uart_byte(8'h31);
                            send_lspa_uart_byte(8'h36);
                            send_lspa_uart_byte(8'h41);
                        end
                        PAYLOAD_FMT_AAAA_PCTN: begin
                            send_lspa_uart_byte(8'h41);
                            send_lspa_uart_byte(8'h41);
                            send_lspa_uart_byte(8'h41);
                            send_lspa_uart_byte(8'h41);
                            send_lspa_uart_byte(8'h25);
                            send_lspa_uart_byte(8'h6e);
                        end
                        PAYLOAD_200_X: begin
                            for (int i = 0; i < 200; i++) begin
                                send_lspa_uart_byte(8'h58);
                            end
                        end
                        PAYLOAD_ONE_A: begin
                            send_lspa_uart_byte(8'h41);
                        end
                        PAYLOAD_ONE_1: begin
                            send_lspa_uart_byte(8'h31);
                        end
                        PAYLOAD_64_A: begin
                            for (int i = 0; i < 64; i++) begin
                                send_lspa_uart_byte(8'h41);
                            end
                        end
                        PAYLOAD_ROP_A_TGT: begin
                            for (int i = 0; i < 12; i++) begin
                                send_lspa_uart_byte(8'h41);
                            end
                            send_lspa_uart_byte(bss_target[7:0]);
                            send_lspa_uart_byte(bss_target[15:8]);
                            send_lspa_uart_byte(bss_target[23:16]);
                            send_lspa_uart_byte(bss_target[31:24]);
                        end
                        PAYLOAD_ROP_B_TGT: begin
                            for (int i = 0; i < 12; i++) begin
                                send_lspa_uart_byte(8'h42);
                            end
                            send_lspa_uart_byte(bss_target[7:0]);
                            send_lspa_uart_byte(bss_target[15:8]);
                            send_lspa_uart_byte(bss_target[23:16]);
                            send_lspa_uart_byte(bss_target[31:24]);
                        end
                        PAYLOAD_UAF_NONZERO: begin
                            send_lspa_uart_byte(8'h01);
                            send_lspa_uart_byte(8'h00);
                            send_lspa_uart_byte(8'h00);
                            send_lspa_uart_byte(8'h00);
                            for (int i = 0; i < 12; i++) begin
                                send_lspa_uart_byte(8'h55);
                            end
                        end
                        default: begin
                            send_lspa_uart_byte(8'h41);
                        end
                    endcase

                    seen_payload_sent = 1;
                    if (payload_attempt <= 3 || payload_attempt % 4 == 0) begin
                        $display("[TB %0t] UART payload sent (attempt %0d)", $time, payload_attempt);
                    end
                    #5000000ns;
                end
                forever begin
                    @(posedge hsdom_seq.clk);
                end
            end

            begin : data_monitor
                forever begin
                    @(posedge hsdom_seq.clk);

                    if (dut.genblk5[0].hsdom_cpu.data_req &&
                        dut.genblk5[0].hsdom_cpu.data_gnt &&
                        dut.genblk5[0].hsdom_cpu.data_we_effective) begin
                        automatic logic [31:0] addr;
                        automatic logic [31:0] data;
                        addr = dut.genblk5[0].hsdom_cpu.data_addr;
                        data = dut.genblk5[0].hsdom_cpu.data_wdata;

                        if (addr == addr_status) begin
                            if (data == STATUS_BOOTED) seen_boot = 1;
                            if (data == STATUS_ATTACK) seen_status_attack = 1;
                        end else if (addr == addr_fault_mepc) begin
                            // Keep matching against expected sink PC when
                            // available, but also accept any non-zero MEPC to
                            // tolerate address drift across software rebuilds.
                            if (data == pc_protected || data == (pc_protected + 32'd2) || data != 32'h00000000)
                                seen_fault_mepc = 1;
                        end else if (addr == addr_fault_mcause) begin
                            if (data == 32'h00000002)
                                seen_fault_mcause = 1;
                        end else if (addr == addr_mtvec_readback) begin
                            if (data[31:8] != 24'h000000 && data[7:0] == 8'h00)
                                seen_mtvec = 1;
                        end else if (addr == addr_boot_tpr) begin
                            if (data == BOOT_TPR)
                                seen_boot_tpr = 1;
                        end else if (addr == addr_boot_tcr) begin
                            if (data == BOOT_TCR)
                                seen_boot_tcr = 1;
                        end
                    end

                    if (dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.ex_stage_i.exception_o_tag) begin
                        exception_count++;
                    end
                end
            end

            begin : end_detect
                forever begin
                    @(posedge hsdom_seq.clk);
                    if (seen_status_attack && seen_fault_mcause) begin
                        $display("[TB %0t] Attack status and fault log observed", $time);
                        #10000ns;
                        break;
                    end
                end
            end
        join_any
        disable fork;

        $display("[TB] =============================================");
        $display("[TB] FINAL SUMMARY - %0s", tname);
        $display("[TB]   boot/runtime seen      = %0d", seen_boot);
        $display("[TB]   boot TPR/TCR seen      = %0d / %0d", seen_boot_tpr, seen_boot_tcr);
        $display("[TB]   main seen              = %0d", seen_main);
        $display("[TB]   UART read/payload      = %0d / %0d", seen_uart_read, seen_payload_sent);
        $display("[TB]   sink PC seen           = %0d", seen_protected_pc);
        $display("[TB]   handler/status attack  = %0d / %0d", seen_handler, seen_status_attack);
        $display("[TB]   fault log mepc/mcause  = %0d / %0d", seen_fault_mepc, seen_fault_mcause);
        $display("[TB]   exceptions             = %0d", exception_count);
        $display("[TB] =============================================");

        if (seen_boot && seen_boot_tpr && seen_boot_tcr && seen_payload_sent &&
            seen_handler && seen_status_attack && seen_fault_mepc && seen_fault_mcause) begin
            $display("[TB] RESULT: PASS - boot-time COTS policy trapped expected sink");
        end else begin
            $display("[TB] RESULT: FAIL - missing one or more COTS DIFT milestones");
            $error("%0s did not complete expected boot-policy attack flow", tname);
        end
        $display("[TB] done.");
    endtask

    task automatic run_cots_benign_runtime_case(
        input string tname,
        input logic [31:0] runtime_status_addr = 32'h410002c0,
        input logic [31:0] pc_uart_read_call = 32'h00000000,
        input logic [31:0] pc_done_spin = 32'h00000000
    );
        automatic logic [31:0] addr_status;
        automatic logic [31:0] addr_emulated;
        automatic logic [31:0] addr_emulation_cycles;
        automatic logic [31:0] addr_total_cycles;
        automatic logic [31:0] addr_fault_mepc;
        automatic logic [31:0] addr_fault_mcause;
        automatic logic [31:0] addr_fault_insn;
        automatic logic [31:0] addr_boot_tpr;
        automatic logic [31:0] addr_boot_tcr;
        automatic logic [31:0] addr_startup_cycles;

        localparam logic [31:0] STATUS_BOOTED   = 32'hd1f70010;
        localparam logic [31:0] STATUS_EMULATED = 32'h0000e001;
        localparam logic [31:0] STATUS_DONE     = 32'hd1f70020;
        localparam logic [31:0] STATUS_ATTACK   = 32'hd1f70002;
        localparam logic [31:0] STATUS_PROGRESS_BASE = 32'hd1f70100;
        localparam logic [31:0] STATUS_PROGRESS_MASK = 32'hffffff00;
        localparam logic [31:0] BOOT_TPR        = 32'h0000a8a2;
        localparam logic [31:0] BOOT_TCR        = 32'h00200018;

        automatic logic seen_boot          = 0;
        automatic logic seen_uart_read     = 0;
        automatic logic seen_done          = 0;
        automatic logic seen_payload_sent  = 0;
        automatic logic seen_emulated      = 0;
        automatic logic seen_status_attack = 0;
        automatic logic seen_fault_mepc    = 0;
        automatic logic seen_fault_mcause  = 0;
        automatic logic seen_fault_insn    = 0;
        automatic logic seen_boot_tpr      = 0;
        automatic logic seen_boot_tcr      = 0;
        automatic logic observation_done   = 0;

        automatic int exception_count      = 0;
        automatic int emulated_count       = 0;
        automatic logic [31:0] fault_mepc_val   = 0;
        automatic logic [31:0] fault_mcause_val = 0;
        automatic logic [31:0] fault_insn_val   = 0;
        automatic logic [31:0] last_status_val  = 0;
        automatic logic [31:0] last_progress_val = 0;
        automatic logic [31:0] startup_cycles_val = 0;
        automatic logic [31:0] emulation_cycles_val = 0;
        automatic logic [31:0] total_cycles_val = 0;

        dbg_bhv = new(jtag);
        lspa_uart_rx0_i = 1'b1;
        addr_status   = runtime_status_addr;
        addr_emulated = runtime_status_addr + 32'h4;
        addr_emulation_cycles = runtime_status_addr + 32'h8;
        addr_total_cycles     = runtime_status_addr + 32'hc;
        addr_fault_mepc       = runtime_status_addr + 32'h10;
        addr_fault_mcause     = runtime_status_addr + 32'h14;
        addr_fault_insn       = runtime_status_addr + 32'h18;
        addr_boot_tpr         = runtime_status_addr + 32'h20;
        addr_boot_tcr         = runtime_status_addr + 32'h24;
        addr_startup_cycles   = runtime_status_addr + 32'h28;

        $display("[TB] =============================================");
        $display("[TB] %0s - benign COTS trusted-runtime policy", tname);
        $display("[TB] =============================================");

        fork
            begin : wd
                #240000000ns;
                $display("[TB] TIMEOUT at 240ms");
            end

            begin : milestones
                forever begin
                    @(posedge hsdom_seq.clk);
                    if (dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.is_decoding &&
                        dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.id_valid) begin
                        automatic logic [31:0] pc;
                        pc = dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.pc_id;

                        if (pc_uart_read_call != 32'h00000000 && !seen_uart_read && pc == pc_uart_read_call) begin
                            seen_uart_read = 1;
                            $display("[TB %0t] benign UART read call PC=%08h", $time, pc);
                        end

                        if (pc_done_spin != 32'h00000000 && !seen_done && pc == pc_done_spin) begin
                            seen_done = 1;
                            $display("[TB %0t] benign workload done PC=%08h", $time, pc);
                        end
                    end
                end
            end

            begin : uart_payload
                if (pc_uart_read_call != 32'h00000000) begin
                    wait (seen_uart_read);
                    #20000ns;
                end else begin
                    wait (seen_boot);
                    #2000000ns;
                end

                send_lspa_uart_byte(8'h31);
                send_lspa_uart_byte(8'h32);
                send_lspa_uart_byte(8'h33);
                send_lspa_uart_byte(8'h34);
                send_lspa_uart_byte(8'h35);
                send_lspa_uart_byte(8'h36);
                send_lspa_uart_byte(8'h37);
                send_lspa_uart_byte(8'h38);
                send_lspa_uart_byte(8'h41);
                send_lspa_uart_byte(8'h42);
                send_lspa_uart_byte(8'h43);
                send_lspa_uart_byte(8'h44);
                send_lspa_uart_byte(8'h45);
                send_lspa_uart_byte(8'h46);
                send_lspa_uart_byte(8'h47);
                send_lspa_uart_byte(8'h48);
                seen_payload_sent = 1;
                $display("[TB %0t] benign UART payload sent", $time);
                #160000000ns;
                observation_done = 1;
            end

            begin : data_monitor
                forever begin
                    @(posedge hsdom_seq.clk);

                    if (dut.genblk5[0].hsdom_cpu.data_req &&
                        dut.genblk5[0].hsdom_cpu.data_gnt &&
                        dut.genblk5[0].hsdom_cpu.data_we_effective) begin
                        automatic logic [31:0] addr;
                        automatic logic [31:0] data;
                        automatic logic [31:0] pc;
                        addr = dut.genblk5[0].hsdom_cpu.data_addr;
                        data = dut.genblk5[0].hsdom_cpu.data_wdata;
                        pc   = dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.pc_id;

                        if (addr == addr_status) begin
                            last_status_val = data;
                            if (data == STATUS_BOOTED) seen_boot = 1;
                            if (data == STATUS_EMULATED) seen_emulated = 1;
                            if ((data & STATUS_PROGRESS_MASK) == STATUS_PROGRESS_BASE) begin
                                last_progress_val = data;
                                $display("[TB %0t] benign progress status <= %08h  PC=%08h", $time, data, pc);
                            end
                            if (data == STATUS_DONE) begin
                                seen_done = 1;
                                $display("[TB %0t] benign workload done status <= %08h  PC=%08h", $time, data, pc);
                            end
                            if (data == STATUS_ATTACK) begin
                                seen_status_attack = 1;
                                $display("[FAULT %0t] attack status <= %08h  PC=%08h", $time, data, pc);
                            end
                        end else if (addr == addr_fault_mepc) begin
                            fault_mepc_val = data;
                            if (data != 32'h00000000) begin
                                seen_fault_mepc = 1;
                                $display("[FAULT %0t] fault_mepc <= %08h  PC=%08h", $time, data, pc);
                            end
                        end else if (addr == addr_fault_mcause) begin
                            fault_mcause_val = data;
                            if (data != 32'h00000000) begin
                                seen_fault_mcause = 1;
                                $display("[FAULT %0t] fault_mcause <= %08h  PC=%08h", $time, data, pc);
                            end
                        end else if (addr == addr_fault_insn) begin
                            fault_insn_val = data;
                            if (data != 32'h00000000) begin
                                seen_fault_insn = 1;
                                $display("[FAULT %0t] fault_insn <= %08h  PC=%08h", $time, data, pc);
                            end
                        end else if (addr == addr_emulated) begin
                            if (data != 32'h00000000) begin
                                seen_emulated = 1;
                                emulated_count = data;
                            end
                        end else if (addr == addr_emulation_cycles) begin
                            emulation_cycles_val = data;
                        end else if (addr == addr_total_cycles) begin
                            total_cycles_val = data;
                        end else if (addr == addr_boot_tpr) begin
                            if (data == BOOT_TPR) seen_boot_tpr = 1;
                        end else if (addr == addr_boot_tcr) begin
                            if (data == BOOT_TCR) seen_boot_tcr = 1;
                        end else if (addr == addr_startup_cycles) begin
                            startup_cycles_val = data;
                        end
                    end

                    if (dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.ex_stage_i.exception_o_tag) begin
                        exception_count++;
                    end
                end
            end

            begin : end_detect
                forever begin
                    @(posedge hsdom_seq.clk);
                    if (seen_status_attack || seen_done || observation_done) begin
                        #10000ns;
                        break;
                    end
                end
            end
        join_any
        disable fork;

        $display("[TB] =============================================");
        $display("[TB] FINAL SUMMARY - %0s", tname);
        $display("[TB]   boot/runtime seen      = %0d", seen_boot);
        $display("[TB]   boot TPR/TCR seen      = %0d / %0d", seen_boot_tpr, seen_boot_tcr);
        $display("[TB]   startup_cycles         = %0d", startup_cycles_val);
        $display("[TB]   UART read/done         = %0d / %0d", seen_uart_read, seen_done);
        $display("[TB]   payload sent           = %0d", seen_payload_sent);
        $display("[TB]   trusted emulation seen = %0d (%0d)", seen_emulated, emulated_count);
        $display("[TB]   emulation_cycles total = %0d  avg/emul = %0d",
                 emulation_cycles_val,
                 (emulated_count > 0) ? emulation_cycles_val / emulated_count : 0);
        $display("[TB]   total_cycles           = %0d", total_cycles_val);
        if (total_cycles_val > 0) begin
            $display("[TB]   emul overhead %%        = %0d.%02d%%",
                     (emulation_cycles_val * 100) / total_cycles_val,
                     ((emulation_cycles_val * 10000) / total_cycles_val) % 100);
        end else begin
            $display("[TB]   emul overhead %%        = n/a (total_cycles=0)");
        end
        $display("[TB]   attack status seen     = %0d", seen_status_attack);
        $display("[TB]   fault mepc/mcause/insn = %0d / %0d / %0d", seen_fault_mepc, seen_fault_mcause, seen_fault_insn);
        $display("[TB]   fault values           = mepc=%08h mcause=%08h insn=%08h", fault_mepc_val, fault_mcause_val, fault_insn_val);
        $display("[TB]   last runtime status    = %08h", last_status_val);
        $display("[TB]   last progress status   = %08h", last_progress_val);
        $display("[TB]   exceptions             = %0d", exception_count);
        $display("[TB] =============================================");

        if (seen_boot && seen_boot_tpr && seen_boot_tcr && seen_payload_sent &&
            (pc_uart_read_call == 32'h00000000 || seen_uart_read) &&
            (pc_done_spin == 32'h00000000 || seen_done) && !seen_status_attack) begin
            $display("[TB] RESULT: PASS - benign tainted input completed without attack");
        end else begin
            $display("[TB] RESULT: FAIL - benign COTS runtime workload did not meet expectations");
            $error("%0s reported an unexpected COTS false-positive result", tname);
        end
        $display("[TB] done.");
    endtask

    task automatic run_uart_benign_benchmark_case(
        input string tname,
        input logic [31:0] runtime_status_addr,
        input logic [31:0] pc_uart_read_call,
        input logic [31:0] pc_done_spin,
        input int payload_kind,
        input logic [31:0] result0_addr,
        input logic [31:0] result0_expected,
        input logic [31:0] result1_addr = 32'h00000000,
        input logic [31:0] result1_expected = 32'h00000000,
        input logic [31:0] result2_addr = 32'h00000000,
        input logic [31:0] result2_expected = 32'h00000000,
        input bit require_emulation = 1'b0,
        input bit require_no_exceptions = 1'b0
    );
        localparam logic [31:0] PC_UART_READ_POLL = 32'h400003c6;

        automatic logic [31:0] addr_status;
        automatic logic [31:0] addr_emulated;
        automatic logic [31:0] addr_boot_tpr;
        automatic logic [31:0] addr_boot_tcr;
        automatic logic [31:0] addr_startup_cycles;

        localparam logic [31:0] STATUS_BOOTED   = 32'hd1f70010;
        localparam logic [31:0] STATUS_EMULATED = 32'h0000e001;
        localparam logic [31:0] STATUS_ATTACK   = 32'hd1f70002;
        localparam logic [31:0] BOOT_TPR        = 32'h0000a8a2;
        localparam logic [31:0] BOOT_TCR        = 32'h00200018;

        automatic logic seen_boot          = 0;
        automatic logic seen_uart_read     = 0;
        automatic logic seen_done          = 0;
        automatic logic seen_payload_sent  = 0;
        automatic logic seen_emulated      = 0;
        automatic logic seen_status_attack = 0;
        automatic logic seen_boot_tpr      = 0;
        automatic logic seen_boot_tcr      = 0;
        automatic logic seen_taint_en      = 0;
        automatic logic seen_result0       = 0;
        automatic logic seen_result1       = 0;
        automatic logic seen_result2       = 0;
        automatic logic observation_done   = 0;
        automatic logic results_ok         = 0;
        automatic logic completed_ok       = 0;

        automatic int exception_count      = 0;
        automatic int emulated_count       = 0;
        automatic logic [31:0] startup_cycles_val = 0;
        automatic logic [31:0] result0_val = 0;
        automatic logic [31:0] result1_val = 0;
        automatic logic [31:0] result2_val = 0;

        dbg_bhv = new(jtag);
        lspa_uart_rx0_i = 1'b1;
        addr_status         = runtime_status_addr;
        addr_emulated       = runtime_status_addr + 32'h4;
        addr_boot_tpr       = runtime_status_addr + 32'h20;
        addr_boot_tcr       = runtime_status_addr + 32'h24;
        addr_startup_cycles = runtime_status_addr + 32'h28;

        $display("[TB] =============================================");
        $display("[TB] %0s - benign UART DIFT benchmark", tname);
        $display("[TB] =============================================");

        fork
            begin : wd
                #100000000ns;
                $display("[TB] TIMEOUT at 100ms");
            end

            begin : milestones
                forever begin
                    @(posedge hsdom_seq.clk);
                    if (dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.is_decoding &&
                        dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.id_valid) begin
                        automatic logic [31:0] pc;
                        pc = dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.pc_id;

                        if (!seen_uart_read && (pc == pc_uart_read_call || pc == PC_UART_READ_POLL)) begin
                            seen_uart_read = 1;
                            $display("[TB %0t] UART read milestone PC=%08h", $time, pc);
                        end

                        if (!seen_done && pc == pc_done_spin) begin
                            seen_done = 1;
                            $display("[TB %0t] workload done PC=%08h", $time, pc);
                        end
                    end
                end
            end

            begin : uart_payload
                wait (seen_uart_read);
                #20000ns;
                send_uart_benchmark_payload(payload_kind);
                seen_payload_sent = 1;
                $display("[TB %0t] benchmark UART payload sent", $time);
                #80000000ns;
                observation_done = 1;
            end

            begin : data_monitor
                forever begin
                    @(posedge hsdom_seq.clk);

                    if (!seen_taint_en && dut.adam_fabric.lspa_taint_en[LSPA_UART0_DIFT_BIT]) begin
                        seen_taint_en = 1;
                        $display("[TB %0t] LSPA UART0 taint_en activated", $time);
                    end

                    if (dut.genblk5[0].hsdom_cpu.data_req &&
                        dut.genblk5[0].hsdom_cpu.data_gnt &&
                        dut.genblk5[0].hsdom_cpu.data_we_effective) begin
                        automatic logic [31:0] addr;
                        automatic logic [31:0] data;
                        addr = dut.genblk5[0].hsdom_cpu.data_addr;
                        data = dut.genblk5[0].hsdom_cpu.data_wdata;

                        if (addr == addr_status) begin
                            if (data == STATUS_BOOTED) seen_boot = 1;
                            if (data == STATUS_EMULATED) seen_emulated = 1;
                            if (data == STATUS_ATTACK) seen_status_attack = 1;
                        end else if (addr == addr_emulated) begin
                            if (data != 32'h00000000) begin
                                seen_emulated = 1;
                                emulated_count = data;
                            end
                        end else if (addr == addr_boot_tpr) begin
                            if (data == BOOT_TPR) seen_boot_tpr = 1;
                        end else if (addr == addr_boot_tcr) begin
                            if (data == BOOT_TCR) seen_boot_tcr = 1;
                        end else if (addr == addr_startup_cycles) begin
                            startup_cycles_val = data;
                        end

                        if (addr == result0_addr) begin
                            result0_val = data;
                            if (data == result0_expected) seen_result0 = 1;
                        end else if (result1_addr != 32'h00000000 && addr == result1_addr) begin
                            result1_val = data;
                            if (data == result1_expected) seen_result1 = 1;
                        end else if (result2_addr != 32'h00000000 && addr == result2_addr) begin
                            result2_val = data;
                            if (data == result2_expected) seen_result2 = 1;
                        end
                    end

                    if (dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.ex_stage_i.exception_o_tag) begin
                        exception_count++;
                    end
                end
            end

            begin : end_detect
                forever begin
                    @(posedge hsdom_seq.clk);
                    if (seen_status_attack || seen_done || observation_done) begin
                        #10000ns;
                        break;
                    end
                end
            end
        join_any
        disable fork;

        results_ok = seen_result0 &&
            ((result1_addr == 32'h00000000) || seen_result1) &&
            ((result2_addr == 32'h00000000) || seen_result2);
        completed_ok = seen_done || results_ok;

        $display("[TB] =============================================");
        $display("[TB] FINAL SUMMARY - %0s", tname);
        $display("[TB]   boot/runtime seen      = %0d", seen_boot);
        $display("[TB]   boot TPR/TCR seen      = %0d / %0d", seen_boot_tpr, seen_boot_tcr);
        $display("[TB]   startup_cycles         = %0d", startup_cycles_val);
        $display("[TB]   UART read/done         = %0d / %0d", seen_uart_read, seen_done);
        $display("[TB]   payload sent           = %0d", seen_payload_sent);
        $display("[TB]   UART taint_en seen     = %0d", seen_taint_en);
        $display("[TB]   trusted emulation seen = %0d (%0d)", seen_emulated, emulated_count);
        $display("[TB]   attack status seen     = %0d", seen_status_attack);
        $display("[TB]   exceptions             = %0d", exception_count);
        $display("[TB]   result0                = %0d value=%08h expected=%08h", seen_result0, result0_val, result0_expected);
        $display("[TB]   result1                = %0d value=%08h expected=%08h", (result1_addr == 32'h00000000) || seen_result1, result1_val, result1_expected);
        $display("[TB]   result2                = %0d value=%08h expected=%08h", (result2_addr == 32'h00000000) || seen_result2, result2_val, result2_expected);
        $display("[TB] =============================================");

        if (seen_boot && seen_boot_tpr && seen_boot_tcr && seen_payload_sent &&
            seen_uart_read && completed_ok && !seen_status_attack && results_ok &&
            (!require_emulation || seen_emulated) &&
            (!require_no_exceptions || exception_count == 0)) begin
            $display("[TB] RESULT: PASS - benign UART DIFT benchmark completed as expected");
        end else begin
            $display("[TB] RESULT: FAIL - benign UART DIFT benchmark did not meet expectations");
            $error("%0s reported an unexpected benchmark result", tname);
        end
        $display("[TB] done.");
    endtask

    `TEST_SUITE begin

        // dift_branch_emulate: trusted branch is emulated, untrusted branch halts
        `TEST_CASE("dift_branch_emulate") begin
            // PCs and data addresses from dift_branch_emulate.dump
            localparam logic [31:0] PC_MAIN             = 32'h400003ec;
            localparam logic [31:0] PC_PSPSW            = 32'h4000042a;
            localparam logic [31:0] PC_MTVEC_WRITE      = 32'h4000042e;
            localparam logic [31:0] PC_TCR_WRITE        = 32'h4000043a;
            localparam logic [31:0] PC_TRUSTED_BEQ      = 32'h40000162;
            localparam logic [31:0] PC_HANDLER_ENTRY    = 32'h40000200;
            localparam logic [31:0] PC_HANDLER_EMULATED = 32'h40000362;
            localparam logic [31:0] PC_HANDLER_RESTORE  = 32'h400003a4;
            localparam logic [31:0] PC_AFTER_TRUSTED    = 32'h40000448;
            localparam logic [31:0] PC_ATTACK_BEQ       = 32'h4000046c;
            localparam logic [31:0] PC_ATTACK_HALT      = 32'h400003a2;

            localparam logic [31:0] ADDR_TAGGED_WORD    = 32'h41000000;
            localparam logic [31:0] ADDR_STATUS         = 32'h41000280;
            localparam logic [31:0] ADDR_EMULATED       = 32'h41000284;
            localparam logic [31:0] ADDR_FAULT_MEPC     = 32'h41000288;
            localparam logic [31:0] ADDR_FAULT_MCAUSE   = 32'h4100028c;
            localparam logic [31:0] ADDR_FAULT_INSN     = 32'h41000290;
            localparam logic [31:0] ADDR_TRUSTED_RESULT = 32'h41000294;
            localparam logic [31:0] ADDR_MTVEC_READBACK = 32'h41000298;

            localparam logic [31:0] STATUS_INIT         = 32'h00000100;
            localparam logic [31:0] STATUS_BEFORE_TRUST = 32'h00000200;
            localparam logic [31:0] STATUS_EMULATED     = 32'h0000e001;
            localparam logic [31:0] STATUS_AFTER_TRUST  = 32'h00000300;
            localparam logic [31:0] STATUS_BEFORE_ATK   = 32'h00000400;
            localparam logic [31:0] STATUS_ATTACK       = 32'hd1f70002;
            localparam logic [31:0] STATUS_BAD          = 32'hbad10000;
            localparam logic [31:0] STATUS_DEAD         = 32'hdead0000;
            localparam logic [31:0] INSN_ATTACK_BEQ     = 32'h00550363;

            automatic logic seen_main              = 0;
            automatic logic seen_pspsw             = 0;
            automatic logic seen_mtvec             = 0;
            automatic logic seen_tcr               = 0;
            automatic logic seen_trusted_beq       = 0;
            automatic logic seen_attack_beq        = 0;
            automatic logic seen_handler_restore   = 0;
            automatic logic seen_after_trusted     = 0;
            automatic logic seen_attack_halt       = 0;
            automatic logic seen_bad               = 0;
            automatic logic seen_dead              = 0;
            automatic logic seen_status_init       = 0;
            automatic logic seen_status_before     = 0;
            automatic logic seen_status_emulated   = 0;
            automatic logic seen_status_after      = 0;
            automatic logic seen_status_attack_pre = 0;
            automatic logic seen_status_attack     = 0;
            automatic logic seen_emulated_count    = 0;
            automatic logic seen_trusted_result    = 0;
            automatic logic seen_fault_mepc        = 0;
            automatic logic seen_fault_mcause      = 0;
            automatic logic seen_fault_insn        = 0;
            automatic logic seen_mtvec_readback    = 0;
            automatic logic seen_trusted_exception = 0;
            automatic logic seen_attack_exception  = 0;
            automatic logic trusted_flow_ok        = 0;
            automatic logic attack_flow_ok         = 0;

            automatic int handler_entries = 0;
            automatic int exception_count = 0;
            automatic int tag_wr_total    = 0;
            automatic int tag_rd_total    = 0;

            dbg_bhv = new(jtag);

            $display("[TB] =============================================");
            $display("[TB] dift_branch_emulate — branch trap emulator");
            $display("[TB] =============================================");
            $display("[TB] >>> Expected final status: %08h <<<", STATUS_ATTACK);

            fork
                // ============================================================
                // Thread 1: Timeout 10 ms
                // ============================================================
                begin : wd
                    #10000000ns;
                    $display("[TB] TIMEOUT at 10ms");
                end

                // ============================================================
                // Thread 2: PC milestone tracker
                // ============================================================
                begin : milestones
                    forever begin
                        @(posedge hsdom_seq.clk);
                        if (dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.is_decoding &&
                            dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.id_valid) begin

                            automatic logic [31:0] pc;
                            automatic logic [31:0] mtvec_base;
                            pc = dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.pc_id;
                            mtvec_base = {dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.cs_registers_i.mtvec_q, 8'h00};

                            if (!seen_main && pc == PC_MAIN) begin
                                seen_main = 1;
                                $display("");
                                $display("[TB %0t] ===== MAIN() ENTRY ===== PC=%08h", $time, pc);
                                $display("[TB %0t]   TPR=%08h  TCR=%08h", $time,
                                    dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.cs_registers_i.tpr_q,
                                    dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.cs_registers_i.tcr_q);
                                $display("[TB %0t]   MTVEC raw=%08h base=%08h mode=%0d", $time,
                                    {dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.cs_registers_i.mtvec_q, 6'b0,
                                     dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.cs_registers_i.mtvec_mode_q},
                                    {dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.cs_registers_i.mtvec_q, 8'h00},
                                    dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.cs_registers_i.mtvec_mode_q);
                            end

                            if (!seen_pspsw && pc == PC_PSPSW) begin
                                seen_pspsw = 1;
                                $display("");
                                $display("[TB %0t] ===== TAG SOURCE p.spsw ===== PC=%08h", $time, pc);
                                $display("[TB %0t]   memory_set=%0b  register_set=%0b", $time,
                                    dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.memory_set_tag,
                                    dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.register_set_tag);
                            end

                            if (!seen_mtvec && pc == PC_MTVEC_WRITE) begin
                                seen_mtvec = 1;
                                $display("");
                                $display("[TB %0t] ===== DIRECT MTVEC INSTALL ===== PC=%08h", $time, pc);
                                $display("[TB %0t]   before/at decode MTVEC raw=%08h base=%08h mode=%0d", $time,
                                    {dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.cs_registers_i.mtvec_q, 6'b0,
                                     dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.cs_registers_i.mtvec_mode_q},
                                    {dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.cs_registers_i.mtvec_q, 8'h00},
                                    dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.cs_registers_i.mtvec_mode_q);
                            end

                            if (!seen_tcr && pc == PC_TCR_WRITE) begin
                                seen_tcr = 1;
                                $display("");
                                $display("[TB %0t] ===== TCR BRANCH CHECK ENABLE ===== PC=%08h", $time, pc);
                                $display("[TB %0t]   after install MTVEC raw=%08h base=%08h mode=%0d", $time,
                                    {dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.cs_registers_i.mtvec_q, 6'b0,
                                     dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.cs_registers_i.mtvec_mode_q},
                                    {dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.cs_registers_i.mtvec_q, 8'h00},
                                    dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.cs_registers_i.mtvec_mode_q);
                            end

                            if (!seen_trusted_beq && pc == PC_TRUSTED_BEQ) begin
                                seen_trusted_beq = 1;
                                $display("");
                                $display("[TB %0t] ===== TRUSTED TAINTED BRANCH ===== PC=%08h", $time, pc);
                                $display("[TB %0t]   rf_tag[a0]=%0b  rf_tag[t0]=%0b", $time,
                                    dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.id_stage_i.registers_tag_i.rf_reg[10],
                                    dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.id_stage_i.registers_tag_i.rf_reg[5]);
                            end

                            if (seen_mtvec_readback && mtvec_base != 32'h00000000 && pc == mtvec_base) begin
                                handler_entries++;
                                $display("");
                                $display("[TB %0t] ===== HANDLER ENTRY #%0d ===== PC=%08h", $time, handler_entries, pc);
                                $display("[TB %0t]   mcause path should be illegal-instruction/DIFT", $time);
                            end

                            if (!seen_handler_restore && pc == PC_HANDLER_RESTORE) begin
                                seen_handler_restore = 1;
                                $display("");
                                $display("[TB %0t] ===== TRUSTED BRANCH EMULATED, RESTORING ===== PC=%08h", $time, pc);
                            end

                            if (!seen_after_trusted && pc == PC_AFTER_TRUSTED) begin
                                seen_after_trusted = 1;
                                $display("");
                                $display("[TB %0t] ===== RETURNED AFTER TRUSTED BRANCH ===== PC=%08h", $time, pc);
                            end

                            if (!seen_attack_beq && pc == PC_ATTACK_BEQ) begin
                                seen_attack_beq = 1;
                                $display("");
                                $display("[TB %0t] ===== NON-WHITELISTED TAINTED BRANCH ===== PC=%08h", $time, pc);
                                $display("[TB %0t]   rf_tag[a0]=%0b  rf_tag[t0]=%0b", $time,
                                    dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.id_stage_i.registers_tag_i.rf_reg[10],
                                    dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.id_stage_i.registers_tag_i.rf_reg[5]);
                            end

                            if (!seen_attack_halt && pc == PC_ATTACK_HALT) begin
                                seen_attack_halt = 1;
                                $display("");
                                $display("[TB %0t] ===== HANDLER ATTACK HALT ===== PC=%08h", $time, pc);
                            end

                        end
                    end
                end

                // ============================================================
                // Thread 3: Data/tag/status monitor
                // ============================================================
                begin : data_monitor
                    forever begin
                        @(posedge hsdom_seq.clk);

                        if (dut.genblk5[0].hsdom_cpu.data_req &&
                            dut.genblk5[0].hsdom_cpu.data_gnt &&
                            dut.genblk5[0].hsdom_cpu.data_we_effective) begin

                            automatic logic [31:0] addr;
                            automatic logic [31:0] data;
                            automatic logic [31:0] pc;

                            addr = dut.genblk5[0].hsdom_cpu.data_addr;
                            data = dut.genblk5[0].hsdom_cpu.data_wdata;
                            pc   = dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.pc_id;

                            if (dut.genblk5[0].hsdom_cpu.data_tag_wdata != 4'b0000) begin
                                tag_wr_total++;
                                $display("[TAG-WR %0t] addr=%08h wdata=%08h tag=%04b be=%04b we=%0b we_tag=%0b PC=%08h",
                                    $time,
                                    addr,
                                    data,
                                    dut.genblk5[0].hsdom_cpu.data_tag_wdata,
                                    dut.genblk5[0].hsdom_cpu.data_be_effective,
                                    dut.genblk5[0].hsdom_cpu.data_we,
                                    dut.genblk5[0].hsdom_cpu.data_we_o_tag,
                                    pc);
                            end

                            if (dut.genblk5[0].hsdom_cpu.data_we_o_tag &&
                                !dut.genblk5[0].hsdom_cpu.data_we &&
                                addr == ADDR_TAGGED_WORD) begin
                                seen_pspsw = 1;
                                $display("[P.SPSW %0t] tagged_word tag-only write addr=%08h tag=%04b PC=%08h",
                                    $time, addr, dut.genblk5[0].hsdom_cpu.data_tag_wdata, pc);
                            end

                            if (addr == ADDR_STATUS) begin
                                $display("[STATUS %0t] status <= %08h  PC=%08h", $time, data, pc);
                                if (data == STATUS_INIT) begin
                                    seen_status_init = 1;
                                    seen_main = 1;
                                end
                                if (data == STATUS_BEFORE_TRUST) begin
                                    seen_status_before = 1;
                                    if (dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.cs_registers_i.tcr_q == 32'h00000018)
                                        seen_tcr = 1;
                                end
                                if (data == STATUS_EMULATED)     seen_status_emulated   = 1;
                                if (data == STATUS_AFTER_TRUST)  seen_status_after      = 1;
                                if (data == STATUS_BEFORE_ATK)   seen_status_attack_pre = 1;
                                if (data == STATUS_ATTACK)       seen_status_attack     = 1;
                                if (data == STATUS_BAD)          seen_bad               = 1;
                                if (data == STATUS_DEAD)         seen_dead              = 1;
                            end else if (addr == ADDR_EMULATED) begin
                                $display("[STATUS %0t] emulated_count <= %08h  PC=%08h", $time, data, pc);
                                if (data == 32'h00000001)
                                    seen_emulated_count = 1;
                            end else if (addr == ADDR_TRUSTED_RESULT) begin
                                $display("[STATUS %0t] trusted_result <= %08h  PC=%08h", $time, data, pc);
                                if (data == 32'h00000001)
                                    seen_trusted_result = 1;
                            end else if (addr == ADDR_MTVEC_READBACK) begin
                                $display("[CSR %0t] mtvec_readback <= %08h  effective_base=%08h mode=%0d PC=%08h",
                                    $time, data, {data[31:8], 8'h00}, data[0], pc);
                                if (data[31:8] != 24'h000000 && data[7:0] == 8'h00 && data[0] == 1'b0) begin
                                    seen_mtvec_readback = 1;
                                    seen_mtvec = 1;
                                end
                            end else if (addr == ADDR_FAULT_MEPC) begin
                                $display("[FAULT %0t] fault_mepc <= %08h  PC=%08h", $time, data, pc);
                                if (data == PC_ATTACK_BEQ || data[31:20] == 12'h400)
                                    seen_fault_mepc = 1;
                            end else if (addr == ADDR_FAULT_MCAUSE) begin
                                $display("[FAULT %0t] fault_mcause <= %08h  PC=%08h", $time, data, pc);
                                if (data == 32'h00000002)
                                    seen_fault_mcause = 1;
                            end else if (addr == ADDR_FAULT_INSN) begin
                                $display("[FAULT %0t] fault_insn <= %08h  PC=%08h", $time, data, pc);
                                if (data == INSN_ATTACK_BEQ)
                                    seen_fault_insn = 1;
                            end
                        end

                        if (dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.data_rvalid_i) begin
                            if (dut.genblk5[0].hsdom_cpu.data_tag_rdata != 4'b0000) begin
                                tag_rd_total++;
                                $display("[TAG-RD %0t] tag_rdata=%04b data_rdata=%08h PC=%08h",
                                    $time,
                                    dut.genblk5[0].hsdom_cpu.data_tag_rdata,
                                    dut.genblk5[0].hsdom_cpu.data_rdata,
                                    dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.pc_id);
                            end
                        end

                        if (dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.ex_stage_i.exception_o_tag) begin
                            exception_count++;
                            $display("[DIFT-EXC %0t] exception_o_tag PC=%08h check_a=%0b check_b=%0b mepc=%08h mcause=%08h mtvec_raw=%08h mtvec_base=%08h mode=%0d",
                                $time,
                                dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.pc_id,
                                dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.ex_stage_i.check_a,
                                dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.ex_stage_i.check_b,
                                dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.cs_registers_i.mepc_q,
                                {dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.cs_registers_i.mcause_q[5], 26'b0,
                                 dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.cs_registers_i.mcause_q[4:0]},
                                {dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.cs_registers_i.mtvec_q, 6'b0,
                                 dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.cs_registers_i.mtvec_mode_q},
                                {dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.cs_registers_i.mtvec_q, 8'h00},
                                dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.cs_registers_i.mtvec_mode_q);
                            if (dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.pc_id == PC_TRUSTED_BEQ ||
                                dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.pc_id == PC_TRUSTED_BEQ + 32'd4)
                                seen_trusted_exception = 1;
                            if (dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.pc_id == PC_ATTACK_BEQ ||
                                dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.pc_id == PC_ATTACK_BEQ + 32'd4)
                                seen_attack_exception = 1;
                        end
                    end
                end

                // ============================================================
                // Thread 4: Periodic CSR/tag dump
                // ============================================================
                begin : periodic_dump
                    for (int ep = 0; ep < 100; ep++) begin
                        #100000ns;
                        $display("");
                        $display("[TB %0t] --- PERIODIC DUMP --- PC=%08h exc=%0d tag_wr=%0d tag_rd=%0d",
                            $time,
                            dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.pc_id,
                            exception_count, tag_wr_total, tag_rd_total);
                        $display("[TB %0t]   TPR=%08h TCR=%08h handler_entries=%0d", $time,
                            dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.cs_registers_i.tpr_q,
                            dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.cs_registers_i.tcr_q,
                            handler_entries);
                        $display("[TB %0t]   MTVEC raw=%08h base=%08h mode=%0d MEPC=%08h MCAUSE=%08h", $time,
                            {dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.cs_registers_i.mtvec_q, 6'b0,
                             dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.cs_registers_i.mtvec_mode_q},
                            {dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.cs_registers_i.mtvec_q, 8'h00},
                            dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.cs_registers_i.mtvec_mode_q,
                            dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.cs_registers_i.mepc_q,
                            {dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.cs_registers_i.mcause_q[5], 26'b0,
                             dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.cs_registers_i.mcause_q[4:0]});
                        $display("[TB %0t]   rf_tags: a0=%0b t0=%0b t1=%0b t2=%0b sp=%0b ra=%0b", $time,
                            dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.id_stage_i.registers_tag_i.rf_reg[10],
                            dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.id_stage_i.registers_tag_i.rf_reg[5],
                            dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.id_stage_i.registers_tag_i.rf_reg[6],
                            dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.id_stage_i.registers_tag_i.rf_reg[7],
                            dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.id_stage_i.registers_tag_i.rf_reg[2],
                            dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.id_stage_i.registers_tag_i.rf_reg[1]);
                    end
                end

                // ============================================================
                // Thread 5: Detect end-of-test
                // ============================================================
                begin : end_detect
                    automatic int attack_halt_count = 0;

                    forever begin
                        @(posedge hsdom_seq.clk);

                        if (seen_status_attack && seen_fault_mepc && seen_fault_mcause && seen_fault_insn) begin
                            $display("[TB %0t] Attack status and fault log observed -> ending test", $time);
                            #10000ns;
                            break;
                        end

                        if (dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.pc_id == PC_ATTACK_HALT)
                            attack_halt_count++;
                        else
                            attack_halt_count = 0;

                        if (attack_halt_count >= 200) begin
                            $display("[TB %0t] Handler attack halt loop detected -> ending test", $time);
                            break;
                        end

                        if (seen_dead || seen_bad) begin
                            $display("[TB %0t] Failure status observed -> ending test", $time);
                            break;
                        end
                    end
                end
            join_any
            disable fork;

            $display("");
            $display("[TB] =============================================");
            $display("[TB] FINAL SUMMARY — dift_branch_emulate");
            $display("[TB]   main seen              = %0d", seen_main);
            $display("[TB]   p.spsw seen            = %0d", seen_pspsw);
            $display("[TB]   mtvec install seen     = %0d", seen_mtvec);
            $display("[TB]   TCR write seen         = %0d", seen_tcr);
            $display("[TB]   trusted branch seen    = %0d", seen_trusted_beq);
            $display("[TB]   trusted exception seen = %0d", seen_trusted_exception);
            $display("[TB]   handler restore seen   = %0d", seen_handler_restore);
            $display("[TB]   after trusted seen     = %0d", seen_after_trusted);
            $display("[TB]   attack branch seen     = %0d", seen_attack_beq);
            $display("[TB]   attack exception seen  = %0d", seen_attack_exception);
            $display("[TB]   attack status seen     = %0d", seen_status_attack);
            $display("[TB]   emulated_count==1      = %0d", seen_emulated_count);
            $display("[TB]   trusted_result==1      = %0d", seen_trusted_result);
            $display("[TB]   mtvec aligned readback = %0d", seen_mtvec_readback);
            $display("[TB]   fault_mepc OK          = %0d", seen_fault_mepc);
            $display("[TB]   fault_mcause OK        = %0d", seen_fault_mcause);
            $display("[TB]   fault_insn OK          = %0d", seen_fault_insn);
            $display("[TB]   BAD status/loop seen   = %0d", seen_bad);
            $display("[TB]   DEAD status/loop seen  = %0d", seen_dead);
            $display("[TB]   handler entries        = %0d", handler_entries);
            $display("[TB]   DIFT exceptions        = %0d", exception_count);
            $display("[TB]   tag writes/reads       = %0d / %0d", tag_wr_total, tag_rd_total);
            $display("[TB]   Final PC               = %08h",
                dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.pc_id);
            $display("[TB]   Final TPR/TCR          = %08h / %08h",
                dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.cs_registers_i.tpr_q,
                dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.cs_registers_i.tcr_q);
            $display("[TB] =============================================");

            trusted_flow_ok = seen_status_init && seen_status_before &&
                seen_status_emulated && seen_status_after &&
                seen_emulated_count && seen_trusted_result && !seen_bad;
            attack_flow_ok = seen_status_attack_pre && seen_status_attack &&
                seen_fault_mepc && seen_fault_mcause && seen_fault_insn && !seen_dead;

            if (seen_pspsw && seen_mtvec_readback && trusted_flow_ok && attack_flow_ok) begin
                $display("[TB] RESULT: PASS — trusted tainted branch was emulated, non-whitelisted branch was trapped as attack");
            end else if (seen_bad) begin
                $display("[TB] RESULT: FAIL — trusted branch path failed before attack test");
                $error("dift_branch_emulate reached BAD failure path");
            end else if (seen_dead) begin
                $display("[TB] RESULT: FAIL — non-whitelisted app branch did not trap");
                $error("dift_branch_emulate reached DEAD failure path");
            end else begin
                $display("[TB] RESULT: INCONCLUSIVE — missing one or more expected branch-emulation milestones");
                $error("dift_branch_emulate testcase did not observe the full expected flow");
            end
            $display("[TB] done.");
        end

        // dift_cwe_122_heap_cots: boot-time policy protects the admin_flag branch
        `TEST_CASE("dift_cwe_122_heap_cots") begin
            run_cots_attack_case(
                "dift_cwe_122_heap_cots",
                32'h40000424,
                32'h400004ea,
                32'h400003fe,
                PAYLOAD_64_A,
                32'h00000000
            );
        end

        `TEST_CASE("dift_cwe_121_rop_cots") begin
            run_cots_attack_case(
                "dift_cwe_121_rop_cots",
                32'h40000408,
                32'h400004a2,
                32'h400003e2,
                PAYLOAD_ROP_A_TGT,
                32'h400003e2
            );
        end

        `TEST_CASE("dift_cwe_787_funcptr_cots") begin
            run_cots_attack_case(
                "dift_cwe_787_funcptr_cots",
                32'h4000041a,
                32'h400004cc,
                32'h400003ee,
                PAYLOAD_ROP_B_TGT,
                32'h400003ee
            );
        end

        `TEST_CASE("dift_cwe_416_use_after_free_cots") begin
            run_cots_attack_case(
                "dift_cwe_416_use_after_free_cots",
                32'h40000420,
                32'h400004ac,
                32'h400003fc,
                PAYLOAD_UAF_NONZERO,
                32'h00000000
            );
        end

        `TEST_CASE("dift_cwe_119_oob_index_cots") begin
            run_cots_attack_case(
                "dift_cwe_119_oob_index_cots",
                32'h4000048a,
                32'h400004d6,
                32'h40000464,
                PAYLOAD_NEG1A,
                32'h00000000
            );
        end

        `TEST_CASE("dift_cwe_120_bss_cots") begin
            run_cots_attack_case(
                "dift_cwe_120_bss_cots",
                32'h4000041a,
                32'h400004e6,
                32'h4000051a,
                PAYLOAD_BSS_FUNCPTR,
                32'h400003ee,
                1'b0,
                32'h41000304
            );
        end

        `TEST_CASE("dift_cwe_121_var_ovf_cots") begin
            run_cots_attack_case(
                "dift_cwe_121_var_ovf_cots",
                32'h40000444,
                32'h400004a2,
                32'h4000042a,
                PAYLOAD_20_A,
                32'h00000000
            );
        end

        `TEST_CASE("dift_cwe_125_oob_read_cots") begin
            run_cots_attack_case(
                "dift_cwe_125_oob_read_cots",
                32'h4000049c,
                32'h400004f8,
                32'h40000466,
                PAYLOAD_16A,
                32'h00000000
            );
        end

        `TEST_CASE("dift_cwe_134_fmt_cots") begin
            run_cots_attack_case(
                "dift_cwe_134_fmt_cots",
                32'h40000442,
                32'h40000494,
                32'h4000041c,
                PAYLOAD_FMT_AAAA_PCTN,
                32'h00000000
            );
        end

        `TEST_CASE("dift_cwe_190_intovf_cots") begin
            run_cots_attack_case(
                "dift_cwe_190_intovf_cots",
                32'h4000047a,
                32'h400004d2,
                32'h40000448,
                PAYLOAD_200_X,
                32'h00000000
            );
        end

        `TEST_CASE("dift_cwe_193_offbyone_err_cots") begin
            run_cots_attack_case(
                "dift_cwe_193_offbyone_err_cots",
                32'h40000476,
                32'h400004d6,
                32'h40000416,
                PAYLOAD_16A_1X,
                32'h00000000
            );
        end

        `TEST_CASE("dift_cwe_415_double_free_cots") begin
            run_cots_attack_case(
                "dift_cwe_415_double_free_cots",
                32'h4000045a,
                32'h4000049c,
                32'h40000434,
                PAYLOAD_ONE_A,
                32'h00000000
            );
        end

        `TEST_CASE("dift_cwe_476_null_deref_cots") begin
            run_cots_attack_case(
                "dift_cwe_476_null_deref_cots",
                32'h40000476,
                32'h400004b8,
                32'h40000432,
                PAYLOAD_ONE_1,
                32'h00000000
            );
        end

        `TEST_CASE("dift_cwe_676_dangerous_strcpy_cots") begin
            run_cots_attack_case(
                "dift_cwe_676_dangerous_strcpy_cots",
                32'h40000452,
                32'h400004b0,
                32'h40000416,
                PAYLOAD_16A_1X,
                32'h00000000
            );
        end

        `TEST_CASE("dift_cwe_824_uninit_ptr_cots") begin
            run_cots_attack_case(
                "dift_cwe_824_uninit_ptr_cots",
                32'h40000436,
                32'h40000478,
                32'h400003fc,
                PAYLOAD_ONE_1,
                32'h00000000,
                1'b0
            );
        end

        // bench_cots_trusted_runtime: libc/allocator over tainted input, no attack
        `TEST_CASE("bench_cots_trusted_runtime") begin
            run_cots_benign_runtime_case(
                "bench_cots_trusted_runtime",
                32'h410002c8,
                32'h4000042e,
                32'h40000488
            );
        end

        // bench_uart_data_integrity: checksum over tainted UART bytes
        `TEST_CASE("bench_uart_data_integrity") begin
            run_uart_benign_benchmark_case(
                "bench_uart_data_integrity",
                32'h410002e0,
                32'h40000450,
                32'h4000048c,
                PAYLOAD_UART_DATA_INTEGRITY,
                32'h410002c4,
                32'h00004259,
                32'h410002c8,
                32'h767b681a,
                32'h410002cc,
                32'h000023a7,
                1'b0,
                1'b0
            );
        end

        // bench_uart_command_fp: UART command parser, trusted branches resolved
        `TEST_CASE("bench_uart_command_fp") begin
            run_uart_benign_benchmark_case(
                "bench_uart_command_fp",
                32'h410002d8,
                32'h400004d2,
                32'h40000556,
                PAYLOAD_UART_COMMAND_SET_LED7,
                32'h410002c0,
                32'hd1f70077,
                32'h410002c4,
                32'hc0de0007,
                32'h410002c8,
                32'hf00d0007,
                1'b1,
                1'b0
            );
        end

        // diftbypass: tag-only store (p.spsw) then aligned/misaligned loads
        `TEST_CASE("diftbypass") begin

            automatic logic tracing = 0;

            dbg_bhv = new(jtag);

            $display("[TB] =============================================");
            $display("[TB] diftbypass — MISALIGNMENT TAG BUG TRACE");
            $display("[TB] =============================================");

            fork
                // ========================================================
                // Thread 1: Timeout
                // ========================================================
                begin : wd
                    #5000000ns;
                    $display("[TB] TIMEOUT at 5 ms");
                end

                // regfile tag write port + LSU internals tracer
                begin : rf_lsu_trace
                    forever begin
                        @(posedge hsdom_seq.clk);

                        // Activate tracing on first bus access to 0x410FFxxx
                        if (!tracing) begin
                            if (dut.genblk5[0].hsdom_cpu.data_req &&
                                dut.genblk5[0].hsdom_cpu.data_addr[31:12] == 20'h410FF) begin
                                tracing = 1;
                                $display("[TRACE %0t] ===== TRACING ACTIVE =====", $time);
                            end
                        end

                        if (tracing) begin
                            // Sample all signals of interest
                            automatic logic        rf_we;
                            automatic logic        rf_wd;
                            automatic logic [5:0]  rf_wa;
                            automatic logic        lsu_rvalid;
                            automatic logic [3:0]  lsu_rdata_i_tag;
                            automatic logic [3:0]  lsu_rdata_q;
                            automatic logic [3:0]  lsu_rdata_ext;
                            automatic logic        lsu_ex_o_tag;
                            automatic logic [1:0]  lsu_type_q;
                            automatic logic [1:0]  lsu_off_q;
                            automatic logic        lsu_we_q;
                            automatic logic        lsu_misalign_ex;
                            automatic logic        lsu_misalign_o;
                            automatic logic        lsu_gnt_tag;
                            automatic logic        lp_dest_tag;
                            automatic logic        lp_enable_tag;
                            automatic logic        wb_we;
                            automatic logic        bus_req;
                            automatic logic        bus_gnt;
                            automatic logic [31:0] bus_addr;
                            automatic logic        bus_we;
                            automatic logic        bus_rvalid;

                            // Register file tag write port
                            rf_we = dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.id_stage_i.registers_tag_i.we_a_i;
                            rf_wd = dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.id_stage_i.registers_tag_i.wdata_a_i;
                            rf_wa = dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.id_stage_i.registers_tag_i.waddr_a_i;

                            // LSU tag internals
                            lsu_rvalid     = dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.load_store_unit_i.data_rvalid_i_tag;
                            lsu_rdata_i_tag= dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.load_store_unit_i.data_rdata_i_tag;
                            lsu_rdata_q    = dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.load_store_unit_i.rdata_q_tag;
                            lsu_rdata_ext  = dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.load_store_unit_i.data_rdata_ext_tag;
                            lsu_ex_o_tag   = dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.load_store_unit_i.data_rdata_ex_o_tag;
                            lsu_type_q     = dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.load_store_unit_i.data_type_q_tag;
                            lsu_off_q      = dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.load_store_unit_i.rdata_offset_q_tag;
                            lsu_we_q       = dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.load_store_unit_i.data_we_q_tag;
                            lsu_misalign_ex= dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.load_store_unit_i.data_misaligned_ex_i;
                            lsu_misalign_o = dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.load_store_unit_i.data_misaligned_o;
                            lsu_gnt_tag    = dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.load_store_unit_i.data_gnt_i_tag;

                            // load_propagation outputs
                            lp_dest_tag    = dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.id_stage_i.regfile_dest_tag;
                            lp_enable_tag  = dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.id_stage_i.regfile_enable_tag;

                            // Writeback enable (the normal regfile_we_wb_i)
                            wb_we          = dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.id_stage_i.regfile_we_wb_i;

                            // Bus interface (OBI)
                            bus_req    = dut.genblk5[0].hsdom_cpu.data_req;
                            bus_gnt    = dut.genblk5[0].hsdom_cpu.data_gnt;
                            bus_addr   = dut.genblk5[0].hsdom_cpu.data_addr;
                            bus_we     = dut.genblk5[0].hsdom_cpu.data_we;
                            bus_rvalid = dut.genblk5[0].hsdom_cpu.data_rvalid;

                            // Print on any "interesting" event
                            if (rf_we || lsu_rvalid || lsu_misalign_ex || lsu_misalign_o ||
                                lsu_gnt_tag || (bus_req && bus_gnt && bus_addr[31:12] == 20'h410FF)) begin

                                $display("[TRACE %0t] PC=%08h | BUS: req=%0b gnt=%0b addr=%08h we=%0b rvalid=%0b | LSU: rvalid_tag=%0b rdata_i=%04b rdata_q=%04b rdata_ext=%04b ex_o_tag=%0b type_q=%02b off_q=%02b we_q=%0b gnt_tag=%0b mis_ex=%0b mis_o=%0b | LP: dest=%0b en=%0b wb_we=%0b | RF: we=%0b wa=6'h%02h wd=%0b",
                                    $time,
                                    dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.pc_id,
                                    bus_req, bus_gnt, bus_addr, bus_we, bus_rvalid,
                                    lsu_rvalid, lsu_rdata_i_tag, lsu_rdata_q, lsu_rdata_ext, lsu_ex_o_tag,
                                    lsu_type_q, lsu_off_q, lsu_we_q, lsu_gnt_tag,
                                    lsu_misalign_ex, lsu_misalign_o,
                                    lp_dest_tag, lp_enable_tag, wb_we,
                                    rf_we, rf_wa, rf_wd);
                            end
                        end
                    end
                end

                // ========================================================
                // Thread 3: Detect end-of-test (spin loop on any PC)
                // ========================================================
                begin : end_detect
                    automatic int spin_count = 0;
                    automatic logic [31:0] last_pc = '0;
                    forever begin
                        @(posedge hsdom_seq.clk);
                        if (dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.pc_id == last_pc &&
                            last_pc != '0 && tracing)
                            spin_count++;
                        else begin
                            spin_count = 0;
                            last_pc = dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.pc_id;
                        end
                        if (spin_count >= 200) begin
                            $display("[TB %0t] Spin loop at PC=%08h -> ending test", $time, last_pc);
                            break;
                        end
                    end
                end

            join_any
            disable fork;

            $display("[TB] done.");
        end

        // dift_autotaint: HW auto-taint on UART read, branch on it traps
        `TEST_CASE("dift_autotaint") begin

            // Key addresses from work/build/.../dift_autotaint.dump.
            localparam logic [31:0] PC_MAIN        = 32'h4000039e; // main() entry
            localparam logic [31:0] PC_UART_MR_WR  = 32'h400003aa; // sw a0,244(s0) — UART MR=1 (RESUME)
            localparam logic [31:0] PC_UART_MR_RD  = 32'h400003ae; // lw a0,244(s0) — poll UART MR
            localparam logic [31:0] PC_UART_MR_BNE = 32'h400003b2; // bnez → back to UART poll
            localparam logic [31:0] PC_GPIO_MR_WR  = 32'h400003b6; // sw a0,180(s0) — GPIO MR=1 (RESUME)
            localparam logic [31:0] PC_GPIO_MR_RD  = 32'h400003ba; // lw a0,180(s0) — poll GPIO MR
            localparam logic [31:0] PC_GPIO_MR_BNE = 32'h400003be; // bnez → back to GPIO poll
            localparam logic [31:0] PC_UART_INIT   = 32'h400003c8; // jal uart_init
            localparam logic [31:0] PC_UART_SETUP  = 32'h40000350; // inside uart_init baud-rate setup
            localparam logic [31:0] PC_TCR_LI      = 32'h400003ca; // li a0, 24
            localparam logic [31:0] PC_TCR_WRITE   = 32'h400003cc; // csrw 0x7c1, a0
            localparam logic [31:0] PC_DTSR_LI     = 32'h400003dc; // li a0, 16
            localparam logic [31:0] PC_DTSR_WRITE  = 32'h400003de; // sw a0,256(s0)
            localparam logic [31:0] PC_UART_LUI    = 32'h400003e2; // lui a0,0x10001
            localparam logic [31:0] PC_UART_READ   = 32'h400003e6; // lw a0,0(a0) - UART DR
            localparam logic [31:0] PC_BEQ_TAINT   = 32'h400003ea; // beq a0,a1,400003ee
            localparam logic [31:0] PC_SPIN        = 32'h400003f0; // j 400003ee (while(1))

            // Milestone flags
            automatic logic seen_main      = 0;
            automatic logic seen_mr_wr     = 0;
            automatic logic seen_mr_poll   = 0;
            automatic logic seen_past_mr   = 0;
            automatic logic seen_gpio_mr_wr  = 0;
            automatic logic seen_gpio_mr_poll = 0;
            automatic logic seen_uart_init = 0;
            automatic logic seen_uart_setup = 0;
            automatic logic seen_tcr       = 0;
            automatic logic printed_tcr    = 0;
            automatic logic seen_dtsr      = 0;
            automatic logic seen_uart_lui  = 0;
            automatic logic seen_uart_read = 0;
            automatic logic seen_beq       = 0;
            automatic logic seen_spin      = 0;
            automatic logic [31:0] last_pc = 32'h00000000;

            automatic logic seen_taint_en  = 0;
            automatic logic seen_exception = 0;
            automatic int   tag_wr_total   = 0;
            automatic int   pspsw_count    = 0;
            automatic int   tag_rd_total   = 0;
            automatic int   exception_count = 0;
            automatic int   mr_poll_count  = 0;
            automatic int   gpio_mr_poll_count = 0;

            dbg_bhv = new(jtag);

            $display("[TB] =============================================");
            $display("[TB] dift_autotaint — HW Auto-Taint Test");
            $display("[TB] =============================================");
            $display("[TB] >>> DIFT BUILD — no p.spsw, pure HW tainting <<<");
            $display("[TB] PC milestones:");
            $display("[TB]   MAIN       = %08h", PC_MAIN);
            $display("[TB]   UART_MR_WR = %08h  (write MR=1)", PC_UART_MR_WR);
            $display("[TB]   UART_MR_RD = %08h  (poll MR loop)", PC_UART_MR_RD);
            $display("[TB]   GPIO_MR_WR = %08h  (write MR=1)", PC_GPIO_MR_WR);
            $display("[TB]   GPIO_MR_RD = %08h  (poll MR loop)", PC_GPIO_MR_RD);
            $display("[TB]   UART_INIT  = %08h  (past MR polls)", PC_UART_INIT);
            $display("[TB]   TCR_WRITE  = %08h  (csrw TCR)", PC_TCR_WRITE);
            $display("[TB]   DTSR_WRITE = %08h  (enable taint)", PC_DTSR_WRITE);
            $display("[TB]   UART_READ  = %08h  (lw from UART0 DR)", PC_UART_READ);
            $display("[TB]   BEQ_TAINT  = %08h  (branch on taint)", PC_BEQ_TAINT);
            $display("[TB]   SPIN       = %08h  (while(1))", PC_SPIN);

            fork
                // ============================================================
                // Thread 1: Timeout
                // ============================================================
                begin : wd
                    #20000000ns;
                    $display("[TB] TIMEOUT at 20ms");
                end

                // ============================================================
                // Thread 2: PC milestone tracker
                // ============================================================
                begin : milestones
                    forever begin
                        @(posedge hsdom_seq.clk);
                        if (dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.is_decoding &&
                            dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.id_valid) begin

                            automatic logic [31:0] pc;
                            pc = dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.pc_id;
                            last_pc = pc;

                            // --- main() entry ---
                            if (!seen_main && pc == PC_MAIN) begin
                                seen_main = 1;
                                $display("");
                                $display("[MS %0t] >>>>> MAIN() ENTRY <<<<< PC=%08h", $time, pc);
                                $display("[MS %0t]   TPR=%08h  TCR=%08h", $time,
                                    dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.cs_registers_i.tpr_q,
                                    dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.cs_registers_i.tcr_q);
                            end

                            // --- UART MR write (sw a0,244(s0)) ---
                            if (!seen_mr_wr && pc == PC_UART_MR_WR) begin
                                seen_mr_wr = 1;
                                $display("");
                                $display("[MS %0t] >>>>> UART MR WRITE <<<<< PC=%08h", $time, pc);
                                $display("[MS %0t]   Writing MR=1 (RESUME) to SYSCFG LSPA.UART[0]", $time);
                            end

                            // --- UART MR poll (lw a0,244(s0)) ---
                            if (pc == PC_UART_MR_RD) begin
                                mr_poll_count++;
                                if (!seen_mr_poll) begin
                                    seen_mr_poll = 1;
                                    $display("");
                                    $display("[MS %0t] >>>>> UART MR POLL (first) <<<<< PC=%08h", $time, pc);
                                end
                                if (mr_poll_count == 100) begin
                                    $display("[MS %0t] *** MR POLL #100 — UART Maestro appears STUCK ***", $time);
                                    $display("[MS %0t]   lspa_taint_en = %0b", $time,
                                        dut.adam_fabric.lspa_taint_en);
                                end
                                if (mr_poll_count == 500) begin
                                    $display("[MS %0t] *** MR POLL #500 — still stuck, dumping OBI/APB ***", $time);
                                end
                            end

                            // --- GPIO MR write (sw a0,180(s0)) ---
                            if (!seen_gpio_mr_wr && pc == PC_GPIO_MR_WR) begin
                                seen_gpio_mr_wr = 1;
                                $display("");
                                $display("[MS %0t] >>>>> GPIO MR WRITE <<<<< PC=%08h", $time, pc);
                                $display("[MS %0t]   Writing MR=1 (RESUME) to SYSCFG LSPA.GPIO[0]", $time);
                            end

                            // --- GPIO MR poll (lw a0,180(s0)) ---
                            if (pc == PC_GPIO_MR_RD) begin
                                gpio_mr_poll_count++;
                                if (!seen_gpio_mr_poll) begin
                                    seen_gpio_mr_poll = 1;
                                    $display("");
                                    $display("[MS %0t] >>>>> GPIO MR POLL (first) <<<<< PC=%08h", $time, pc);
                                end
                            end

                            // --- Past MR polls → uart_init ---
                            if (!seen_past_mr && seen_mr_poll && pc == PC_UART_INIT) begin
                                seen_past_mr = 1;
                                $display("");
                                $display("[MS %0t] >>>>> PAST MR POLLS → uart_init <<<<< PC=%08h  (uart_polls=%0d gpio_polls=%0d)",
                                    $time, pc, mr_poll_count, gpio_mr_poll_count);
                            end

                            // --- uart_init reached ---
                            if (!seen_uart_init && pc == PC_UART_INIT) begin
                                seen_uart_init = 1;
                                $display("");
                                $display("[MS %0t] >>>>> UART_INIT <<<<< PC=%08h", $time, pc);
                            end

                            if (!seen_uart_setup && pc == PC_UART_SETUP) begin
                                seen_uart_setup = 1;
                                $display("");
                                $display("[MS %0t] >>>>> UART_INIT SETUP <<<<< PC=%08h", $time, pc);
                                $display("[MS %0t]   In uart_init before DIFT TCR/DTSR setup", $time);
                            end

                            // --- TCR write ---
                            if (!seen_tcr && pc == PC_TCR_WRITE) begin
                                seen_tcr = 1;
                                $display("");
                                $display("[MS %0t] >>>>> TCR WRITE <<<<< PC=%08h", $time, pc);
                                $display("[MS %0t]   a0 (TCR val) expected=0x18", $time);
                            end
                            // Print TCR value right after the write
                            if (seen_tcr && !printed_tcr && !seen_dtsr && pc > PC_TCR_WRITE && pc < PC_DTSR_LI) begin
                                $display("[MS %0t]   TPR=%08h  TCR=%08h  (after csrw)", $time,
                                    dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.cs_registers_i.tpr_q,
                                    dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.cs_registers_i.tcr_q);
                                printed_tcr = 1;
                            end

                            // --- DTSR write ---
                            if (!seen_dtsr && pc == PC_DTSR_WRITE) begin
                                seen_dtsr = 1;
                                $display("");
                                $display("[MS %0t] >>>>> DTSR WRITE <<<<< PC=%08h", $time, pc);
                                $display("[MS %0t]   Writing DTSR[UART0]=1 to SYSCFG TAINT_SRC", $time);
                                $display("[MS %0t]   lspa_taint_en BEFORE = %0b", $time,
                                    dut.adam_fabric.lspa_taint_en);
                            end

                            // --- UART lui (setup address) ---
                            if (!seen_uart_lui && pc == PC_UART_LUI) begin
                                seen_uart_lui = 1;
                                $display("");
                                $display("[MS %0t] >>>>> UART0 LUI <<<<< PC=%08h", $time, pc);
                                $display("[MS %0t]   lspa_taint_en = %0b  (UART0 bit should be 1 now)", $time,
                                    dut.adam_fabric.lspa_taint_en);
                            end

                            // --- UART0 data-register read (lw a0,0(a0)) ---
                            if (!seen_uart_read && pc == PC_UART_READ) begin
                                seen_uart_read = 1;
                                $display("");
                                $display("[MS %0t] >>>>> UART0 DR READ <<<<< PC=%08h", $time, pc);
                                $display("[MS %0t]   taint_en = %0b  (UART0 bit MUST be 1 for auto-taint)", $time,
                                    dut.adam_fabric.lspa_taint_en);
                            end

                            // --- beq on tainted value ---
                            if (!seen_beq && pc == PC_BEQ_TAINT) begin
                                seen_beq = 1;
                                $display("");
                                $display("[MS %0t] >>>>> BEQ (branch on tainted) <<<<< PC=%08h", $time, pc);
                                $display("[MS %0t]   rf_tag[10] a0 = %0b  (should be tainted=1)", $time,
                                    dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.id_stage_i.registers_tag_i.rf_reg[10]);
                                $display("[MS %0t]   rf_tag[11] a1 = %0b", $time,
                                    dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.id_stage_i.registers_tag_i.rf_reg[11]);
                                $display("[MS %0t]   alu_op_a_tag = %0b  alu_op_b_tag = %0b", $time,
                                    dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.alu_operand_a_tag,
                                    dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.alu_operand_b_tag);
                                $display("[MS %0t]   TPR=%08h  TCR=%08h", $time,
                                    dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.cs_registers_i.tpr_q,
                                    dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.cs_registers_i.tcr_q);
                            end

                            // --- spin loop ---
                            if (!seen_spin && pc == PC_SPIN) begin
                                seen_spin = 1;
                                $display("");
                                $display("[MS %0t] >>>>> SPIN (while(1)) <<<<< PC=%08h", $time, pc);
                            end
                        end
                    end
                end

                // ============================================================
                // Thread 3: Monitor taint_en signal activation
                // ============================================================
                begin : taint_en_monitor
                    forever begin
                        @(posedge lsdom_seq.clk);
                        if (!seen_taint_en &&
                            dut.adam_fabric.lspa_taint_en[LSPA_UART0_DIFT_BIT]) begin
                            seen_taint_en = 1;
                            $display("");
                            $display("[TB %0t] ===== LSPA UART0 TAINT_EN ACTIVATED =====", $time);
                            $display("[TB %0t]   PC=%08h", $time,
                                dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.pc_id);
                        end
                    end
                end

                // ============================================================
                // Thread 4: Data bus tag monitor
                // ============================================================
                begin : tag_bus_monitor
                    forever begin
                        @(posedge hsdom_seq.clk);

                        // Tag write monitor
                        if (dut.genblk5[0].hsdom_cpu.data_req &&
                            dut.genblk5[0].hsdom_cpu.data_gnt &&
                            dut.genblk5[0].hsdom_cpu.data_we_effective) begin
                            if (dut.genblk5[0].hsdom_cpu.data_tag_wdata != 4'b0000) begin
                                tag_wr_total++;
                                $display("[TAG-WR %0t] addr=%08h tag=%04b PC=%08h",
                                    $time,
                                    dut.genblk5[0].hsdom_cpu.data_addr,
                                    dut.genblk5[0].hsdom_cpu.data_tag_wdata,
                                    dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.pc_id);
                            end

                            // ALERT if any p.spsw appears — this should NOT happen
                            if (dut.genblk5[0].hsdom_cpu.data_we_o_tag &&
                                !dut.genblk5[0].hsdom_cpu.data_we) begin
                                pspsw_count++;
                                $display("[ALERT %0t] UNEXPECTED p.spsw! addr=%08h PC=%08h",
                                    $time,
                                    dut.genblk5[0].hsdom_cpu.data_addr,
                                    dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.pc_id);
                            end
                        end

                        // Tag read monitor — the critical check for auto-taint
                        if (dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.data_rvalid_i) begin
                            if (dut.genblk5[0].hsdom_cpu.data_tag_rdata != 4'b0000) begin
                                tag_rd_total++;
                                $display("[TAG-RD %0t] tag_rdata=%04b data=%08h PC=%08h",
                                    $time,
                                    dut.genblk5[0].hsdom_cpu.data_tag_rdata,
                                    dut.genblk5[0].hsdom_cpu.data_rdata,
                                    dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.pc_id);
                            end
                        end

                        // DIFT exception monitor
                        if (dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.ex_stage_i.exception_o_tag) begin
                            exception_count++;
                            if (!seen_exception) begin
                                seen_exception = 1;
                                $display("");
                                $display("[TB %0t] ===== DIFT EXCEPTION (auto-taint triggered!) =====", $time);
                            end
                            $display("[DIFT-EXC %0t] PC=%08h  check_a=%0b  check_b=%0b",
                                $time,
                                dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.pc_id,
                                dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.ex_stage_i.check_a,
                                dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.ex_stage_i.check_b);
                        end
                    end
                end

                // ============================================================
                // Thread 5: Data bus address monitor (SYSCFG accesses)
                // ============================================================
                begin : bus_monitor
                    forever begin
                        @(posedge hsdom_seq.clk);
                        if (dut.genblk5[0].hsdom_cpu.data_req &&
                            dut.genblk5[0].hsdom_cpu.data_gnt) begin
                            automatic logic [31:0] addr;
                            addr = dut.genblk5[0].hsdom_cpu.data_addr;
                            // Print SYSCFG accesses (0x01000000 - 0x010001FF)
                            if (addr >= 32'h01000000 && addr < 32'h01000200) begin
                                $display("[BUS %0t] SYSCFG %s addr=%08h data=%08h  PC=%08h",
                                    $time,
                                    dut.genblk5[0].hsdom_cpu.data_we_effective ? "WR" : "RD",
                                    addr,
                                    dut.genblk5[0].hsdom_cpu.data_we_effective ?
                                        dut.genblk5[0].hsdom_cpu.data_wdata :
                                        32'hxxxxxxxx,
                                    dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.pc_id);
                                if (dut.genblk5[0].hsdom_cpu.data_we_effective && addr == 32'h01000100) begin
                                    seen_dtsr = 1;
                                end
                            end
                            // Print GPIO accesses (0x10000000)
                            if (addr >= 32'h10000000 && addr < 32'h10000100) begin
                                $display("[BUS %0t] GPIO %s addr=%08h PC=%08h",
                                    $time,
                                    dut.genblk5[0].hsdom_cpu.data_we_effective ? "WR" : "RD",
                                    addr,
                                    dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.pc_id);
                            end
                            if (addr >= 32'h10001000 && addr < 32'h10001100) begin
                                $display("[BUS %0t] UART0 %s addr=%08h PC=%08h",
                                    $time,
                                    dut.genblk5[0].hsdom_cpu.data_we_effective ? "WR" : "RD",
                                    addr,
                                    dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.pc_id);
                                if (seen_dtsr && !dut.genblk5[0].hsdom_cpu.data_we_effective) begin
                                    seen_uart_read = 1;
                                end
                            end
                        end
                        // Print read responses for SYSCFG
                        if (dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.data_rvalid_i) begin
                            automatic logic [31:0] rdata;
                            rdata = dut.genblk5[0].hsdom_cpu.data_rdata;
                            // Only print during MR poll phase
                            if (seen_mr_poll && !seen_past_mr && mr_poll_count <= 10) begin
                                $display("[BUS %0t] RDATA=%08h (MR poll #%0d)  PC=%08h",
                                    $time, rdata, mr_poll_count,
                                    dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.pc_id);
                            end
                        end
                    end
                end

                // ============================================================
                // Thread 6: Periodic status dump (every 100us)
                // ============================================================
                begin : periodic_dump
                    forever begin
                        #100000ns;
                        $display("");
                        $display("[TB %0t] --- STATUS ---  PC=%08h  taint_en=%0b  tag_rd=%0d  tag_wr=%0d  exc=%0d  mr_polls=%0d",
                            $time,
                            dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.pc_id,
                            dut.adam_fabric.lspa_taint_en,
                            tag_rd_total, tag_wr_total, exception_count, mr_poll_count);
                        $display("[TB %0t]   TPR=%08h  TCR=%08h", $time,
                            dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.cs_registers_i.tpr_q,
                            dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.cs_registers_i.tcr_q);
                        $display("[TB %0t]   Milestones: main=%0b mr_wr=%0b mr_poll=%0b past_mr=%0b uart_init=%0b uart_setup=%0b tcr=%0b dtsr=%0b uart_read=%0b beq=%0b spin=%0b",
                            $time,
                            seen_main, seen_mr_wr, seen_mr_poll, seen_past_mr,
                            seen_uart_init, seen_uart_setup, seen_tcr, seen_dtsr, seen_uart_read,
                            seen_beq, seen_spin);
                    end
                end

                // ============================================================
                // Thread 7: End-of-test detector
                // ============================================================
                begin : end_detect
                    automatic int spin_count = 0;
                    forever begin
                        @(posedge hsdom_seq.clk);

                        // Success: exception detected after UART0 read
                        if (seen_uart_read && exception_count >= 1) begin
                            $display("[TB %0t] DIFT exception after tainted peripheral read → settling...", $time);
                            #10000ns;
                            break;
                        end

                        // Spin loop detection (true spin = same PC for 200 cycles)
                        if (dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.pc_id == PC_SPIN)
                            spin_count++;
                        else
                            spin_count = 0;
                        if (spin_count >= 200) begin
                            seen_spin = 1;
                            $display("[TB %0t] Spin loop at PC=%08h → ending", $time, PC_SPIN);
                            break;
                        end

                        // Stuck detection: if MR poll count exceeds threshold
                        if (mr_poll_count >= 50000) begin
                            $display("[TB %0t] STUCK: MR poll count=%0d — UART Maestro never completed RESUME", $time, mr_poll_count);
                            break;
                        end
                    end
                end

            join_any
            disable fork;

            // === Final summary ===
            $display("");
            $display("[TB] =============================================");
            $display("[TB] FINAL SUMMARY — dift_autotaint");
            $display("[TB]   Milestones reached:");
            $display("[TB]     main()       = %s", seen_main      ? "YES" : "NO");
            $display("[TB]     UART MR wr   = %s", seen_mr_wr     ? "YES" : "NO");
            $display("[TB]     UART MR poll = %s  (count=%0d)", seen_mr_poll ? "YES" : "NO", mr_poll_count);
            $display("[TB]     GPIO MR wr   = %s", seen_gpio_mr_wr ? "YES" : "NO");
            $display("[TB]     GPIO MR poll = %s  (count=%0d)", seen_gpio_mr_poll ? "YES" : "NO", gpio_mr_poll_count);
            $display("[TB]     Past MR poll = %s", seen_past_mr   ? "YES" : "NO");
            $display("[TB]     uart_init    = %s", seen_uart_init ? "YES" : "NO");
            $display("[TB]     uart setup   = %s", seen_uart_setup ? "YES" : "NO");
            $display("[TB]     TCR write    = %s", seen_tcr       ? "YES" : "NO");
            $display("[TB]     DTSR write   = %s", seen_dtsr      ? "YES" : "NO");
            $display("[TB]     UART0 read   = %s", seen_uart_read ? "YES" : "NO");
            $display("[TB]     BEQ taint    = %s", seen_beq       ? "YES" : "NO");
            $display("[TB]     Spin loop    = %s", seen_spin      ? "YES" : "NO");
            $display("[TB]   ---");
            $display("[TB]   Taint_en activated  = %s", seen_taint_en ? "YES" : "NO");
            $display("[TB]   Tainted reads (HW)  = %0d", tag_rd_total);
            $display("[TB]   Tagged stores (prop) = %0d", tag_wr_total);
            $display("[TB]   p.spsw writes        = %0d (should be 0!)", pspsw_count);
            $display("[TB]   DIFT exceptions      = %0d", exception_count);
            $display("[TB]   Last decoded PC      = %08h", last_pc);
            $display("[TB]   TPR = %08h   TCR = %08h",
                dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.cs_registers_i.tpr_q,
                dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.cs_registers_i.tcr_q);
            $display("[TB]   Register file tags:");
            for (int r = 0; r < 32; r++) begin
                if (dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.id_stage_i.registers_tag_i.rf_reg[r])
                    $display("[TB]     x%02d = 1  <<<< TAINTED", r);
            end
            $display("[TB] =============================================");

            if (seen_taint_en && seen_uart_read && exception_count >= 1) begin
                $display("[TB] RESULT: PASS — HW auto-taint worked!");
                $display("[TB]   Tainted reads: %0d  |  Exceptions: %0d  |  Tagged stores: %0d  |  p.spsw: %0d",
                    tag_rd_total, exception_count, tag_wr_total, pspsw_count);
                if (pspsw_count > 0)
                    $warning("Unexpected p.spsw writes — app compiled correctly?");
            end else if (!seen_past_mr) begin
                $display("[TB] RESULT: FAIL — stuck at UART MR poll (%0d iterations)", mr_poll_count);
                $display("[TB]   UART Maestro never completed RESUME — check pause handshake");
                $error("Firmware stuck polling SYSCFG LSPA.UART[0].MR");
            end else if (!seen_tcr) begin
                $display("[TB] RESULT: FAIL — firmware never reached TCR write");
                $display("[TB]   Last decoded PC=%08h; if this is %08h, execution is still inside uart_init", last_pc, PC_UART_SETUP);
                $error("Firmware did not reach DIFT configuration");
            end else if (!seen_dtsr) begin
                $display("[TB] RESULT: FAIL — firmware reached TCR but did not write DTSR");
                $display("[TB]   Last decoded PC=%08h", last_pc);
                $error("Firmware did not arm SYSCFG TAINT_SRC.DTSR");
            end else if (!seen_taint_en) begin
                $display("[TB] RESULT: FAIL — DTSR write happened but taint_en never activated");
                $error("Auto-taint enable signal never went high");
            end else if (!seen_uart_read) begin
                $display("[TB] RESULT: FAIL — no tainted read seen (r_user not overridden?)");
                $error("No tainted peripheral read observed");
            end else begin
                $display("[TB] RESULT: FAIL — no DIFT exception (TCR not catching branches?)");
                $error("DIFT exception not triggered despite tainted data");
            end
            $display("[TB] done.");
        end

        // dift_mmio_guard: tainted UART byte forwarded to GPIO ODR write is blocked
        `TEST_CASE("dift_mmio_guard") begin
            automatic int guard_pulse_count = 0;
            automatic int tainted_w_count   = 0;
            automatic int tainted_r_count   = 0;

            // Key addresses from work/build/.../dift_mmio_guard.dump.
            localparam logic [31:0] PC_MAIN        = 32'h4000039e; // main() entry
            localparam logic [31:0] PC_UART_MR_WR  = 32'h400003ae; // sw a0,244(s1) - UART MR=1
            localparam logic [31:0] PC_UART_MR_RD  = 32'h400003b2; // lw a0,244(s1) - poll UART MR
            localparam logic [31:0] PC_GPIO_MR_WR  = 32'h400003ba; // sw a0,180(s1) - GPIO MR=1
            localparam logic [31:0] PC_GPIO_MR_RD  = 32'h400003be; // lw a0,180(s1) - poll GPIO MR
            localparam logic [31:0] PC_UART_SETUP  = 32'h40000350; // inside uart_init baud-rate setup
            localparam logic [31:0] PC_UART_INIT   = 32'h400003d4; // jal uart_init
            localparam logic [31:0] PC_TPR_WRITE   = 32'h400003e8; // csrw 0x7c0, a2
            localparam logic [31:0] PC_TCR_WRITE   = 32'h400003ec; // csrw 0x7c1, a0
            localparam logic [31:0] PC_DTSR_WRITE  = 32'h400003f2; // sw a0,256(s1)
            localparam logic [31:0] PC_MPM_WRITE   = 32'h400003f8; // sw a0,260(s1)
            localparam logic [31:0] PC_MPS_CLEAR   = 32'h400003fc; // sw a0,264(s1)
            localparam logic [31:0] PC_UART_READ   = 32'h40000404; // lw a0,0(a0)
            localparam logic [31:0] PC_GPIO_WRITE  = 32'h40000406; // sw tainted value to GPIO ODR
            localparam logic [31:0] PC_MPS_READ    = 32'h4000040e; // lw a0,264(s1)
            localparam logic [31:0] PC_RESULT_WR   = 32'h4000042a; // final GPIO result write
            localparam logic [31:0] PC_SPIN        = 32'h4000042e; // j 4000042c

            automatic logic seen_main         = 0;
            automatic logic seen_uart_mr_wr   = 0;
            automatic logic seen_uart_mr_poll = 0;
            automatic logic seen_gpio_mr_wr   = 0;
            automatic logic seen_gpio_mr_poll = 0;
            automatic logic seen_uart_setup   = 0;
            automatic logic seen_uart_init    = 0;
            automatic logic seen_tpr          = 0;
            automatic logic seen_tcr          = 0;
            automatic logic seen_dtsr         = 0;
            automatic logic seen_mpm          = 0;
            automatic logic seen_mps_clear    = 0;
            automatic logic seen_uart_read    = 0;
            automatic logic seen_gpio_write   = 0;
            automatic logic seen_mps_read     = 0;
            automatic logic seen_result_wr    = 0;
            automatic logic seen_spin         = 0;
            automatic logic [31:0] last_pc    = 32'h00000000;

            dbg_bhv = new(jtag);

            $display("[TB] =============================================");
            $display("[TB] dift_mmio_guard — Attack #17 (Tainted MMIO Write Guard)");
            $display("[TB] =============================================");
            $display("[TB] PC milestones:");
            $display("[TB]   MAIN       = %08h", PC_MAIN);
            $display("[TB]   UART_INIT  = %08h", PC_UART_INIT);
            $display("[TB]   TPR_WRITE  = %08h", PC_TPR_WRITE);
            $display("[TB]   TCR_WRITE  = %08h", PC_TCR_WRITE);
            $display("[TB]   DTSR_WRITE = %08h", PC_DTSR_WRITE);
            $display("[TB]   MPM_WRITE  = %08h", PC_MPM_WRITE);
            $display("[TB]   MPS_CLEAR  = %08h", PC_MPS_CLEAR);
            $display("[TB]   UART_READ  = %08h", PC_UART_READ);
            $display("[TB]   GPIO_WRITE = %08h", PC_GPIO_WRITE);
            $display("[TB]   MPS_READ   = %08h", PC_MPS_READ);
            $display("[TB]   SPIN       = %08h", PC_SPIN);

            fork
                begin : wd
                    #5000000ns;
                    $display("[TB] TIMEOUT at 5ms");
                end

                // --- PC milestone tracker ---
                begin : milestones
                    forever begin
                        @(posedge hsdom_seq.clk);
                        if (dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.is_decoding &&
                            dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.id_valid) begin
                            automatic logic [31:0] pc;
                            pc = dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.pc_id;
                            last_pc = pc;

                            if (!seen_main && pc == PC_MAIN) begin
                                seen_main = 1;
                                $display("[MS %0t] MMIO main() PC=%08h", $time, pc);
                            end
                            if (!seen_uart_mr_wr && pc == PC_UART_MR_WR) begin
                                seen_uart_mr_wr = 1;
                                $display("[MS %0t] MMIO UART MR write PC=%08h", $time, pc);
                            end
                            if (!seen_uart_mr_poll && pc == PC_UART_MR_RD) begin
                                seen_uart_mr_poll = 1;
                                $display("[MS %0t] MMIO UART MR poll PC=%08h", $time, pc);
                            end
                            if (!seen_gpio_mr_wr && pc == PC_GPIO_MR_WR) begin
                                seen_gpio_mr_wr = 1;
                                $display("[MS %0t] MMIO GPIO MR write PC=%08h", $time, pc);
                            end
                            if (!seen_gpio_mr_poll && pc == PC_GPIO_MR_RD) begin
                                seen_gpio_mr_poll = 1;
                                $display("[MS %0t] MMIO GPIO MR poll PC=%08h", $time, pc);
                            end
                            if (!seen_uart_init && pc == PC_UART_INIT) begin
                                seen_uart_init = 1;
                                $display("[MS %0t] MMIO uart_init call PC=%08h", $time, pc);
                            end
                            if (!seen_uart_setup && pc == PC_UART_SETUP) begin
                                seen_uart_setup = 1;
                                $display("[MS %0t] MMIO uart_init setup PC=%08h", $time, pc);
                            end
                            if (!seen_tpr && pc == PC_TPR_WRITE) begin
                                seen_tpr = 1;
                                $display("[MS %0t] MMIO TPR write PC=%08h", $time, pc);
                            end
                            if (!seen_tcr && pc == PC_TCR_WRITE) begin
                                seen_tcr = 1;
                                $display("[MS %0t] MMIO TCR write PC=%08h", $time, pc);
                            end
                            if (!seen_dtsr && pc == PC_DTSR_WRITE) begin
                                seen_dtsr = 1;
                                $display("[MS %0t] MMIO DTSR write PC=%08h", $time, pc);
                            end
                            if (!seen_mpm && pc == PC_MPM_WRITE) begin
                                seen_mpm = 1;
                                $display("[MS %0t] MMIO MPM write PC=%08h", $time, pc);
                            end
                            if (!seen_mps_clear && pc == PC_MPS_CLEAR) begin
                                seen_mps_clear = 1;
                                $display("[MS %0t] MMIO MPS clear PC=%08h", $time, pc);
                            end
                            if (!seen_uart_read && pc == PC_UART_READ) begin
                                seen_uart_read = 1;
                                $display("[MS %0t] MMIO UART0 read PC=%08h", $time, pc);
                            end
                            if (!seen_gpio_write && pc == PC_GPIO_WRITE) begin
                                seen_gpio_write = 1;
                                $display("[MS %0t] MMIO tainted GPIO write PC=%08h", $time, pc);
                            end
                            if (!seen_mps_read && pc == PC_MPS_READ) begin
                                seen_mps_read = 1;
                                $display("[MS %0t] MMIO MPS read PC=%08h", $time, pc);
                            end
                            if (!seen_result_wr && pc == PC_RESULT_WR) begin
                                seen_result_wr = 1;
                                $display("[MS %0t] MMIO result GPIO write PC=%08h", $time, pc);
                            end
                            if (!seen_spin && pc == PC_SPIN) begin
                                seen_spin = 1;
                                $display("[MS %0t] MMIO spin PC=%08h", $time, pc);
                            end
                        end
                    end
                end

                // --- Guard pulse monitor ---
                begin : guard_mon
                    forever begin
                        @(posedge lsdom_seq.clk);
`ifdef DIFT
                        if (dut.lspa_guard_exc[LSPA_GPIO0_DIFT_BIT]) begin
                            guard_pulse_count++;
                            $display("[TB %0t] >>> GUARD PULSE on LSPA <<< count=%0d  (w_user=%0h w_strb_in=%0h aw_addr=%08h w_data=%08h)",
                                $time, guard_pulse_count,
                                dut.adam_fabric.genblk1.adam_dift_periph_guard_lspa.slv.w_user,
                                dut.adam_fabric.genblk1.adam_dift_periph_guard_lspa.slv.w_strb,
                                dut.adam_fabric.genblk1.adam_dift_periph_guard_lspa.slv.aw_addr,
                                dut.adam_fabric.genblk1.adam_dift_periph_guard_lspa.slv.w_data);
                        end
`endif
                    end
                end

                // --- CPU store-tag visibility (independent of the guard) ---
                begin : cpu_store_mon
                    forever begin
                        @(posedge hsdom_seq.clk);
                        if (dut.genblk5[0].hsdom_cpu.data_req &&
                            dut.genblk5[0].hsdom_cpu.data_gnt &&
                            dut.genblk5[0].hsdom_cpu.data_we_effective) begin
                            if (dut.genblk5[0].hsdom_cpu.data_tag_wdata != 4'b0000) begin
                                $display("[CPU-STORE-TAG %0t] addr=%08h data=%08h tag=%04b PC=%08h",
                                    $time,
                                    dut.genblk5[0].hsdom_cpu.data_addr,
                                    dut.genblk5[0].hsdom_cpu.data_wdata,
                                    dut.genblk5[0].hsdom_cpu.data_tag_wdata,
                                    dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.pc_id);
                            end
                        end
                    end
                end

                // --- Tainted-traffic bookkeeping ---
                begin : traf_mon
                    forever begin
                        @(posedge lsdom_seq.clk);
`ifdef DIFT
                        if (dut.adam_fabric.genblk1.adam_dift_periph_guard_lspa.slv.r_valid &&
                            dut.adam_fabric.genblk1.adam_dift_periph_guard_lspa.slv.r_ready &&
                            dut.adam_fabric.genblk1.adam_dift_periph_guard_lspa.slv.r_user != '0) begin
                            tainted_r_count++;
                        end
                        if (dut.adam_fabric.genblk1.adam_dift_periph_guard_lspa.slv.w_valid &&
                            dut.adam_fabric.genblk1.adam_dift_periph_guard_lspa.slv.w_ready &&
                            dut.adam_fabric.genblk1.adam_dift_periph_guard_lspa.slv.w_user != '0) begin
                            tainted_w_count++;
                        end
`endif
                    end
                end

                // --- End-of-test: wait for guard + settle ---
                begin : end_detect
                    forever begin
                        @(posedge lsdom_seq.clk);
                        if (guard_pulse_count >= 1) begin
                            #100000ns;
                            break;
                        end
                    end
                end
            join_any
            disable fork;

            $display("");
            $display("[TB] =============================================");
            $display("[TB] FINAL SUMMARY — dift_mmio_guard");
            $display("[TB]   main=%0b uart_init=%0b uart_setup=%0b tpr=%0b tcr=%0b dtsr=%0b mpm=%0b mps_clear=%0b",
                seen_main, seen_uart_init, seen_uart_setup, seen_tpr, seen_tcr,
                seen_dtsr, seen_mpm, seen_mps_clear);
            $display("[TB]   uart_read=%0b gpio_write=%0b mps_read=%0b result_wr=%0b spin=%0b last_pc=%08h",
                seen_uart_read, seen_gpio_write, seen_mps_read, seen_result_wr,
                seen_spin, last_pc);
            $display("[TB]   Tainted reads through LSPA guard = %0d", tainted_r_count);
            $display("[TB]   Tainted writes through LSPA guard = %0d", tainted_w_count);
            $display("[TB]   Guard pulses                   = %0d", guard_pulse_count);
            $display("[TB] =============================================");

            if (guard_pulse_count >= 1) begin
                $display("[TB] RESULT: PASS — MMIO write guard fired on tainted store.");
            end else if (!seen_tpr) begin
                $display("[TB] RESULT: FAIL — firmware never reached DIFT setup");
                $display("[TB]   Last decoded PC=%08h; if this is %08h, execution is still inside uart_init", last_pc, PC_UART_SETUP);
                $error("Firmware did not reach MMIO guard configuration");
            end else if (!seen_dtsr || !seen_mpm) begin
                $display("[TB] RESULT: FAIL — firmware did not arm DTSR/MPM completely");
                $error("MMIO guard policy registers were not fully configured");
            end else if (!seen_uart_read) begin
                $display("[TB] RESULT: FAIL — no UART0 source read reached");
                $error("No tainted source read before MMIO guard check");
            end else if (!seen_gpio_write) begin
                $display("[TB] RESULT: FAIL — no GPIO sink write reached");
                $error("No guarded sink write observed");
            end else begin
                $error("Guard never fired — tainted MMIO write not blocked");
            end
            $display("[TB] done.");
        end

        // dift_no_autotaint_ra: same exploit as dift_autotaint_ra with DTSR=0,
        // exploit succeeds — shows auto-taint alone is what detection relies on
        `TEST_CASE("dift_no_autotaint_ra") begin
            // PC addresses from dift_no_autotaint_ra.dump
            localparam logic [31:0] PC_MAIN        = 32'h400003d0;
            localparam logic [31:0] PC_TCR_WRITE   = 32'h4000040a; // csrw 0x7c1, a0
            // No DTSR write in Config-B — the binary does not touch DTSR
            localparam logic [31:0] PC_VULN_ENTRY  = 32'h4000039e; // vuln_read entry
            localparam logic [31:0] PC_VULN_RET    = 32'h400003ce; // ret in vuln_read
            localparam logic [31:0] PC_AFTER_VULN  = 32'h40000424; // first insn after jal vuln_read
            localparam logic [31:0] PC_SPIN        = 32'h40000430; // j 0x40000430 (while(1))

            automatic logic seen_main         = 0;
            automatic logic seen_tcr          = 0;
            automatic logic seen_vuln         = 0;
            automatic logic seen_vuln_ret    = 0;
            automatic logic seen_after_vuln  = 0;
            automatic logic seen_spin         = 0;
            automatic int   tag_wr_total      = 0;
            automatic int   tag_rd_total      = 0;
            automatic int   exception_count   = 0;
            automatic int   dtsr_write_count  = 0;

            dbg_bhv = new(jtag);

            $display("[TB] =============================================");
            $display("[TB] dift_no_autotaint_ra — Config-B (DIFT armed, DTSR=0)");
            $display("[TB] =============================================");
            $display("[TB] >>> Expected: vuln_read returns, post-call code runs, 0 DIFT exceptions <<<");

            fork
                begin : wd
                    #15000000ns;
                    $display("[TB] TIMEOUT at 15ms");
                end

                // ---- PC milestone tracker ----
                begin : milestones
                    forever begin
                        @(posedge hsdom_seq.clk);
                        if (dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.is_decoding &&
                            dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.id_valid) begin
                            automatic logic [31:0] pc;
                            pc = dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.pc_id;

                            if (!seen_main && pc == PC_MAIN) begin
                                seen_main = 1;
                                $display("[MS %0t] MAIN entry PC=%08h  TPR=%08h  TCR=%08h", $time, pc,
                                    dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.cs_registers_i.tpr_q,
                                    dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.cs_registers_i.tcr_q);
                            end
                            if (!seen_tcr && pc == PC_TCR_WRITE) begin
                                seen_tcr = 1;
                                $display("[MS %0t] TCR write PC=%08h", $time, pc);
                            end
                            if (!seen_vuln && pc == PC_VULN_ENTRY) begin
                                seen_vuln = 1;
                                $display("[MS %0t] vuln_read entry PC=%08h", $time, pc);
                            end
                            if (!seen_vuln_ret && seen_vuln && pc == PC_VULN_RET) begin
                                seen_vuln_ret = 1;
                                $display("[MS %0t] vuln_read RET reached PC=%08h", $time, pc);
                                $display("[MS %0t]   rf_tag[1] ra = %0b  (expect 0 — auto-taint OFF)", $time,
                                    dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.id_stage_i.registers_tag_i.rf_reg[1]);
                            end
                            if (!seen_after_vuln && seen_vuln_ret && pc == PC_AFTER_VULN) begin
                                seen_after_vuln = 1;
                                $display("[MS %0t] >>> POST-VULN code reached <<< PC=%08h  (Config-B: vuln_read returned with no DIFT trap)", $time, pc);
                            end
                            if (!seen_spin && pc == PC_SPIN) begin
                                seen_spin = 1;
                                $display("[MS %0t] spin reached PC=%08h", $time, pc);
                            end
                        end
                    end
                end

                // ---- Tag bus + exception monitor ----
                begin : tag_bus_monitor
                    forever begin
                        @(posedge hsdom_seq.clk);
                        if (dut.genblk5[0].hsdom_cpu.data_req &&
                            dut.genblk5[0].hsdom_cpu.data_gnt &&
                            dut.genblk5[0].hsdom_cpu.data_we_effective &&
                            dut.genblk5[0].hsdom_cpu.data_tag_wdata != 4'b0000) begin
                            tag_wr_total++;
                        end
                        if (dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.data_rvalid_i &&
                            dut.genblk5[0].hsdom_cpu.data_tag_rdata != 4'b0000) begin
                            tag_rd_total++;
                        end
                        if (dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.ex_stage_i.exception_o_tag) begin
                            exception_count++;
                            $display("[DIFT-EXC %0t] UNEXPECTED exception_o_tag PC=%08h",
                                $time, dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.pc_id);
                        end
                        if (dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.id_stage_i.execute_pc_tag &&
                            dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.id_stage_i.pc_id_i_tag &&
                            dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.is_decoding) begin
                            exception_count++;
                            $display("[DIFT-EXC %0t] UNEXPECTED EXECUTE_PC trap PC=%08h",
                                $time, dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.pc_id);
                        end
                    end
                end

                // ---- DTSR sanity: must remain 0 throughout the run ----
                begin : dtsr_check
                    forever begin
                        @(posedge lsdom_seq.clk);
                        if (dut.adam_fabric.lspa_taint_en !== '0) begin
                            dtsr_write_count++;
                            $display("[TB %0t] *** Config-B violation: lspa_taint_en went HIGH (DTSR was written) ***", $time);
                        end
                    end
                end

                // ---- End-of-test ----
                begin : end_detect
                    automatic int spin_count = 0;
                    forever begin
                        @(posedge hsdom_seq.clk);
                        if (seen_after_vuln) begin
                            #5000ns;
                            // Continue a little longer to make sure no late trap fires
                        end
                        if (dut.genblk5[0].hsdom_cpu.cv32e40p_top.core_i.pc_id == PC_SPIN)
                            spin_count++;
                        else
                            spin_count = 0;
                        if (spin_count >= 200) begin
                            $display("[TB %0t] Spin loop reached → ending", $time);
                            break;
                        end
                    end
                end
            join_any
            disable fork;

            $display("");
            $display("[TB] =============================================");
            $display("[TB] FINAL SUMMARY — dift_no_autotaint_ra (Config-B)");
            $display("[TB]   vuln_read returned    = %s", seen_vuln_ret   ? "YES" : "NO");
            $display("[TB]   post-vuln code ran    = %s", seen_after_vuln ? "YES" : "NO");
            $display("[TB]   spin reached          = %s", seen_spin       ? "YES" : "NO");
            $display("[TB]   DIFT exceptions       = %0d  (expect 0)", exception_count);
            $display("[TB]   Tainted tag writes    = %0d  (expect 0)", tag_wr_total);
            $display("[TB]   Tainted tag reads     = %0d  (expect 0)", tag_rd_total);
            $display("[TB]   DTSR-violation count  = %0d  (expect 0)", dtsr_write_count);
            $display("[TB] =============================================");

            // Config-B PASS = vulnerable function returned cleanly with no DIFT trap
            if (seen_vuln_ret && seen_after_vuln && exception_count == 0 &&
                tag_wr_total == 0 && tag_rd_total == 0 && dtsr_write_count == 0) begin
                $display("[TB] RESULT: PASS — Config-B reproduced. DIFT armed, auto-taint OFF, untainted UART data flowed through fabric/SRAM, vuln_read returned with no exception. Auto-tainting is the missing ingredient.");
            end else if (exception_count > 0) begin
                $error("Config-B inconsistent: DIFT exception fired despite DTSR=0");
            end else if (dtsr_write_count > 0) begin
                $error("Config-B violation: lspa_taint_en went high during the run");
            end else if (tag_wr_total > 0 || tag_rd_total > 0) begin
                $error("Config-B inconsistent: non-zero tag traffic on data bus while DTSR=0");
            end else begin
                $display("[TB] RESULT: INCONCLUSIVE — vuln_read did not complete (check timeout / PC milestones).");
            end
            $display("[TB] done.");
        end
    end
endmodule