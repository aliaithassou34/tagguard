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

module adam_axil_to_mem #(
    `ADAM_CFG_PARAMS,

    parameter MAX_TRANS = FAB_MAX_TRANS
) (
    ADAM_SEQ.Slave   seq,
    ADAM_PAUSE.Slave pause,

    AXI_LITE.Slave axil,

    output logic  mem_req,
    output ADDR_T mem_addr,
    output logic  mem_we,
    output STRB_T mem_be,
    output DATA_T mem_wdata,
    input  DATA_T mem_rdata

`ifdef DIFT
    ,
    output logic [STRB_WIDTH-1:0] mem_tag_wdata,
    input  logic [STRB_WIDTH-1:0] mem_tag_rdata
`endif
);

    logic  obi_req;
    logic  obi_gnt;
    logic  obi_rvalid;
    logic  obi_rready;
    DATA_T obi_rdata;

`ifdef DIFT
    logic [STRB_WIDTH-1:0] obi_tag_wdata;
    logic [STRB_WIDTH-1:0] obi_tag_rdata;
    logic [STRB_WIDTH-1:0] buf_tag_rdata;
`endif
    
    logic  buf_write;
    DATA_T buf_rdata;
    
    adam_obi_from_axil #(
        `ADAM_CFG_PARAMS_MAP,

        .MAX_TRANS (FAB_MAX_TRANS)
    ) adam_obi_from_axil (
        .seq   (seq),
        .pause (pause),

        .axil (axil),

        .req    (obi_req),
        .gnt    (obi_gnt),
        .addr   (mem_addr),
        .we     (mem_we),
        .be     (mem_be),
        .wdata  (mem_wdata),
        .rvalid (obi_rvalid),
        .rready (obi_rready),
        .rdata  (obi_rdata)

`ifdef DIFT
        ,
        .tag_wdata (obi_tag_wdata),
        .tag_rdata (obi_tag_rdata)
`endif
    );

    assign mem_req = obi_req && obi_gnt;
    assign obi_gnt = !obi_rvalid;
    assign obi_rdata = (buf_write) ? mem_rdata : buf_rdata;

`ifdef DIFT
    assign mem_tag_wdata = obi_tag_wdata;
    assign obi_tag_rdata = (buf_write) ? mem_tag_rdata : buf_tag_rdata;
`endif

    always_ff @(posedge seq.clk) begin
        if (seq.rst) begin
            obi_rvalid <= 0;
        end
        else begin
            if (obi_rvalid && obi_rready) begin
                obi_rvalid <= 0; 
            end

            if (obi_req && obi_gnt) begin
                obi_rvalid <= 1;
            end
        end
    end

    always @(posedge seq.clk) begin
        if (seq.rst) begin
            buf_write    <= '0;
            buf_rdata    <= '0;
`ifdef DIFT
            buf_tag_rdata <= '0;
`endif
        end
        else begin
            if (buf_write) begin
                buf_rdata     <= mem_rdata;
`ifdef DIFT
                buf_tag_rdata <= mem_tag_rdata;
`endif
            end
            buf_write <= mem_req;
        end
    end

endmodule