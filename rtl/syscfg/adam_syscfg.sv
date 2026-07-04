/*
 * Copyright 2025 LIRMM
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

`include "adam/macros.svh"

module adam_syscfg #(
    `ADAM_CFG_PARAMS
) (
    ADAM_SEQ.Slave   seq,
    ADAM_PAUSE.Slave pause,

    AXI_LITE.Slave slv,

    output logic      lsdom_rst,
    ADAM_PAUSE.Master lsdom_pause,

    output logic      hsdom_rst,
    ADAM_PAUSE.Master hsdom_pause,

    output logic      fab_lsdom_rst,
    ADAM_PAUSE.Master fab_lsdom_pause,

    output logic      fab_hsdom_rst,
    ADAM_PAUSE.Master fab_hsdom_pause,

    output logic      fab_lspa_rst,
    ADAM_PAUSE.Master fab_lspa_pause,

    output logic      fab_lspb_rst,
    ADAM_PAUSE.Master fab_lspb_pause,

    output logic      lpcpu_rst,
    ADAM_PAUSE.Master lpcpu_pause,
    output ADDR_T     lpcpu_boot_addr,
    output logic      lpcpu_irq,

    output logic      lpmem_rst,
    ADAM_PAUSE.Master lpmem_pause,

    output logic      cpu_rst       [NO_CPUS+1],
    ADAM_PAUSE.Master cpu_pause     [NO_CPUS+1],
    output ADDR_T     cpu_boot_addr [NO_CPUS+1],
    output logic      cpu_irq       [NO_CPUS+1],

    output logic      dma_rst   [NO_DMAS+1],
    ADAM_PAUSE.Master dma_pause [NO_DMAS+1],
    output logic      dma_irq   [NO_DMAS+1],

    output logic      mem_rst   [NO_MEMS+1],
    ADAM_PAUSE.Master mem_pause [NO_MEMS+1],

    output logic      lspa_rst   [NO_LSPAS+1],
    ADAM_PAUSE.Master lspa_pause [NO_LSPAS+1],
    input  logic      lspa_irq   [NO_LSPAS+1],

    output logic      lspb_rst   [NO_LSPBS+1],
    ADAM_PAUSE.Master lspb_pause [NO_LSPBS+1],
    input  logic      lspb_irq   [NO_LSPBS+1],

    output logic      hsp_rst   [NO_HSPS+1],
    ADAM_PAUSE.Master hsp_pause [NO_HSPS+1],
    input  logic      hsp_irq   [NO_HSPS+1]

`ifdef DIFT
    , output logic [NO_LSPAS:0] lspa_taint_en,
    output logic [NO_LSPBS:0]   lspb_taint_en,
    output logic [NO_LSPAS:0]   lspa_guard_en,
    output logic [NO_LSPBS:0]   lspb_guard_en,
    input  logic [NO_LSPAS:0]   lspa_guard_exc,
    input  logic [NO_LSPBS:0]   lspb_guard_exc
`endif
);

    localparam NO_TGTS = 4 + EN_LSPA + EN_LSPB + EN_HSP + EN_LPCPU + EN_LPMEM +
        NO_CPUS + NO_DMAS + NO_MEMS + NO_LSPAS + NO_LSPBS
`ifdef DIFT
        + 1
`endif
        ;

`ifdef DIFT
    localparam int unsigned DIFT_LSPA_S = 0;
    localparam int unsigned DIFT_LSPB_S = DIFT_LSPA_S + NO_LSPAS;
    localparam int unsigned DIFT_NO_PERIPHS = NO_LSPAS + NO_LSPBS;

    initial begin
        assert (DIFT_NO_PERIPHS <= DATA_WIDTH)
        else $error("DIFT peripheral bitfields require %0d bits but DATA_WIDTH is %0d",
            DIFT_NO_PERIPHS, DATA_WIDTH);
    end
`endif

    DATA_T irq_vec;

    // Pause ==================================================================

    ADAM_PAUSE apb_pause ();
    ADAM_PAUSE tgt_demux_pause ();
    ADAM_PAUSE tgt_pause [NO_TGTS+1] ();
    ADAM_PAUSE pause_null ();
    ADAM_PAUSE temp_pause [3] ();
    assign temp_pause[0].ack        = apb_pause.ack;
    assign temp_pause[1].ack        = tgt_demux_pause.ack;
    assign temp_pause[2].ack        = pause_null.ack;
    assign apb_pause.req            = temp_pause[0].req;
    assign tgt_demux_pause.req      = temp_pause[1].req;
    assign pause_null.req           = temp_pause[2].req;

    adam_pause_demux #(
        .NO_MSTS  (2),
        .PARALLEL (0)
    ) top_pause_demux (
        .seq (seq),

        .slv (pause),
        .mst (temp_pause)
    );

    adam_pause_demux #(
        .NO_MSTS  (NO_TGTS),
        .PARALLEL (1)
    ) tgt_pause_demux (
        .seq (seq),

        .slv (tgt_demux_pause),
        .mst (tgt_pause)
    );

    // Interconnect ===========================================================

    localparam type RULE_T = adam_cfg_pkg::MMAP_T;

    `ADAM_APB_I tgt_apb [NO_TGTS+1] ();

    RULE_T tgt_addr_map [NO_TGTS+1];

    generate
        for (genvar i = 0; i < NO_TGTS; i++) begin
            assign tgt_addr_map[i] = '{
                start : STRB_WIDTH * 4*i,
                end_  : STRB_WIDTH * 4*(i+1),
                inc   : '0
            };
        end
    endgenerate

    adam_axil_apb_bridge #(
        `ADAM_CFG_PARAMS_MAP,

        .NO_MSTS (NO_TGTS),

        .RULE_T (RULE_T)
    ) adam_axil_apb_bridge (
        .seq   (seq),
        .pause (apb_pause),

        .slv (slv),
        .mst (tgt_apb),

        .addr_map (tgt_addr_map)
    );

    // tgt mapping ============================================================

    generate
        localparam LSDOM_S = 0;
        localparam LSDOM_E = LSDOM_S + 1;

        localparam HSDOM_S = LSDOM_E;
        localparam HSDOM_E = HSDOM_S + 1;

        localparam FAB_LSDOM_S = HSDOM_E;
        localparam FAB_LSDOM_E = FAB_LSDOM_S + 1;

        localparam FAB_HSDOM_S = FAB_LSDOM_E;
        localparam FAB_HSDOM_E = FAB_HSDOM_S + 1;

        localparam FAB_LSPA_S = FAB_HSDOM_E;
        localparam FAB_LSPA_E = FAB_LSPA_S + EN_LSPA;

        localparam FAB_LSPB_S = FAB_LSPA_E;
        localparam FAB_LSPB_E = FAB_LSPB_S + EN_LSPB;

        localparam LPCPU_S = FAB_LSPB_E;
        localparam LPCPU_E = LPCPU_S + EN_LPCPU;

        localparam LPMEM_S = LPCPU_E;
        localparam LPMEM_E = LPMEM_S + EN_LPMEM;

        localparam CPU_S = LPMEM_E;
        localparam CPU_E = CPU_S + NO_CPUS;

        localparam DMA_S = CPU_E;
        localparam DMA_E = DMA_S + NO_DMAS;

        localparam MEM_S = DMA_E;
        localparam MEM_E = MEM_S + NO_MEMS;

        localparam LSPA_S = MEM_E;
        localparam LSPA_E = LSPA_S + NO_LSPAS;

        localparam LSPB_S = LSPA_E;
        localparam LSPB_E = LSPB_S + NO_LSPBS;

        localparam HSP_S = LSPB_E;
        localparam HSP_E = HSP_S + NO_HSPS;

        for (genvar i = LSDOM_S; i < LSDOM_E; i++) begin
            adam_syscfg_tgt #(
                `ADAM_CFG_PARAMS_MAP,

                .EN_BOOTSTRAP (1),
                .EN_BOOT_ADDR (0),
                .EN_IRQ       (0)
            ) tgt_lsdom (
                .seq   (seq),
                .pause (tgt_pause[i]),

                .slv (tgt_apb[i]),

                .irq_vec (irq_vec),

                .tgt_rst       (lsdom_rst),
                .tgt_pause     (lsdom_pause),
                .tgt_boot_addr (),
                .tgt_irq       ()
            );
        end

        for (genvar i = HSDOM_S; i < HSDOM_E; i++) begin
            adam_syscfg_tgt #(
                `ADAM_CFG_PARAMS_MAP,

                .EN_BOOTSTRAP (1),
                .EN_BOOT_ADDR (0),
                .EN_IRQ       (0)
            ) tgt_hsdom (
                .seq   (seq),
                .pause (tgt_pause[i]),

                .slv (tgt_apb[i]),

                .irq_vec (irq_vec),

                .tgt_rst       (hsdom_rst),
                .tgt_pause     (hsdom_pause),
                .tgt_boot_addr (),
                .tgt_irq       ()
            );
        end

        for (genvar i = FAB_LSDOM_S; i < FAB_LSDOM_E; i++) begin
            adam_syscfg_tgt #(
                `ADAM_CFG_PARAMS_MAP,

                .EN_BOOTSTRAP (1),
                .EN_BOOT_ADDR (0),
                .EN_IRQ       (0)
            ) tgt_fab_lsdom (
                .seq   (seq),
                .pause (tgt_pause[i]),

                .slv (tgt_apb[i]),

                .irq_vec (irq_vec),

                .tgt_rst       (fab_lsdom_rst),
                .tgt_pause     (fab_lsdom_pause),
                .tgt_boot_addr (),
                .tgt_irq       ()
            );
        end

        for (genvar i = FAB_HSDOM_S; i < FAB_HSDOM_E; i++) begin
            adam_syscfg_tgt #(
                `ADAM_CFG_PARAMS_MAP,

                .EN_BOOTSTRAP (1),
                .EN_BOOT_ADDR (0),
                .EN_IRQ       (0)
            ) tgt_fab_hsdom (
                .seq   (seq),
                .pause (tgt_pause[i]),

                .slv (tgt_apb[i]),

                .irq_vec (irq_vec),

                .tgt_rst       (fab_hsdom_rst),
                .tgt_pause     (fab_hsdom_pause),
                .tgt_boot_addr (),
                .tgt_irq       ()
            );
        end

        for (genvar i = FAB_LSPA_S; i < FAB_LSPA_E; i++) begin
            adam_syscfg_tgt #(
                `ADAM_CFG_PARAMS_MAP,

                .EN_BOOTSTRAP (1),
                .EN_BOOT_ADDR (0),
                .EN_IRQ       (0)
            ) tgt_fab_lspa (
                .seq   (seq),
                .pause (tgt_pause[i]),

                .slv (tgt_apb[i]),

                .irq_vec (irq_vec),

                .tgt_rst       (fab_lspa_rst),
                .tgt_pause     (fab_lspa_pause),
                .tgt_boot_addr (),
                .tgt_irq       ()
            );
        end
        if (!EN_LSPA) begin
            assign fab_lspa_rst = '1;
            `ADAM_PAUSE_MST_TIE_OFF(fab_lspa_pause);
        end

        for (genvar i = FAB_LSPB_S; i < FAB_LSPB_E; i++) begin
            adam_syscfg_tgt #(
                `ADAM_CFG_PARAMS_MAP,

                .EN_BOOTSTRAP (0),
                .EN_BOOT_ADDR (0),
                .EN_IRQ       (0)
            ) tgt_fab_lspb (
                .seq   (seq),
                .pause (tgt_pause[i]),

                .slv (tgt_apb[i]),

                .irq_vec (irq_vec),

                .tgt_rst       (fab_lspb_rst),
                .tgt_pause     (fab_lspb_pause),
                .tgt_boot_addr (),
                .tgt_irq       ()
            );
        end
        if (!EN_LSPB) begin
            assign fab_lspb_rst = '1;
            `ADAM_PAUSE_MST_TIE_OFF(fab_lspb_pause);
        end

        for (genvar i = LPCPU_S; i < LPCPU_E; i++) begin
            adam_syscfg_tgt #(
                `ADAM_CFG_PARAMS_MAP,

                .EN_BOOTSTRAP (EN_BOOTSTRAP_LPCPU),
                .EN_BOOT_ADDR (1),
                .EN_IRQ       (1)
            ) tgt_lpcpu (
                .seq   (seq),
                .pause (tgt_pause[i]),

                .slv (tgt_apb[i]),

                .irq_vec (irq_vec),

                .tgt_rst       (lpcpu_rst),
                .tgt_pause     (lpcpu_pause),
                .tgt_boot_addr (lpcpu_boot_addr),
                .tgt_irq       (lpcpu_irq)
            );
        end
        if (!EN_LPCPU) begin
            assign lpcpu_rst = '1;
            `ADAM_PAUSE_MST_TIE_OFF(lpcpu_pause);
        end

        for (genvar i = LPMEM_S; i < LPMEM_E; i++) begin
            adam_syscfg_tgt #(
                `ADAM_CFG_PARAMS_MAP,

                .EN_BOOTSTRAP (EN_BOOTSTRAP_LPMEM),
                .EN_BOOT_ADDR (0),
                .EN_IRQ       (0)
            ) tgt_lpmem (
                .seq   (seq),
                .pause (tgt_pause[i]),

                .slv (tgt_apb[i]),

                .irq_vec (irq_vec),

                .tgt_rst       (lpmem_rst),
                .tgt_pause     (lpmem_pause),
                .tgt_boot_addr (),
                .tgt_irq       ()
            );
        end
        if (!EN_LPMEM) begin
            assign lpmem_rst = '1;
            `ADAM_PAUSE_MST_TIE_OFF(lpmem_pause);
        end

        for (genvar i = CPU_S; i < CPU_E; i++) begin
            adam_syscfg_tgt #(
                `ADAM_CFG_PARAMS_MAP,

                .EN_BOOTSTRAP ((i == CPU_S) ? EN_BOOTSTRAP_CPU0 : 0),
                .EN_BOOT_ADDR (1),
                .EN_IRQ       (1)
            ) tgt_cpu (
                .seq   (seq),
                .pause (tgt_pause[i]),

                .slv (tgt_apb[i]),

                .irq_vec (irq_vec),

                .tgt_rst       (cpu_rst      [i-CPU_S]),
                .tgt_pause     (cpu_pause    [i-CPU_S]),
                .tgt_boot_addr (cpu_boot_addr[i-CPU_S]),
                .tgt_irq       (cpu_irq      [i-CPU_S])
            );
        end

        for (genvar i = DMA_S; i < DMA_E; i++) begin
            adam_syscfg_tgt #(
                `ADAM_CFG_PARAMS_MAP,

                .EN_BOOTSTRAP (0),
                .EN_BOOT_ADDR (0),
                .EN_IRQ       (1)
            ) tgt_dma (
                .seq   (seq),
                .pause (tgt_pause[i]),

                .slv (tgt_apb[i]),

                .irq_vec (irq_vec),

                .tgt_rst       (dma_rst  [i-DMA_S]),
                .tgt_pause     (dma_pause[i-DMA_S]),
                .tgt_boot_addr (),
                .tgt_irq       (dma_irq  [i-DMA_S])
            );
        end

        for (genvar i = MEM_S; i < MEM_E; i++) begin
            adam_syscfg_tgt #(
                `ADAM_CFG_PARAMS_MAP,

                .EN_BOOTSTRAP (1), // (i == MEM_S) ? EN_BOOTSTRAP_MEM0 : 0),
                .EN_BOOT_ADDR (0),
                .EN_IRQ       (0)
            ) tgt_mem (
                .seq   (seq),
                .pause (tgt_pause[i]),

                .slv (tgt_apb[i]),

                .irq_vec (irq_vec),

                .tgt_rst       (mem_rst  [i-MEM_S]),
                .tgt_pause     (mem_pause[i-MEM_S]),
                .tgt_boot_addr (),
                .tgt_irq       ()
            );
        end

        for (genvar i = LSPA_S; i < LSPA_E; i++) begin
            adam_syscfg_tgt #(
                `ADAM_CFG_PARAMS_MAP,

                .EN_BOOTSTRAP (0),
                .EN_BOOT_ADDR (0),
                .EN_IRQ       (0)
            ) tgt_lspa (
                .seq   (seq),
                .pause (tgt_pause[i]),

                .slv (tgt_apb[i]),

                .irq_vec (irq_vec),

                .tgt_rst       (lspa_rst  [i-LSPA_S]),
                .tgt_pause     (lspa_pause[i-LSPA_S]),
                .tgt_boot_addr (),
                .tgt_irq       ()
            );
        end

        for (genvar i = LSPB_S; i < LSPB_E; i++) begin
            adam_syscfg_tgt #(
                `ADAM_CFG_PARAMS_MAP,

                .EN_BOOTSTRAP (0),
                .EN_BOOT_ADDR (0),
                .EN_IRQ       (0)
            ) tgt_lspb (
                .seq   (seq),
                .pause (tgt_pause[i]),

                .slv (tgt_apb[i]),

                .irq_vec (irq_vec),

                .tgt_rst       (lspb_rst  [i-LSPB_S]),
                .tgt_pause     (lspb_pause[i-LSPB_S]),
                .tgt_boot_addr (),
                .tgt_irq       ()
            );
        end

        for (genvar i = HSP_S; i < HSP_E; i++) begin
            adam_syscfg_tgt #(
                `ADAM_CFG_PARAMS_MAP,

                .EN_BOOTSTRAP (0),
                .EN_BOOT_ADDR (0),
                .EN_IRQ       (0)
            ) tgt_hsp (
                .seq   (seq),
                .pause (tgt_pause[i]),

                .slv (tgt_apb[i]),

                .irq_vec (irq_vec),

                .tgt_rst       (hsp_rst  [i-HSP_S]),
                .tgt_pause     (hsp_pause[i-HSP_S]),
                .tgt_boot_addr (),
                .tgt_irq       ()
            );
        end

`ifdef DIFT
        // DIFT registers: +0 DTSR (taint source), +4 MPM (guard mask), +8 MPS (guard status, sticky W1C)

        localparam DIFT_S = HSP_E;
        localparam DIFT_E = DIFT_S + 1;

        for (genvar i = DIFT_S; i < DIFT_E; i++) begin
            DATA_T dift_dtsr;
            DATA_T dift_mpm;
            DATA_T dift_mps;

            // stateless block: always ack pause/resume immediately
            assign tgt_pause[i].ack = tgt_pause[i].req;

            always_ff @(posedge seq.clk) begin
                if (seq.rst) begin
                    dift_dtsr <= '0;
                    dift_mpm  <= '0;
                    dift_mps  <= '0;

                    tgt_apb[i].prdata  <= '0;
                    tgt_apb[i].pready  <= '0;
                    tgt_apb[i].pslverr <= '0;
                end
                else begin
                    // sticky: cleared only by software write of 1
                    for (int periph_idx = 0; periph_idx < NO_LSPAS; periph_idx++) begin
                        if (lspa_guard_exc[periph_idx]) begin
                            dift_mps[DIFT_LSPA_S+periph_idx] <= 1'b1;
                        end
                    end
                    for (int periph_idx = 0; periph_idx < NO_LSPBS; periph_idx++) begin
                        if (lspb_guard_exc[periph_idx]) begin
                            dift_mps[DIFT_LSPB_S+periph_idx] <= 1'b1;
                        end
                    end

                    if (tgt_apb[i].psel && !tgt_apb[i].pready) begin
                        case (tgt_apb[i].paddr[3:2])
                            2'd0: begin // DTSR
                                if (tgt_apb[i].pwrite) dift_dtsr <= tgt_apb[i].pwdata;
                                else                   tgt_apb[i].prdata <= dift_dtsr;
                            end
                            2'd1: begin // MPM
                                if (tgt_apb[i].pwrite) dift_mpm <= tgt_apb[i].pwdata;
                                else                   tgt_apb[i].prdata <= dift_mpm;
                            end
                            2'd2: begin // MPS (sticky, W1C)
                                if (tgt_apb[i].pwrite) begin
                                    for (int periph_idx = 0; periph_idx < NO_LSPAS; periph_idx++) begin
                                        if (tgt_apb[i].pwdata[DIFT_LSPA_S+periph_idx]) begin
                                            dift_mps[DIFT_LSPA_S+periph_idx] <= lspa_guard_exc[periph_idx];
                                        end
                                    end
                                    for (int periph_idx = 0; periph_idx < NO_LSPBS; periph_idx++) begin
                                        if (tgt_apb[i].pwdata[DIFT_LSPB_S+periph_idx]) begin
                                            dift_mps[DIFT_LSPB_S+periph_idx] <= lspb_guard_exc[periph_idx];
                                        end
                                    end
                                end
                                else tgt_apb[i].prdata <= dift_mps;
                            end
                            default: begin
                                tgt_apb[i].prdata <= '0;
                            end
                        endcase
                        tgt_apb[i].pready  <= '1;
                        tgt_apb[i].pslverr <= '0;
                    end
                    else begin
                        tgt_apb[i].pready <= '0;
                    end
                end
            end

            always_comb begin
                lspa_taint_en = '0;
                lspb_taint_en = '0;
                lspa_guard_en = '0;
                lspb_guard_en = '0;

                for (int periph_idx = 0; periph_idx < NO_LSPAS; periph_idx++) begin
                    lspa_taint_en[periph_idx] = dift_dtsr[DIFT_LSPA_S+periph_idx];
                    lspa_guard_en[periph_idx] = dift_mpm [DIFT_LSPA_S+periph_idx];
                end
                for (int periph_idx = 0; periph_idx < NO_LSPBS; periph_idx++) begin
                    lspb_taint_en[periph_idx] = dift_dtsr[DIFT_LSPB_S+periph_idx];
                    lspb_guard_en[periph_idx] = dift_mpm [DIFT_LSPB_S+periph_idx];
                end
            end
        end
`endif

    endgenerate

    // irq mapping ============================================================

    localparam NO_IRQ = NO_LSPAS + NO_LSPBS + NO_HSPS;

    localparam IRQ_LSPA_S = 0;
    localparam IRQ_LSPA_E = IRQ_LSPA_S + NO_LSPAS;

    localparam IRQ_LSPB_S = IRQ_LSPA_E;
    localparam IRQ_LSPB_E = IRQ_LSPB_S + NO_LSPBS;

    localparam IRQ_HSP_S = IRQ_LSPB_S;
    localparam IRQ_HSP_E = IRQ_HSP_S + NO_HSPS;

    generate
        for (genvar i = 0; i < DATA_WIDTH; i++) begin
            if (i >= IRQ_LSPA_S && i < IRQ_LSPA_E) begin
                assign irq_vec[i] = lspa_irq[i-IRQ_LSPA_S];
            end
            else if (i >= IRQ_LSPB_S && i < IRQ_LSPB_E) begin
                assign irq_vec[i] = lspb_irq[i-IRQ_LSPB_S];
            end
            else if (i >= IRQ_HSP_S && i < IRQ_HSP_E) begin
                assign irq_vec[i] = hsp_irq[i-IRQ_HSP_S];
            end
            else begin
                assign irq_vec[i] = '0;
            end
        end
    endgenerate

endmodule
