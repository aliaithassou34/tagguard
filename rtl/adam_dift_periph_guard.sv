/*
 * Copyright 2026 LIRMM
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

// adam_dift_periph_guard — DIFT I/O security unit.
// Engineer: Ali Ait Hassou, LIRMM.
//
// Per-slot AXI-Lite wrapper: tags peripheral read responses when taint_en_i
// is set, and squashes tainted writes when guard_en_i is set (else passthrough).

`include "adam/macros.svh"

module adam_dift_periph_guard #(
    `ADAM_CFG_PARAMS,

    parameter int unsigned NO_MSTS = 1,
    parameter ADDR_T       INC     = ADDR_T'(1024)
) (
    input logic      clk_i,
    input logic      rst_i,

    AXI_LITE.Slave  slv,
    AXI_LITE.Master mst,

    input  logic [NO_MSTS:0] taint_en_i, // from SYSCFG DTSR (per slot)
    input  logic [NO_MSTS:0] guard_en_i, // from SYSCFG MPM  (per slot)
    output logic [NO_MSTS:0] guard_exc_o // 1-cycle pulse on blocked write
);

`ifdef DIFT
    localparam int unsigned STRB_ADDR_LSB = $clog2(STRB_WIDTH);
    localparam int unsigned SLOT_ADDR_MSB = $clog2(INC) - 1;

    function automatic logic [NO_MSTS:0] periph_hit(input ADDR_T addr);
        logic [NO_MSTS:0] hit;
        ADDR_T start_addr;
        ADDR_T end_addr;

        begin
            hit = '0;
            for (int unsigned idx = 0; idx < NO_MSTS; idx++) begin
                start_addr = ADDR_T'(idx) * INC;
                end_addr   = ADDR_T'(idx + 1) * INC;
                if ((addr >= start_addr) && (addr < end_addr)) begin
                    hit[idx] = 1'b1;
                end
            end
            return hit;
        end
    endfunction

    function automatic logic data_reg_hit(input ADDR_T addr);
        return addr[SLOT_ADDR_MSB:STRB_ADDR_LSB] == '0;
    endfunction
`endif

    // AW channel ============================================================
`ifdef DIFT
    logic             write_pending_q;
    logic [NO_MSTS:0] write_hit_q;
    logic [NO_MSTS:0] aw_hit;
    logic [NO_MSTS:0] write_hit;
    logic             aw_fire;
    logic             w_fire;
    logic             w_allowed;
    logic             w_tainted;
    logic             w_blocked;

    assign aw_hit = periph_hit(slv.aw_addr);

    assign mst.aw_addr  = slv.aw_addr;
    assign mst.aw_prot  = slv.aw_prot;
    assign mst.aw_user  = slv.aw_user;
    assign mst.aw_valid = slv.aw_valid & !write_pending_q;
    assign slv.aw_ready = mst.aw_ready & !write_pending_q;

    assign aw_fire = slv.aw_valid & slv.aw_ready;
`else
    assign mst.aw_addr  = slv.aw_addr;
    assign mst.aw_prot  = slv.aw_prot;
    assign mst.aw_user  = slv.aw_user;
    assign mst.aw_valid = slv.aw_valid;
    assign slv.aw_ready = mst.aw_ready;
`endif

    // W channel — conditional strobe squash =================================
`ifdef DIFT
    assign write_hit = write_pending_q ? write_hit_q : aw_hit;
    // let a same-cycle AWVALID qualify WVALID (bridge needs both together)
    assign w_allowed = write_pending_q | slv.aw_valid;
    assign w_tainted = |slv.w_user;
    assign w_blocked = w_tainted & |(write_hit & guard_en_i);

    assign mst.w_data  = slv.w_data;
    assign mst.w_strb  = w_blocked ? '0 : slv.w_strb;
    assign mst.w_user  = slv.w_user;
    assign mst.w_valid = slv.w_valid & w_allowed;
    assign slv.w_ready = mst.w_ready & w_allowed;

    assign w_fire      = slv.w_valid & slv.w_ready;
    assign guard_exc_o = (w_fire & w_blocked) ? write_hit : '0;

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            write_pending_q <= 1'b0;
            write_hit_q     <= '0;
        end
        else begin
            if (aw_fire && !w_fire) begin
                write_pending_q <= 1'b1;
                write_hit_q     <= aw_hit;
            end
            else if (w_fire) begin
                write_pending_q <= 1'b0;
                write_hit_q     <= '0;
            end
        end
    end
`else
    assign mst.w_data  = slv.w_data;
    assign mst.w_strb  = slv.w_strb;
    assign mst.w_user  = slv.w_user;
    assign mst.w_valid = slv.w_valid;
    assign slv.w_ready = mst.w_ready;

    assign guard_exc_o = '0;
`endif

    // B channel — pass through ==============================================
    assign slv.b_resp  = mst.b_resp;
    assign slv.b_user  = mst.b_user;
    assign slv.b_valid = mst.b_valid;
    assign mst.b_ready = slv.b_ready;

    // AR channel — pass through =============================================
`ifdef DIFT
    logic             read_pending_q;
    logic             read_taint_q;
    logic [NO_MSTS:0] ar_hit;
    logic             ar_taint;
    logic             ar_fire;
    logic             r_fire;
    logic             read_taint;

    assign ar_hit   = periph_hit(slv.ar_addr);
    assign ar_taint = |(ar_hit & taint_en_i) & data_reg_hit(slv.ar_addr);

    assign mst.ar_addr  = slv.ar_addr;
    assign mst.ar_prot  = slv.ar_prot;
    assign mst.ar_user  = slv.ar_user;
    assign mst.ar_valid = slv.ar_valid & !read_pending_q;
    assign slv.ar_ready = mst.ar_ready & !read_pending_q;

    assign ar_fire = slv.ar_valid & slv.ar_ready;
`else
    assign mst.ar_addr  = slv.ar_addr;
    assign mst.ar_prot  = slv.ar_prot;
    assign mst.ar_user  = slv.ar_user;
    assign mst.ar_valid = slv.ar_valid;
    assign slv.ar_ready = mst.ar_ready;
`endif

    // R channel — taint injection ===========================================
    assign slv.r_data  = mst.r_data;
    assign slv.r_resp  = mst.r_resp;
    assign slv.r_valid = mst.r_valid;
    assign mst.r_ready = slv.r_ready;

`ifdef DIFT
    assign r_fire     = mst.r_valid & slv.r_ready;
    assign read_taint = read_pending_q ? read_taint_q : ar_taint;
    assign slv.r_user = read_taint ? '1 : mst.r_user;

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            read_pending_q <= 1'b0;
            read_taint_q   <= 1'b0;
        end
        else begin
            if (ar_fire && !r_fire) begin
                read_pending_q <= 1'b1;
                read_taint_q   <= ar_taint;
            end
            else if (r_fire) begin
                read_pending_q <= 1'b0;
                read_taint_q   <= 1'b0;
            end
        end
    end
`else
    assign slv.r_user = mst.r_user;
`endif

endmodule
