//======================================================================
//
// siphash.v
// ---------
// Top level wrapper for the Verilog 2001 implementation of SipHash.
// This wrapper provides a 32-bit memory like interface.
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

module siphash(
               // Clock and reset.
               input wire           clk,
               input wire           reset_n,

               // Read and write interface.
               input wire           cs,
               input wire           wr_rd,
               input wire [3 : 0]   addr,
               input wire [31 : 0]  write_data,
               output wire [31 : 0] read_data,
               output wire          read_data_valid,
               output wire          error
              );


  //----------------------------------------------------------------
  // API and Symbolic names.
  //----------------------------------------------------------------
  parameter SIPHASH_ADDR_CTRL   = 4'h0;
  SIPHASH_BIT_INITIALIZE        = 0;
  SIPHASH_BIT_COMPRESS          = 1;
  SIPHASH_BIT_FINALIZE          = 2;
  SIPHASH_BIT_LONG              = 3;

  parameter SIPHASH_ADDR_STATUS = 4'h1;

  parameter SIPHASH_ADDR_PARAM  = 4'h2;

  parameter SIPHASH_ADDR_KEY0   = 4'h4;
  parameter SIPHASH_ADDR_KEY1   = 4'h5;
  parameter SIPHASH_ADDR_KEY2   = 4'h6;
  parameter SIPHASH_ADDR_KEY3   = 4'h7;

  parameter SIPHASH_ADDR_M0     = 4'h8;
  parameter SIPHASH_ADDR_M1     = 4'h9;

  parameter SIPHASH_ADDR_WORD0  = 4'hc;
  parameter SIPHASH_ADDR_WORD1  = 4'hd;
  parameter SIPHASH_ADDR_WORD2  = 4'he;
  parameter SIPHASH_ADDR_WORD3  = 4'hf;


  //----------------------------------------------------------------
  // Registers including update variables and write enable.
  //----------------------------------------------------------------
  reg [3 : 0]  ctrl_reg;
  reg [3 : 0]  ctrl_new;
  reg          ctrl_we;

  reg [7 : 0]  param_reg;
  reg [7 : 0]  param_new;
  reg          param_we;

  reg [31 : 0] key0_reg;
  reg [31 : 0] key0_new;
  reg          key0_we;

  reg [31 : 0] key1_reg;
  reg [31 : 0] key1_new;
  reg          key1_we;

  reg [31 : 0] key2_reg;
  reg [31 : 0] key2_new;
  reg          key2_we;

  reg [31 : 0] key3_reg;
  reg [31 : 0] key3_new;
  reg          key3_we;

  reg [31 : 0] mi0_reg;
  reg [31 : 0] mi0_new;
  reg          mi0_we;

  reg [31 : 0] mi1_reg;
  reg [31 : 0] mi1_new;
  reg          mi1_we;

  reg [31 : 0] word0_reg;
  reg [31 : 0] word0_new;
  reg          word0_we;

  reg [31 : 0] word1_reg;
  reg [31 : 0] word1_new;
  reg          word1_we;

  reg [31 : 0] word2_reg;
  reg [31 : 0] word2_new;
  reg          word2_we;

  reg [31 : 0] word3_reg;
  reg [31 : 0] word3_new;
  reg          word3_we;


  //----------------------------------------------------------------
  // Wires.
  //----------------------------------------------------------------
  reg read_data_out;
  reg read_data_valid_out;
  reg error_out;

  reg            core_initalize;
  reg            core_compress;
  reg            core_finalize;
  reg            core_long;
  reg [3 : 0]    core_c;
  reg [3 : 0]    core_d;
  reg [127 : 0]  core_k;
  reg [63 : 0]   core_mi;
  wire           core_ready;
  wire [127 : 0] core_siphash_word;
  wire           core_siphash_word_valid;


  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------
  assign read_data       = read_data_out;
  assign read_data_valid = read_data_valid_out;
  assign error           = error_out;



  //----------------------------------------------------------------
  // Core instance.
  //----------------------------------------------------------------
  siphash_core core(
                    .clk(clk),
                    .reset_n(reset_n),

                    .initalize(core_initalize),
                    .compress(core_compress),
                    .finalize(core_finalize),
                    .long(core_long),

                    .c(core_c),
                    .d(core_d),
                    .k(core_k),
                    .mi(core_mi),

                    .ready(core_ready),

                    .siphash_word(core_siphash_word),
                    .siphash_word_valid(core_siphash_word_valid)
                   );


  //----------------------------------------------------------------
  // reg_update
  // Update functionality for all registers in the core.
  // All registers are positive edge triggered with
  // asynchronous active low reset.
  //----------------------------------------------------------------
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        begin
          // Reset all registers to defined values.
          ctrl_reg  <= 3'b000;
          param_reg <= {SIPHASH_DEFAULT_D, SIPHASH_DEFAULT_C};
          key0_reg  <= 32'h00000000;
          key1_reg  <= 32'h00000000;
          key2_reg  <= 32'h00000000;
          key3_reg  <= 32'h00000000;
          mi0_reg   <= 32'h00000000;
          mi1_reg   <= 32'h00000000;
          word0_reg <= 32'h00000000;
          word1_reg <= 32'h00000000;
          word2_reg <= 32'h00000000;
          word3_reg <= 32'h00000000;
        end
      else
        begin
          if (ctrl_we)
            begin
              ctrl_reg <= ctrl_new;
            end

          if (param_we)
            begin
              param_reg <= param_new;
            end

          if (key0_we)
            begin
              key0_reg <= key0_new;
            end

          if (key1_we)
            begin
              key1_reg <= key1_new;
            end

          if (key2_we)
            begin
              key2_reg <= key2_new;
            end

          if (key3_we)
            begin
              key3_reg <= key3_new;
            end

          if (mi0_we)
            begin
              mi0_reg <= mi0_new;
            end

          if (mi1_we)
            begin
              mi1_reg <= mi1_new;
            end

          // We sample the siphash word when valid is set.
          if (core_siphash_word_valid)
            begin
              word0_reg <= core_siphash_word[31  :  0];
              word1_reg <= core_siphash_word[63  : 32];
              word2_reg <= core_siphash_word[95  : 64];
              word3_reg <= core_siphash_word[127 : 96];
            end
        end
    end // reg_update


  // Map core inputs and outputs to the wrapper registers.
  always @*
    begin : mapping
      core_initalize = ctrl_reg[SIPHASH_BIT_INITIALIZE];
      core_compress  = ctrl_reg[SIPHASH_BIT_COMPRESS];
      core_finalize  = ctrl_reg[SIPHASH_BIT_FINALIZE];
      core_long      = ctrl_reg[SIPHASH_BIT_LONG];

      core_c         = param_reg[(SIPHASH_START_C + SIPHASH_SIZE_C) : SIPHASH_START_C];
      core_d         = param_reg[(SIPHASH_START_D + SIPHASH_SIZE_D) : SIPHASH_START_D];
      core_k         = {key0_reg, key1_reg, key2_reg, key3_reg};
      core_mi        = {mi0_reg, mi1_reg};
    end


  //----------------------------------------------------------------
  // register update control logic.
  //----------------------------------------------------------------
  always @*
    begin : reg_ctrl
      // Default assignments
      read_data_out       = 32'h00000000;
      read_data_valid_out = 1'b0;
      error_out           = 1'b0;

      ctrl_new            = 3'b000;
      ctrl_we             = 1'b0;
      param_new           = 8'h00;
      param_we            = 1'b0;

      key0_new            = 32'h00000000;
      key0_we             = 1'b0;
      key1_new            = 32'h00000000;
      key1_we             = 1'b0;
      key2_new            = 32'h00000000;
      key2_we             = 1'b0;
      key3_new            = 32'h00000000;
      key3_we             = 1'b0;

      mi0_new             = 32'h00000000;
      mi0_we              = 1'b0;
      mi1_new             = 32'h00000000;
      mi1_we              = 1'b0;

      word0_new           = 32'h00000000;
      word0_we            = 1'b0;
      word1_new           = 32'h00000000;
      word1_we            = 1'b0;
      word2_new           = 32'h00000000;
      word2_we            = 1'b0;
      word3_new           = 32'h00000000;
      word3_we            = 1'b0;

      if (cs)
        begin
          if (wr_rd)
            begin
              // Write operation.
              case (addr)

                SIPHASH_ADDR_CTRL:
                  begin
                    ctrl_new = write_data[2 : 0];
                    ctrl_we  = 1'b1;
                  end

                SIPHASH_ADDR_PARAM:
                  begin
                    param_new = write_data[7 : 0];
                    param_we  = 1'b1;
                  end

                SIPHASH_ADDR_KEY0:
                  begin
                    key0_new = write_data;
                    key0_we  = 1'b1;
                  end

                SIPHASH_ADDR_KEY1:
                  begin
                    key1_new = write_data;
                    key1_we  = 1'b1;
                  end

                SIPHASH_ADDR_KEY2:
                  begin
                    key2_new = write_data;
                    key2_we  = 1'b1;
                  end

                SIPHASH_ADDR_KEY3:
                  begin
                    key3_new = write_data;
                    key3_we  = 1'b1;
                  end

                SIPHASH_ADDR_MI0:
                  begin
                    mi0_new = write_data;
                    mi0_we  = 1'b1;
                  end

                SIPHASH_ADDR_MI1:
                  begin
                    mi1_new = write_data;
                    mi1_we  = 1'b1;
                  end

                default:
                  begin
                    error_out = 1;
                  end
              endcase // case (addr)
            end

          else
            begin
              // Read operation.
              case (addr)
                SIPHASH_ADDR_CTRL:
                  begin
                    read_data_out       = {29'h00000000, ctrl_reg};
                    read_data_valid_out = 1'b1;
                  end

                SIPHASH_ADDR_STATUS:
                  begin
                    read_data_out       = {30'h00000000, core_ready, core_siphash_word_valid};
                    read_data_valid_out = 1'b1;
                  end

                SIPHASH_ADDR_PARAM:
                  begin
                    read_data_out       = {24'h000000, param_reg};
                    read_data_valid_out = 1'b1;
                  end

                SIPHASH_ADDR_KEY0:
                  begin
                    read_data_out       = key0_reg;
                    read_data_valid_out = 1'b1;
                  end

                SIPHASH_ADDR_KEY1:
                  begin
                    read_data_out       = key1_reg;
                    read_data_valid_out = 1'b1;
                  end

                SIPHASH_ADDR_KEY2:
                  begin
                    read_data_out       = key2_reg;
                    read_data_valid_out = 1'b1;
                  end

                SIPHASH_ADDR_KEY3:
                  begin
                    read_data_out       = key3_reg;
                    read_data_valid_out = 1'b1;
                  end

                SIPHASH_ADDR_MI0:
                  begin
                    read_data_out       = mi0_reg;
                    read_data_valid_out = 1'b1;
                  end

                SIPHASH_ADDR_MI1:
                  begin
                    read_data_out       = mi1_reg;
                    read_data_valid_out = 1'b1;
                  end

                SIPHASH_ADDR_WORD0:
                  begin
                    read_data_out       = word0_reg;
                    read_data_valid_out = 1'b1;
                  end

                SIPHASH_ADDR_WORD1:
                  begin
                    read_data_out       = word1_reg;
                    read_data_valid_out = 1'b1;
                  end

                SIPHASH_ADDR_WORD2:
                  begin
                    read_data_out       = word2_reg;
                    read_data_valid_out = 1'b1;
                  end

                SIPHASH_ADDR_WORD3:
                  begin
                    read_data_out       = wordi3_reg;
                    read_data_valid_out = 1'b1;
                  end

                default:
                  begin
                    error_out = 1;
                  end
              endcase // case (addr)
            end
        end
    end

endmodule // siphash

//======================================================================
// EOF siphash.v
//======================================================================
