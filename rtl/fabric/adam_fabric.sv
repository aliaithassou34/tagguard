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
`include "axi/assign.svh"

module adam_fabric #(
    `ADAM_CFG_PARAMS
) (
    // lsdom ==================================================================
    
    ADAM_SEQ.Slave   lsdom_seq,
    ADAM_PAUSE.Slave lsdom_pause,
    ADAM_PAUSE.Slave lsdom_pause_lspa,
    ADAM_PAUSE.Slave lsdom_pause_lspb,

    AXI_LITE.Slave lsdom_lpcpu [2],

    AXI_LITE.Master lsdom_lpmem,
    AXI_LITE.Master lsdom_syscfg,
    APB.Master      lsdom_lspa [NO_LSPAS+1],
    APB.Master      lsdom_lspb [NO_LSPBS+1],

    input logic [NO_LSPAS:0] lspa_taint_en,
    input logic [NO_LSPBS:0] lspb_taint_en,
    input logic [NO_LSPAS:0] lspa_guard_en,
    input logic [NO_LSPBS:0] lspb_guard_en,
    output logic [NO_LSPAS:0] lspa_guard_exc,
    output logic [NO_LSPBS:0] lspb_guard_exc,

    // hsdom ==================================================================
    
    ADAM_SEQ.Slave   hsdom_seq,
    ADAM_PAUSE.Slave hsdom_pause,

    AXI_LITE.Slave hsdom_cpu [2*NO_CPUS+1],
    AXI_LITE.Slave hsdom_dma [NO_DMAS+1],
    AXI_LITE.Slave hsdom_debug_slv,

    AXI_LITE.Master hsdom_mem [NO_MEMS+1],
    AXI_LITE.Master hsdom_hsp [NO_HSPS+1],
    AXI_LITE.Master hsdom_debug_mst
);

    // lsdom ==================================================================

    `ADAM_AXIL_I lsdom_from_hsdom ();
    `ADAM_AXIL_I lsdom_to_hsdom ();

    `ADAM_AXIL_I lsdom_to_lspa ();
    `ADAM_AXIL_I lsdom_to_lspb ();

    `ADAM_AXIL_I lspa_tainted ();
    `ADAM_AXIL_I lspb_tainted ();

    adam_fabric_lsdom #(
        `ADAM_CFG_PARAMS_MAP
    ) adam_fabric_lsdom (
        .seq   (lsdom_seq),
        .pause (lsdom_pause),

        .lpcpu      (lsdom_lpcpu),
        .from_hsdom (lsdom_from_hsdom),

        .lpmem    (lsdom_lpmem),
        .syscfg   (lsdom_syscfg),
        .lspa     (lsdom_to_lspa),
        .lspb     (lsdom_to_lspb),
        .to_hsdom (lsdom_to_hsdom)
    );

    generate
        if (EN_LSPA) begin
            adam_dift_periph_guard #(
                `ADAM_CFG_PARAMS_MAP,

                .NO_MSTS (NO_LSPAS),
                .INC     (MMAP_LSPA.inc)
            ) adam_dift_periph_guard_lspa (
                .clk_i (lsdom_seq.clk),
                .rst_i (lsdom_seq.rst),

                .slv         (lsdom_to_lspa),
                .mst         (lspa_tainted),
                .taint_en_i  (lspa_taint_en),
                .guard_en_i  (lspa_guard_en),
                .guard_exc_o (lspa_guard_exc)
            );

            adam_fabric_lspx #(
                `ADAM_CFG_PARAMS_MAP,

                .NO_MSTS (NO_LSPAS),
                .INC     (MMAP_LSPA.inc)
            ) adam_fabric_lspa (
                .seq   (lsdom_seq),
                .pause (lsdom_pause_lspa),

                .slv (lspa_tainted),
                .mst (lsdom_lspa)
            );
        end
        else begin
            `ADAM_PAUSE_SLV_TIE_OFF(lsdom_pause_lspa);
            `ADAM_AXIL_SLV_TIE_OFF(lsdom_to_lspa);
            `ADAM_AXIL_SLV_TIE_OFF(lspa_tainted);
            assign lspa_guard_exc = '0;
        end

        if (EN_LSPB) begin
            adam_dift_periph_guard #(
                `ADAM_CFG_PARAMS_MAP,

                .NO_MSTS (NO_LSPBS),
                .INC     (MMAP_LSPB.inc)
            ) adam_dift_periph_guard_lspb (
                .clk_i (lsdom_seq.clk),
                .rst_i (lsdom_seq.rst),

                .slv         (lsdom_to_lspb),
                .mst         (lspb_tainted),
                .taint_en_i  (lspb_taint_en),
                .guard_en_i  (lspb_guard_en),
                .guard_exc_o (lspb_guard_exc)
            );

            adam_fabric_lspx #(
                `ADAM_CFG_PARAMS_MAP,

                .NO_MSTS (NO_LSPBS),
                .INC     (MMAP_LSPB.inc)
            ) adam_fabric_lspb (
                .seq   (lsdom_seq),
                .pause (lsdom_pause_lspb),

                .slv (lspb_tainted),
                .mst (lsdom_lspb)
            );
        end
        else begin
            `ADAM_PAUSE_SLV_TIE_OFF(lsdom_pause_lspb);
            `ADAM_AXIL_SLV_TIE_OFF(lsdom_to_lspb);
            `ADAM_AXIL_SLV_TIE_OFF(lspb_tainted);
            assign lspb_guard_exc = '0;
        end
    endgenerate

    // hsdom ==================================================================

    `ADAM_AXIL_I hsdom_from_lsdom ();
    `ADAM_AXIL_I hsdom_to_lsdom ();

    adam_fabric_hsdom #(
        `ADAM_CFG_PARAMS_MAP
    ) adam_fabric_hsdom (
        .seq   (hsdom_seq),
        .pause (hsdom_pause),

        .cpu        (hsdom_cpu),
        .dma        (hsdom_dma),
        .debug_slv  (hsdom_debug_slv),
        .from_lsdom (hsdom_from_lsdom),

        .mem       (hsdom_mem),
        .hsp       (hsdom_hsp),
        .debug_mst (hsdom_debug_mst),
        .to_lsdom  (hsdom_to_lsdom)
    );

    // cdc (placeholder) ======================================================

    axi_lite_cut_intf #(
        .BYPASS     (0),
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH),
        .USER_WIDTH (`ADAM_DIFT_AXI_USER_W)
    ) cut_hsdom_to_lsdom (
        .clk_i  (lsdom_seq.clk),
        .rst_ni (!lsdom_seq.rst),
        .in     (hsdom_to_lsdom),
        .out    (lsdom_from_hsdom)
    );

    axi_lite_cut_intf #(
        .BYPASS     (0),
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH),
        .USER_WIDTH (`ADAM_DIFT_AXI_USER_W)
    ) cut_lsdom_to_hsdom (
        .clk_i  (lsdom_seq.clk),
        .rst_ni (!lsdom_seq.rst),
        .in     (lsdom_to_hsdom),
        .out    (hsdom_from_lsdom)
    );

endmodule
