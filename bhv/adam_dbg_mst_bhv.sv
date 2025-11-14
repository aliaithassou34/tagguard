`timescale 1ns/1ps
`include "adam/macros_bhv.svh"

package adam_dbg_mst_bhv;

import adam_jtag_mst_bhv::*;

class adam_dbg_mst_bhv #(
    `ADAM_BHV_CFG_PARAMS,

    parameter int W_IR   = 5,
    parameter int IDLE   = 1,
    parameter int ABITS  = 7
);

    localparam logic [W_IR-1:0] A_IDCODE = 'h01;
    localparam logic [W_IR-1:0] A_DTMCS  = 'h10;
    localparam logic [W_IR-1:0] A_DMI    = 'h11;

    localparam int W_IDCODE = 32;
    localparam int W_DTMCS  = 32;

    // {addr[ABITS-1:0], data[31:0], op[1:0]}
    localparam int W_DMI    = ABITS + 34;

    localparam logic [ABITS-1:0] A_DMCONTROL  = 'h10;
    localparam logic [ABITS-1:0] A_DMSTATUS   = 'h11;
    localparam logic [ABITS-1:0] A_SBCS       = 'h38;
    localparam logic [ABITS-1:0] A_SBADDRESS0 = 'h39;
    localparam logic [ABITS-1:0] A_SBDATA0    = 'h3C;

    typedef logic [ABITS-1:0]    dmaddr_t;
    typedef logic [31:0]         dmdata_t;

    adam_jtag_mst_bhv #(
       `ADAM_BHV_CFG_PARAMS_MAP
    ) jtag_bhv;

    typedef virtual ADAM_JTAG jtag_t;

    function new(jtag_t jtag);
        jtag_bhv = new(jtag);
    endfunction

    task dtm_init();
        logic [W_IDCODE-1:0] idcode;
        logic [W_DTMCS-1:0]  dtmcs;

        jtag_bhv.reset();
        jtag_bhv.tap_reset();

        jtag_bhv.tap_reg_read(A_IDCODE, W_IR, idcode, W_IDCODE);
        assert(idcode == DEBUG_IDCODE);

        jtag_bhv.tap_reg_read(A_DTMCS, W_IR, dtmcs, W_DTMCS);
        assert(dtmcs[9:4] == ABITS);
        assert(dtmcs[14:12] == IDLE);
    endtask

    task dm_init();
        // set dmactive
        dm_write(A_DMCONTROL, '1);
    endtask

    task dm_select(input logic [19:0] hartsel);
        dmdata_t dmcontrol;

        dm_read(A_DMCONTROL, dmcontrol);

        dmcontrol[25:6] = {hartsel[9:0], hartsel[19:10]};
        dm_write(A_DMCONTROL, dmcontrol);

        dm_read(A_DMCONTROL, dmcontrol);
        assert(dmcontrol[25:6] == {hartsel[9:0], hartsel[19:10]});
    endtask

    task dm_halt();
        dmdata_t dmcontrol, dmstatus;

        dm_read(A_DMCONTROL, dmcontrol);

        // set haltreq
        dmcontrol[31] = 1'b1;
        dm_write(A_DMCONTROL, dmcontrol);

        // wait for allhalted
        do begin
          dm_read(A_DMSTATUS, dmstatus);
        end while (!dmstatus[9]);

        // clear haltreq
        dmcontrol[31] = 1'b0;
        dm_write(A_DMCONTROL, dmcontrol);
    endtask

    task dm_resume();
        dmdata_t dmcontrol, dmstatus;

        // set resumereq
        dm_read(A_DMCONTROL, dmcontrol);
        dmcontrol[30] = 1'b1;
        dm_write(A_DMCONTROL, dmcontrol);

        // wait for allresumeack
        do begin
            dm_read(A_DMSTATUS, dmstatus);
        end while (!dmstatus[17]);

        // clear resumereq
        dmcontrol[30] = 1'b0;
        dm_write(A_DMCONTROL, dmcontrol);
    endtask

    task dm_sb_write(
        input ADDR_T addr,
        input DATA_T data
    );
        dmdata_t sbcs;

        dm_bus_wait();

        // clear sbreadonaddr
        dm_read(A_SBCS, sbcs);
        sbcs[20] = 1'b0;
        dm_write(A_SBCS, sbcs);

        // write to address0
        dm_write(A_SBADDRESS0, addr);

        // write to sbdata0
        dm_write(A_SBDATA0,    data);

        dm_bus_wait();
    endtask

    task dm_sb_read(
      input  ADDR_T addr,
      output DATA_T data
    );
        dmdata_t sbcs;

        dm_bus_wait();

        // set sbreadonaddr
        dm_read(A_SBCS, sbcs);
        sbcs[20] = 1'b1;
        dm_write(A_SBCS, sbcs);

        // write address (triggers read)
        dm_write(A_SBADDRESS0, addr);

        dm_bus_wait();

        // read data
        dm_read(A_SBDATA0, data);
    endtask

    task dm_bus_wait();
        dmdata_t sbcs;
        // poll sbbusy
        do begin
            dm_read(A_SBCS, sbcs);
        end while (sbcs[21]);
    endtask

    task dm_read(
        input  dmaddr_t addr,
        output dmdata_t data
    );
        logic [W_DMI-1:0] dmi;

        dmi[ABITS+33:34] = addr;
        dmi[33:2]        = '0;
        dmi[1:0]         = 2'd1; // op=read
        jtag_bhv.tap_reg_write(A_DMI, W_IR, dmi, W_DMI);

        repeat (IDLE-1) jtag_bhv.tap_nop();

        jtag_bhv.tap_reg_read(A_DMI, W_IR, dmi, W_DMI);
      assert(dmi[1:0] == 2'd0);
      data = dmi[33:2];
    endtask

    task dm_write(
        input dmaddr_t addr,
        input dmdata_t data
    );
        logic [W_DMI-1:0] dmi;

        // Request
        dmi[ABITS+33:34] = addr;
        dmi[33:2]        = data;
        dmi[1:0]         = 2'd2; // op=write
        jtag_bhv.tap_reg_write(A_DMI, W_IR, dmi, W_DMI);

        // Idle cycles as requested by DTMCS.idle
        repeat (IDLE-1) jtag_bhv.tap_nop();

        // Read back status (and discard data)
        jtag_bhv.tap_reg_read(A_DMI, W_IR, dmi, W_DMI);
        assert(dmi[1:0] == 2'd0);
    endtask

endclass

endpackage
