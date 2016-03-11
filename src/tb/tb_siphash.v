//======================================================================
//
// tb_siphash.v
// ------------
// Testbench for the SipHash core wrapper.
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

//------------------------------------------------------------------
// Compiler directives.
//------------------------------------------------------------------
`timescale 1ns/10ps

module tb_siphash();

  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  parameter CLK_HALF_PERIOD = 2;
  parameter CLK_PERIOD      = 2 * CLK_HALF_PERIOD;


  //----------------------------------------------------------------
  // Register and Wire declarations.
  //----------------------------------------------------------------
  // Cycle counter.
  reg [31 : 0] cycle_ctr;

  // Clock and reset.
  reg tb_clk;
  reg tb_reset_n;

  // DUT connections.
  reg           tb_cs;
  reg           tb_we;
  reg [7 : 0]   tb_addr;
  reg [31 : 0]  tb_write_data;
  wire [31 : 0] tb_read_data;


  //----------------------------------------------------------------
  // siphash device under test.
  //----------------------------------------------------------------
  siphash dut(
              // Clock and reset.
              .clk(tb_clk),
              .reset_n(tb_reset_n),

              .cs(tb_cs),
              .we(tb_we),
              .addr(tb_addr),
              .write_data(tb_write_data),
              .read_data(tb_read_data)
             );


  //----------------------------------------------------------------
  // clk_gen
  // Clock generator process.
  //----------------------------------------------------------------
  always
    begin : clk_gen
      #CLK_HALF_PERIOD tb_clk = !tb_clk;
    end // clk_gen


  //--------------------------------------------------------------------
  // dut_monitor
  // Monitor for observing the inputs and outputs to the dut.
  // Includes the cycle counter.
  //--------------------------------------------------------------------
  always @ (posedge tb_clk)
    begin : dut_monitor
      cycle_ctr = cycle_ctr + 1;

      $display("cycle = %8x:", cycle_ctr);
    end // dut_monitor


  //----------------------------------------------------------------
  // dump_inputs
  // Dump the internal SIPHASH state to std out.
  //----------------------------------------------------------------
  task dump_inputs;
    begin
      $display("Inputs:");
      $display("");
    end
  endtask // dump_inputs


  //----------------------------------------------------------------
  // dump_outputs
  // Dump the outputs from the SipHash to std out.
  //----------------------------------------------------------------
  task dump_outputs;
    begin
      $display("Outputs:");
      $display("");
    end
  endtask // dump_inputs


  //----------------------------------------------------------------
  // dump_state
  // Dump the internal SIPHASH state to std out.
  //----------------------------------------------------------------
  task dump_state;
    begin
      $display("Internal state:");
      $display("");
    end
  endtask // dump_state


  //----------------------------------------------------------------
  // run_old_short_test_vector()
  //
  // Perform testing of short mac using the testvectors
  // from the the SipHash paper Appendix A.
  //----------------------------------------------------------------
  task run_old_short_test_vector;
    begin
      #(10 * CLK_PERIOD);
      // tb_key = 128'h0f0e0d0c0b0a09080706050403020100;
      // tb_initalize = 1;
      #(CLK_PERIOD);
      // tb_initalize = 0;
      dump_outputs();

      // Add first block.
      #(CLK_PERIOD);
      // tb_compress = 1;
      // tb_mi = 64'h0706050403020100;
      #(CLK_PERIOD);
      // tb_compress = 0;
      dump_state();
      dump_outputs();

      // Wait a number of cycle and
      // try and start the next iteration.
      #(50 * CLK_PERIOD);
      dump_outputs();
      // tb_compress = 1;
      // tb_mi = 64'h0f0e0d0c0b0a0908;
      #(CLK_PERIOD);
      // tb_compress = 0;
      dump_state();
      dump_outputs();

      // Wait a number of cycles and
      // and pull finalizaition.
      #(50 * CLK_PERIOD);
      dump_outputs();
      // tb_finalize = 1;
      #(CLK_PERIOD);
      // tb_finalize = 0;
      dump_state();
      dump_outputs();

//      if (tb_siphash_word == 64'ha129ca6149be45e5)
//        begin
//          $display("Correct digest for old old short test vector received.");
//        end
//      else
//        begin
//          $display("Error: incorrect digest for old old short test vector received.");
//          $display("Expected: 0x%016x", 64'ha129ca6149be45e5);
//          $display("Recived:  0x%016x", tb_siphash_word);
//        end
    end
  endtask // run_old_short_test_vector


  //----------------------------------------------------------------
  // siphash_test
  // The main test functionality.
  //----------------------------------------------------------------
  initial
    begin : siphash_test
      $display("   -- Testbench for siphash wrapper started --");

      // Set clock, reset and DUT input signals to
      // defined values at simulation start.
      tb_cs         = 1'b0;
      tb_we         = 1'b0;
      tb_addr       = 8'h00;
      tb_write_data = 32'h00000000;

      cycle_ctr    = 0;
      tb_clk       = 0;
      tb_reset_n   = 0;
      // dump_state();

      // Wait ten clock cycles and release reset.
      #(10 * CLK_PERIOD);
      @(negedge tb_clk)
      tb_reset_n = 1;
      // dump_state();

      // Wait some cycles.
      #(100 * CLK_PERIOD);
      $display("Processing done..");
      // dump_state();
      // dump_outputs();

      // Finish in style.
      $display("siphash simulation done.");
      $finish;
    end // siphash_test

endmodule // tb_siphash

//======================================================================
// EOF tb_siphash.v
//======================================================================
