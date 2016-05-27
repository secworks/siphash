//======================================================================
//
// siphash_core.v
// --------------
// Verilog 2001 implementation of SipHash.
// This is the internal core with wide interface.
// The core implements the round function as a one cycle, full parallel
// operation. This means chained 64 bit adders.
//
// Note that the module name is siphash_core to allow usage of the
// same TB and wrapper as the default and tiny versions of the core.
//
//
// Copyright (c) 2012, Secworks Sweden AB
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or
// without modification, are permitted provided that the following
// conditions are met:
//
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in
//    the documentation and/or other materials provided with the
//    distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
// FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
// COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
// BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
// STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
// ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//======================================================================

module siphash_core(
                    // Clock and reset.
                    input wire            clk,
                    input wire            reset_n,

                    input wire            initalize,
                    input wire            compress,
                    input wire            finalize,
                    input wire            long,

                    input wire [3 : 0]    compression_rounds,
                    input wire [3 : 0]    final_rounds,
                    input wire [127 : 0]  key,
                    input wire [63 : 0]   mi,

                    output wire           ready,
                    output wire [127 : 0] siphash_word,
                    output wire           siphash_word_valid
                   );


  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  localparam DP_INIT         = 3'h0;
  localparam DP_COMP_START   = 3'h1;
  localparam DP_COMP_END     = 3'h2;
  localparam DP_FINAL0_START = 3'h3;
  localparam DP_FINAL1_START = 3'h4;
  localparam DP_SIPROUND     = 3'h5;

  localparam CTRL_IDLE         = 3'h0;
  localparam CTRL_COMP_LOOP    = 3'h1;
  localparam CTRL_COMP_END     = 3'h2;
  localparam CTRL_FINAL0_LOOP  = 3'h3;
  localparam CTRL_FINAL0_END   = 3'h4;
  localparam CTRL_FINAL1_START = 3'h5;
  localparam CTRL_FINAL1_LOOP  = 3'h6;
  localparam CTRL_FINAL1_END   = 3'h7;


  //----------------------------------------------------------------
  // Registers including update variables and write enable.
  //----------------------------------------------------------------
  reg [63 : 0] v0_reg;
  reg [63 : 0] v0_new;
  reg          v0_we;

  reg [63 : 0] v1_reg;
  reg [63 : 0] v1_new;
  reg          v1_we;

  reg [63 : 0] v2_reg;
  reg [63 : 0] v2_new;
  reg          v2_we;

  reg [63 : 0] v3_reg;
  reg [63 : 0] v3_new;
  reg          v3_we;

  reg [63 : 0] mi_reg;
  reg          mi_we;

  reg [3 : 0]  loop_ctr_reg;
  reg [3 : 0]  loop_ctr_new;
  reg          loop_ctr_we;
  reg          loop_ctr_inc;
  reg          loop_ctr_rst;

  reg          ready_reg;
  reg          ready_new;
  reg          ready_we;

  reg [63 : 0] siphash_word0_reg;
  reg [63 : 0] siphash_word1_reg;
  reg [63 : 0] siphash_word_new;
  reg          siphash_word0_we;
  reg          siphash_word1_we;

  reg          siphash_valid_reg;
  reg          siphash_valid_new;
  reg          siphash_valid_we;

  reg [2 : 0]  siphash_ctrl_reg;
  reg [2 : 0]  siphash_ctrl_new;
  reg          siphash_ctrl_we;


  //----------------------------------------------------------------
  // Wires.
  //----------------------------------------------------------------
  reg         dp_update;
  reg [2 : 0] dp_mode;


  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------
  assign ready              = ready_reg;
  assign siphash_word       = {siphash_word1_reg, siphash_word0_reg};
  assign siphash_word_valid = siphash_valid_reg;


  //----------------------------------------------------------------
  // reg_update
  // Update functionality for all registers in the core.
  // All registers are positive edge triggered with
  // asynchronous active low reset.
  //----------------------------------------------------------------
  always @ (posedge clk)
    begin
      if (!reset_n)
        begin
          // Reset all registers to defined values.
          v0_reg            <= 64'h0;
          v1_reg            <= 64'h0;
          v2_reg            <= 64'h0;
          v3_reg            <= 64'h0;
          siphash_word0_reg <= 64'h0;
          siphash_word1_reg <= 64'h0;
          mi_reg            <= 64'h0;
          ready_reg         <= 1;
          siphash_valid_reg <= 0;
          loop_ctr_reg      <= 4'h0;
          siphash_ctrl_reg  <= CTRL_IDLE;
        end
      else
        begin
          if (siphash_word0_we)
            siphash_word0_reg <= siphash_word_new;

          if (siphash_word1_we)
            siphash_word1_reg <= siphash_word_new;

          if (v0_we)
            v0_reg <= v0_new;

          if (v1_we)
            v1_reg <= v1_new;

          if (v2_we)
            v2_reg <= v2_new;

          if (v3_we)
            v3_reg <= v3_new;

          if (mi_we)
            mi_reg <= mi;

          if (ready_we)
            ready_reg <= ready_new;

          if (siphash_valid_we)
            siphash_valid_reg <= siphash_valid_new;

          if (loop_ctr_we)
            loop_ctr_reg <= loop_ctr_new;

          if (siphash_ctrl_we)
            siphash_ctrl_reg <= siphash_ctrl_new;
        end
    end // reg_update


  //----------------------------------------------------------------
  // datapath_update
  // update_logic for the internal datapath with the internal state
  // stored in the v0, v1, v2 and v3 registers.
  //
  // The datapath contains two parallel 64-bit adders with
  // operand MUXes to support reuse during processing.
  //----------------------------------------------------------------
  always @*
    begin : datapath_update
      reg [63 : 0] add_0_res;
      reg [63 : 0] add_1_res;
      reg [63 : 0] add_2_res;
      reg [63 : 0] add_3_res;
      reg [63 : 0] v0_tmp;
      reg [63 : 0] v1_tmp;
      reg [63 : 0] v2_tmp;
      reg [63 : 0] v3_tmp;

      v0_new    = 64'h0;
      v0_we     = 0;
      v1_new    = 64'h0;
      v1_we     = 0;
      v2_new    = 64'h0;
      v2_we     = 0;
      v3_new    = 64'h0;
      v3_we     = 0;

      siphash_word_new = v0_reg ^ v1_reg ^ v2_reg ^ v3_reg;

      if (dp_update)
        begin
          case (dp_mode)
            DP_INIT:
              begin
                v0_new = key[063 : 000] ^ 64'h736f6d6570736575;
                v2_new = key[063 : 000] ^ 64'h6c7967656e657261;
                v3_new = key[127 : 064] ^ 64'h7465646279746573;
                v0_we  = 1;
                v1_we  = 1;
                v2_we  = 1;
                v3_we  = 1;
                if (long)
                  v1_new = key[127 : 064] ^ 64'h646f72616e646f6d ^ 64'hee;
                else
                  v1_new = key[127 : 064] ^ 64'h646f72616e646f6d;
              end

            DP_COMP_START:
              begin
                v3_new = v3_reg ^ mi;
                v3_we = 1;
              end

            DP_COMP_END:
              begin
                v0_new = v0_reg ^ mi_reg;
                v0_we = 1;
              end

            DP_FINAL0_START:
              begin
                v2_we = 1;
                if (long)
                  v2_new = v2_reg ^ 64'hee;
                else
                  v2_new = v2_reg ^ 64'hff;
              end

            DP_FINAL1_START:
              begin
                v1_new = v1_reg ^ 64'hdd;
                v1_we  = 1;
              end

            DP_SIPROUND:
              begin
                add_0_res = v0_reg + v1_reg;
                add_1_res = v2_reg + v3_reg;

                v0_tmp = {add_0_res[31:0], add_0_res[63:32]};
                v1_tmp = {v1_reg[50:0], v1_reg[63:51]} ^ add_0_res;
                v2_tmp = add_1_res;
                v3_tmp = {v3_reg[47:0], v3_reg[63:48]} ^ add_1_res;

                add_2_res = v1_tmp + v2_tmp;
                add_3_res = v0_tmp + v3_tmp;

                v0_new = add_3_res;
                v0_we = 1;

                v1_new = {v1_tmp[46:0], v1_tmp[63:47]} ^ add_2_res;
                v1_we = 1;

                v2_new = {add_2_res[31:0], add_2_res[63:32]};
                v2_we = 1;

                v3_new = {v3_tmp[42:0], v3_tmp[63:43]} ^ add_3_res;
                v3_we = 1;
              end

            default:
              begin
              end
          endcase // case (dp_state_reg)
        end // if (dp_update)
    end // block: datapath_update


  //----------------------------------------------------------------
  // loop_ctr
  // Update logic for the loop counter, a monotonically
  // increasing counter with reset.
  //----------------------------------------------------------------
  always @*
    begin : loop_ctr
      loop_ctr_new = 0;
      loop_ctr_we  = 0;

      if (loop_ctr_rst)
        loop_ctr_we  = 1;

      if (loop_ctr_inc)
        begin
          loop_ctr_new = loop_ctr_reg + 4'h1;
          loop_ctr_we  = 1;
        end
    end // loop_ctr


  //----------------------------------------------------------------
  // siphash_ctrl_fsm
  // Logic for the state machine controlling the core behaviour.
  //----------------------------------------------------------------
  always @*
    begin : siphash_ctrl_fsm
      loop_ctr_rst      = 0;
      loop_ctr_inc      = 0;
      dp_update         = 0;
      dp_mode           = DP_INIT;
      mi_we             = 0;
      ready_new         = 0;
      ready_we          = 0;
      siphash_word0_we  = 0;
      siphash_word1_we  = 0;
      siphash_valid_new = 0;
      siphash_valid_we  = 0;
      siphash_ctrl_new  = CTRL_IDLE;
      siphash_ctrl_we   = 0;

      case (siphash_ctrl_reg)
        CTRL_IDLE:
          begin
            if (initalize)
              begin
                dp_update         = 1;
                dp_mode           = DP_INIT;
                siphash_valid_new = 0;
                siphash_valid_we  = 1;
              end

            else if (compress)
              begin
                mi_we            = 1;
                loop_ctr_rst     = 1;
                ready_new        = 0;
                ready_we         = 1;
                dp_update        = 1;
                dp_mode          = DP_COMP_START;
                siphash_ctrl_new = CTRL_COMP_LOOP;
                siphash_ctrl_we  = 1;
              end

            else if (finalize)
              begin
                loop_ctr_rst      = 1;
                ready_new         = 0;
                ready_we          = 1;
                dp_update         = 1;
                dp_mode           = DP_FINAL0_START;
                siphash_ctrl_new  = CTRL_FINAL0_LOOP;
                siphash_ctrl_we   = 1;
              end
          end

        CTRL_COMP_LOOP:
          begin
            loop_ctr_inc = 1;
            dp_update    = 1;
            dp_mode      = DP_SIPROUND;
            if (loop_ctr_reg == (compression_rounds - 1))
              begin
                siphash_ctrl_new  = CTRL_COMP_END;
                siphash_ctrl_we   = 1;
              end
          end

        CTRL_COMP_END:
          begin
            ready_new        = 1;
            ready_we         = 1;
            dp_update        = 1;
            dp_mode          = DP_COMP_END;
            siphash_ctrl_new = CTRL_IDLE;
            siphash_ctrl_we  = 1;
          end

        CTRL_FINAL0_LOOP:
          begin
            loop_ctr_inc = 1;
            dp_update    = 1;
            dp_mode      = DP_SIPROUND;
            if (loop_ctr_reg == (final_rounds - 1))
              begin
                if (long)
                  begin
                    siphash_ctrl_new  = CTRL_FINAL1_START;
                    siphash_ctrl_we   = 1;
                  end
                else
                  begin
                    siphash_ctrl_new  = CTRL_FINAL0_END;
                    siphash_ctrl_we   = 1;
                  end
              end
          end

        CTRL_FINAL0_END:
          begin
            ready_new         = 1;
            ready_we          = 1;
            siphash_word0_we  = 1;
            siphash_valid_new = 1;
            siphash_valid_we  = 1;
            siphash_ctrl_new  = CTRL_IDLE;
            siphash_ctrl_we   = 1;
          end

        CTRL_FINAL1_START:
          begin
            siphash_word0_we = 1;
            loop_ctr_rst     = 1;
            dp_update        = 1;
            dp_mode          = DP_FINAL1_START;
            siphash_ctrl_new = CTRL_FINAL1_LOOP;
            siphash_ctrl_we  = 1;
          end

        CTRL_FINAL1_LOOP:
          begin
            loop_ctr_inc = 1;
            dp_update    = 1;
            dp_mode      = DP_SIPROUND;
            if (loop_ctr_reg == (final_rounds - 1))
              begin
                siphash_ctrl_new  = CTRL_FINAL1_END;
                siphash_ctrl_we   = 1;
              end
          end

        CTRL_FINAL1_END:
          begin
            ready_new         = 1;
            ready_we          = 1;
            siphash_word1_we  = 1;
            siphash_valid_new = 1;
            siphash_valid_we  = 1;
            siphash_ctrl_new  = CTRL_IDLE;
            siphash_ctrl_we   = 1;
          end

        default:
          begin
          end
      endcase // case (siphash_ctrl_reg)
    end // siphash_ctrl_fsm
endmodule // siphash_core

//======================================================================
// EOF siphash_core.v
//======================================================================
