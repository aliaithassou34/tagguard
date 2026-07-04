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

module adam_mem #(
    `ADAM_CFG_PARAMS,

    parameter SIZE = 4096

`ifndef SYNTHESIS
    , parameter string HEXFILE = ""
`endif
) (
    ADAM_SEQ.Slave seq,

    input  logic  req,
    input  ADDR_T addr,
    input  logic  we,
    input  STRB_T be,
    input  DATA_T wdata,
    output DATA_T rdata

`ifdef DIFT
    ,
    input  logic [STRB_WIDTH-1:0] tag_wdata,
    output logic [STRB_WIDTH-1:0] tag_rdata
`endif
);

    localparam UNALIGNED_WIDTH = $clog2(STRB_WIDTH);
    localparam ALIGNED_WIDTH   = ADDR_WIDTH - UNALIGNED_WIDTH;
    localparam ALIGNED_SIZE    = SIZE / STRB_WIDTH;

`ifdef DIFT
    // 36-bit wide RAM: 32 data + 4 tag bits (1 per byte) per word
    (* ram_style = "block" *)
    reg [DATA_WIDTH+STRB_WIDTH-1:0] mem [ALIGNED_SIZE-1:0];
`else
    (* ram_style = "block" *)
    reg [DATA_WIDTH-1:0] mem [ALIGNED_SIZE-1:0];
`endif

`ifndef SYNTHESIS
    initial begin
`ifdef DIFT
        for (int i = 0; i < ALIGNED_SIZE; i++) mem[i] = '0;
`endif
        if (HEXFILE != "") $readmemh(HEXFILE, mem);
    end
`endif

    logic [ALIGNED_WIDTH-1:0] aligned;

    assign aligned = addr[ADDR_WIDTH-1:UNALIGNED_WIDTH];

    always @(posedge seq.clk) begin
        if (we) begin
            for (int i = 0; i < STRB_WIDTH; i++) begin
                if (be[i]) begin
                    mem[aligned][i*8 +: 8] <= wdata[i*8 +: 8];
`ifdef DIFT
                    // Normal store: tag follows byte enable
                    mem[aligned][DATA_WIDTH + i] <= tag_wdata[i];
`endif
                end
            end
`ifdef DIFT
            // Tag-only write (p.spsw / p.spsh / p.spsb): we=1, be=0
            if (be == '0) begin
                for (int i = 0; i < STRB_WIDTH; i++) begin
                    if (tag_wdata[i]) begin
                        mem[aligned][DATA_WIDTH + i] <= 1'b1;
                    end
                end
            end
`endif
        end

`ifdef DIFT
        rdata <= mem[aligned][DATA_WIDTH-1:0];
        tag_rdata <= mem[aligned][DATA_WIDTH +: STRB_WIDTH];
`else
        rdata <= mem[aligned];
`endif
    end

endmodule
