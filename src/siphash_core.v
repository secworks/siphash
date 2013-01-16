//======================================================================
//
// siphash_core.v
// ---------------
// Verilog 2001 implementation of SipHash.
// This is the core with wide interface.
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
                    input wire           clk,
                    input wire           reset_n,
                
                    // Control
                    input wire           initalize,
                    input wire           compress,
                    input wire           finalize,

                    // Number of compression rounds c.
                    // Number of finalization rounds d.
                    // Key k.
                    // Message word block mi.
                    input wire [3 : 0]   c,
                    input wire [3 : 0]   d,
                    input wire [127 : 0] k,
                    input wire [63 : 0]  mi,

                    // Status output.
                    output wire          ready,
                    
                    // Hash word output.
                    output wire [63 : 0] siphash_word,
                    output wire          siphash_word_valid
                   );

  
  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  // Datapath control states names.
  parameter DP_INITIALIZAION     = 3'h0;
  parameter DP_COMPRESSION_START = 3'h1;
  parameter DP_COMPRESSION_END   = 3'h2;
  parameter DP_FINALIZATION      = 3'h3;
  parameter DP_SIPROUND_0        = 3'h4;
  parameter DP_SIPROUND_1        = 3'h5;

  // State names for the control FSM.
  parameter CTRL_IDLE    = 3'h0;
  parameter CTRL_COMP_0  = 3'h1;
  parameter CTRL_COMP_1  = 3'h2;
  parameter CTRL_COMP_2  = 3'h3;
  parameter CTRL_FINAL_0 = 3'h4;
  parameter CTRL_FINAL_1 = 3'h5;

  
  //----------------------------------------------------------------
  // Registers including update variables
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

  reg [3 : 0] loop_ctr_reg;
  reg [3 : 0] loop_ctr_new;
  reg         loop_ctr_we;
  reg         loop_ctr_inc;
  reg         loop_ctr_rst;

  reg ready_reg;
  reg ready_new;
  reg ready_we;
  
  reg siphash_valid_reg;
  reg siphash_valid_new;
  reg siphash_valid_we;

  reg [2 : 0] dp_state_reg;
  reg [2 : 0] dp_state_new;
  reg         dp_state_we;

  reg [2 : 0] siphash_ctrl_reg;
  reg [2 : 0] siphash_ctrl_new;
  reg         siphash_ctrl_we;
  
  
  //----------------------------------------------------------------
  // Wires.
  //----------------------------------------------------------------
  reg          dp_update;

  
  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------
  assign ready              = ready_reg;
  assign siphash_word       = v0_reg ^ v1_reg ^ v2_reg ^ v3_reg;
  assign siphash_word_valid = siphash_valid_reg;
  
  
  //----------------------------------------------------------------
  // reg_update
  // This block contains all the register updates in the core.
  // All registers are positive edge triggered with synchronous
  // active low reset.
  //----------------------------------------------------------------
  always @ (posedge clk)
    begin
      if (!reset_n)
        begin
          // Reset all registers to defined values.
          v0_reg            <= 64'h0000000000000000;
          v1_reg            <= 64'h0000000000000000;
          v2_reg            <= 64'h0000000000000000;
          v3_reg            <= 64'h0000000000000000;
          mi_reg            <= 64'h0000000000000000;
          ready_reg         <= 1;
          siphash_valid_reg <= 0;
          loop_ctr_reg      <= 4'h0;
          dp_state_reg      <= DP_INITIALIZAION;
          siphash_ctrl_reg  <= CTRL_IDLE;
        end
      else
        begin
          if (v0_we)
            begin
              v0_reg <= v0_new;
            end
          
          if (v1_we)
            begin
              v1_reg <= v1_new;
            end

          if (v2_we)
            begin
              v2_reg <= v2_new;
            end
 
          if (v3_we)
            begin
              v3_reg <= v3_new;
            end
 
          if (mi_we)
            begin
              mi_reg <= mi;
            end

          if (ready_we)
            begin
              ready_reg <= ready_new;
            end

          if (siphash_valid_we)
            begin
              siphash_valid_reg <= siphash_valid_new;
            end
          
          if (loop_ctr_we)
            begin
              loop_ctr_reg <= loop_ctr_new;
            end
          
          if (dp_state_we)
            begin
              dp_state_reg <= dp_state_new;
            end
          
          if (siphash_ctrl_we)
            begin
              siphash_ctrl_reg <= siphash_ctrl_new;
            end
        end
    end // reg_update


  //----------------------------------------------------------------
  // datapath_update
  // update_logic for the internal datapath with internal state 
  // stored in the v0, v1, v2 and v3 registers.
  //
  // This datapath contains two parallel 64-bit adders with 
  // operand MUXes to support reuse during processing.
  //----------------------------------------------------------------
  always @*
    begin : datapath_update
      // Internal wires
      reg [63 : 0] add_a_op0;
      reg [63 : 0] add_a_op1;
      reg [63 : 0] add_a_res;
      
      reg [63 : 0] add_b_op0;
      reg [63 : 0] add_b_op1;
      reg [63 : 0] add_b_res;
      
      // Default assignments
      add_a_op0 = v0_reg;
      add_b_op0 = v2_reg;
      v0_new    = 64'h0000000000000000;
      v0_we     = 0;
      v1_new    = 64'h0000000000000000;
      v1_we     = 0;
      v2_new    = 64'h0000000000000000;
      v2_we     = 0;
      v3_new    = 64'h0000000000000000;
      v3_we     = 0;

      // Operand MUXes for the adders.
      case (dp_state_reg)
        DP_SIPROUND_0:
          begin
            add_a_op1 = v1_reg;
            add_b_op1 = v3_reg;
          end
        
        DP_SIPROUND_1:
          begin
            add_a_op1 = v3_reg;
            add_b_op1 = v1_reg;
          end
        
        default:
          begin
            add_a_op1    = 64'h0000000000000000;
            add_b_op1    = 64'h0000000000000000;
          end
      endcase // case (dp_state_reg)

      // The 64 bit adders
      add_a_res = add_a_op0 + add_a_op1;
      add_b_res = add_b_op0 + add_b_op1;
      
      // Main DP logic.
      if (dp_update)
        begin
          case (dp_state_reg)
            DP_INITIALIZAION:
              begin
                v0_new = k[63 : 0] ^ 64'h736f6d6570736575;
                v0_we = 1;
                v1_new = k[127 : 64] ^ 64'h646f72616e646f6d;
                v1_we = 1;
                v2_new = k[63 : 0] ^ 64'h6c7967656e657261;
                v2_we = 1;
                v3_new = k[127 : 64] ^ 64'h7465646279746573;
                v3_we = 1;
              end

            DP_COMPRESSION_START:
              begin
                v3_new = v3_reg ^ mi_reg;
                v3_we = 1;
              end

            DP_COMPRESSION_END:
              begin
                v0_new = v0_reg ^ mi_reg;
                v0_we = 1;
              end

            DP_FINALIZATION:
              begin
                v2_new = {{v2_reg[63:8]}, {v2_reg[7:0] ^ 8'hff}};
                v2_we = 1;
              end
            
            DP_SIPROUND_0:
              begin
                v0_new = {add_a_res[31:0], add_a_res[63:32]};
                v0_we = 1;

                v1_new = {v1_reg[50:0], v1_reg[63:51]} ^ add_a_res;
                v1_we = 1;
                
                v2_new = add_b_res;
                v2_we = 1;
                
                v3_new = {v3_reg[47:0], v3_reg[63:48]} ^ v2_new;
                v3_we = 1;
              end

            DP_SIPROUND_1:
              begin
                v0_new = add_a_res;
                v0_we = 1;

                v1_new = {v1_reg[46:0], v1_reg[63:47]} ^ add_b_res;
                v1_we = 1;

                v2_new = {add_b_res[31:0], add_b_res[63:32]};
                v2_we = 1;

                v3_new = {v3_reg[42:0], v3_reg[63:43]} ^ add_a_res;
                v3_we = 1;
              end
            
          endcase // case (dp_state_reg)
        end // if (dp_update)
    end // block: datapath_update
  
  
  //----------------------------------------------------------------
  // loop_ctr
  // Update logic for the loop counter.
  // A simple monotonically increasing counter.
  //----------------------------------------------------------------
  always @*
    begin : loop_ctr
      // Defult assignments
      loop_ctr_new = 0;
      loop_ctr_we  = 0;
      
      if (loop_ctr_rst)
        begin
          loop_ctr_new = 0;
          loop_ctr_we  = 1;
        end

      if (loop_ctr_inc)
        begin
          loop_ctr_new = loop_ctr_reg + 4'h01;
          loop_ctr_we  = 1;
        end
    end // loop_ctr
  
  
  //----------------------------------------------------------------
  // siphash_ctrl_fsm
  // Logic for the state machine controlling the core behaviour.
  //----------------------------------------------------------------
  always @*
    begin : siphash_ctrl_fsm
      // Default assignments.
      loop_ctr_rst      = 0;
      loop_ctr_inc      = 0;
      dp_update         = 0;
      dp_state_new      = DP_INITIALIZAION;
      dp_state_we       = 0;
      mi_we             = 0;
      ready_new         = 0;
      ready_we          = 0;
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
                dp_state_new      = DP_INITIALIZAION;
                dp_state_we       = 1;
                siphash_valid_new = 0;
                siphash_valid_we  = 1;
              end
            
            else if (compress)
              begin
                mi_we             = 1;
                loop_ctr_rst      = 1;
                ready_new         = 0;
                ready_we          = 1;
                siphash_valid_new = 0;
                siphash_valid_we  = 1;
                dp_update         = 1;
                dp_state_new      = DP_COMPRESSION_START;
                dp_state_we       = 1;
                siphash_ctrl_new  = CTRL_COMP_0;
                siphash_ctrl_we   = 1;
              end

            else if (finalize)
              begin
                loop_ctr_rst      = 1;
                ready_new         = 0;
                ready_we          = 1;
                siphash_valid_new = 0;
                siphash_valid_we  = 1;
                dp_update         = 1;
                dp_state_new      = DP_FINALIZATION;
                dp_state_we       = 1;
                siphash_ctrl_new  = CTRL_FINAL_0;
                siphash_ctrl_we   = 1;
              end
          end

        CTRL_COMP_0:
          begin
            dp_update        = 1;
            dp_state_new     = DP_SIPROUND_0;
            dp_state_we      = 1;
            siphash_ctrl_new = CTRL_COMP_1;
            siphash_ctrl_we  = 1;
          end

        CTRL_COMP_1:
          begin
            if (dp_state_reg == DP_SIPROUND_1)
              begin
                if (loop_ctr_reg == (c - 1))
                  begin
                    siphash_ctrl_new  = CTRL_COMP_2;
                    siphash_ctrl_we   = 1;
                  end
                else
                  begin
                    loop_ctr_inc = 1;
                    dp_update    = 1;
                    dp_state_new = DP_SIPROUND_0;
                    dp_state_we  = 1;
                  end
              end
            else
              begin
                dp_update    = 1;
                dp_state_new = dp_state_reg + 3'b01;
                dp_state_we  = 1;
              end
          end

        CTRL_COMP_2:
          begin
            ready_new        = 1;
            ready_we         = 1;
            dp_update        = 1;
            dp_state_new     = DP_COMPRESSION_END;
            dp_state_we      = 1;
            siphash_ctrl_new = CTRL_IDLE;
            siphash_ctrl_we  = 1;
          end
        
        CTRL_FINAL_0:
          begin
            dp_update         = 1;
            dp_state_new      = DP_SIPROUND_0;
            dp_state_we       = 1;
            siphash_ctrl_new  = CTRL_FINAL_1;
            siphash_ctrl_we   = 1;
          end

        CTRL_FINAL_1:
          begin
            if (dp_state_reg == DP_SIPROUND_1)              
              begin
                if (loop_ctr_reg == (d - 1))
                  begin
                    // Done.
                    ready_new         = 1;
                    ready_we          = 1;
                    dp_update         = 1;
                    siphash_valid_new = 1;
                    siphash_valid_we  = 1;
                    siphash_ctrl_new  = CTRL_IDLE;
                    siphash_ctrl_we   = 1;
                  end
                else
                  begin
                    loop_ctr_inc = 1;
                    dp_update    = 1;
                    dp_state_new = DP_SIPROUND_0;
                    dp_state_we  = 1;
                  end
              end
            else
              begin
                dp_update    = 1;
                dp_state_new = dp_state_reg + 3'b001;
                dp_state_we  = 1;
              end
          end
      endcase // case (siphash_ctrl_reg)
    end // siphash_ctrl_fsm

endmodule // siphash_core

//======================================================================
// EOF siphash_core.v
//======================================================================
