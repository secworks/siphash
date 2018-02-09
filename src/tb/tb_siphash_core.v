//======================================================================
//
// tb_siphash_core.v
// -----------------
// Testbench for the SipHash hash function core.
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

module tb_siphash_core();

  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  parameter DEBUG = 0;

  parameter CLK_HALF_PERIOD = 2;
  parameter CLK_PERIOD      = 2 * CLK_HALF_PERIOD;


  //----------------------------------------------------------------
  // Register and wire declarations.
  //----------------------------------------------------------------
  reg [31 : 0] cycle_ctr;
  reg [31 : 0] test_ctr;
  reg [31 : 0] error_ctr;

  reg            tb_clk;
  reg            tb_reset_n;
  reg            tb_initalize;
  reg            tb_compress;
  reg            tb_finalize;
  reg            tb_long;
  reg [3 : 0]    tb_c;
  reg [3 : 0]    tb_d;
  reg [127 : 0]  tb_key;
  reg [63 : 0]   tb_mi;
  wire           tb_ready;
  wire [127 : 0] tb_siphash_word;
  wire           tb_siphash_word_valid;

  reg            display_state;


  //----------------------------------------------------------------
  // siphash_core device under test.
  //----------------------------------------------------------------
  siphash_core dut(
                   .clk(tb_clk),
                   .reset_n(tb_reset_n),

                   .initalize(tb_initalize),
                   .compress(tb_compress),
                   .finalize(tb_finalize),
                   .long(tb_long),

                   .compression_rounds(tb_c),
                   .final_rounds(tb_d),
                   .key(tb_key),
                   .mi(tb_mi),

                   .ready(tb_ready),
                   .siphash_word(tb_siphash_word),
                   .siphash_word_valid(tb_siphash_word_valid)
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

      if (display_state)
        begin
          $display("cycle %08x:", cycle_ctr);
          dump_state();
        end
    end // dut_monitor


  //----------------------------------------------------------------
  // inc_test_ctr
  //----------------------------------------------------------------
  task inc_test_ctr;
    begin
      test_ctr = test_ctr +1;
    end
  endtask // inc_test_ctr


  //----------------------------------------------------------------
  // inc_error_ctr
  //----------------------------------------------------------------
  task inc_error_ctr;
    begin
      error_ctr = error_ctr +1;
    end
  endtask // inc_error_ctr


  //----------------------------------------------------------------
  // dump_inputs
  // Dump the internal SIPHASH state to std out.
  //----------------------------------------------------------------
  task dump_inputs;
    begin
      $display("Inputs:");
      $display("init = %b, compress = %b, finalize = %b",
               tb_initalize, tb_compress, tb_finalize);
      $display("reset = %b, c = %02x, d = %02x, mi = %08x",
               tb_reset_n, tb_c, tb_d, tb_mi);
      $display("");
      #(CLK_PERIOD);
    end
  endtask // dump_inputs


  //----------------------------------------------------------------
  // dump_outputs
  // Dump the outputs from the SipHash to std out.
  //----------------------------------------------------------------
  task dump_outputs;
    begin
      $display("Outputs:");
      $display("ready = %d", tb_ready);
      $display("siphash_word = 0x%032x, valid = %d",
               tb_siphash_word, tb_siphash_word_valid);
      $display("");
      #(CLK_PERIOD);
    end
  endtask // dump_inputs


  //----------------------------------------------------------------
  // dump_state
  // Dump the internal SIPHASH state to std out.
  //----------------------------------------------------------------
  task dump_state;
    begin
      $display("Internal state:");
      $display("v0_reg = %016x, v1_reg = %016x", dut.v0_reg, dut.v1_reg);
      $display("v2_reg = %016x, v3_reg = %016x", dut.v2_reg, dut.v3_reg);
      $display("mi_reg = %016x", dut.mi_reg);
      $display("siphash_word1_reg = %016x, siphash_word0_reg = %016x",
               dut.siphash_word1_reg, dut.siphash_word0_reg);
      $display("initalize = 0x%01x, compress = 0x%01x, finalize = 0x%01x, long = 0x%01x",
               dut.initalize, dut.compress, dut.finalize, dut.long);
      $display("loop_ctr = %02x, dp_update = %01x, dp_mode = %02x, fsm_state = %02x",
               dut.loop_ctr_reg, dut.dp_update, dut.dp_mode, dut.siphash_ctrl_reg);
      $display("ready = %d, valid = %d", tb_ready, tb_siphash_word_valid);
      $display("");
      #(CLK_PERIOD);
    end
  endtask // dump_state


  //----------------------------------------------------------------
  // tb_init
  // Initialize varibles, dut inputs at start.
  //----------------------------------------------------------------
  task tb_init;
    begin
      test_ctr     = 0;
      error_ctr    = 0;
      cycle_ctr    = 0;
      tb_c         = 4'h2;
      tb_d         = 4'h4;
      tb_mi        = 64'h0;
      tb_key       = 128'h0;
      tb_initalize = 0;
      tb_compress  = 0;
      tb_finalize  = 0;
      tb_long      = 0;
      cycle_ctr    = 0;
      tb_clk       = 0;
      tb_reset_n   = 0;
    end
  endtask // tb_init


  //----------------------------------------------------------------
  // run_long_test()
  //
  // Run a specific long test.
  //----------------------------------------------------------------
  task run_long_test;
    begin
      inc_test_ctr();
      tb_long =  1;
      display_state = 0;
      tb_key = 128'h0f0e0d0c0b0a09080706050403020100;
      $display("Running test with 128 bit hash output.");
      $display("Key: 0x%016x", tb_key);
      tb_initalize = 1;
      #(CLK_PERIOD);
      tb_initalize = 0;
      #(2 * CLK_PERIOD);
      $display("State after key init.");
      dump_state();

      // Add first block.
      #(CLK_PERIOD);
      $display("State before block 1.");
      dump_state();
      tb_compress = 1;
      tb_mi = 64'h0706050403020100;
      #(CLK_PERIOD);
      tb_compress = 0;
      #(10 * CLK_PERIOD);
      $display("State after block 1.");
      dump_state();

      // Wait a number of cycle and
      // try and start the next iteration.
      #(50 * CLK_PERIOD);
      display_state = 0;
      $display("State before block 2.");
      dump_state();
      #(2 * CLK_PERIOD);
      tb_compress = 1;
      tb_mi = 64'h0f0e0d0c0b0a0908;
      #(CLK_PERIOD);
      tb_compress = 0;
      #(10 * CLK_PERIOD);
      $display("State after block 2.");
      dump_state();
      #(2 * CLK_PERIOD);

      // Wait a number of cycles and
      // and pull finalizaition.
      #(4 * CLK_PERIOD);
      $display("State before finalization.");
      dump_state();
      tb_finalize = 1;
      #(CLK_PERIOD);
      tb_finalize = 0;
      #(20 * CLK_PERIOD);
      $display("State after finalization.");
      dump_state();

      if (tb_siphash_word == 128'hd9c3cf970fec087e11a8b03399e99354)
        begin
          $display("Correct result for long hash test received.");
        end
      else
        begin
          inc_error_ctr();
          $display("Error: incorrect hash for siphash long hash received.");
          $display("Expected: 0x%016x", 128'hd9c3cf970fec087e11a8b03399e99354);
          $display("Recived:  0x%016x", tb_siphash_word);
        end
    end
  endtask // run_long_test


  //----------------------------------------------------------------
  // run_old_short_test_vector()
  //
  // Perform testing of short mac using the testvectors
  // from the the SipHash paper Appendix A.
  //----------------------------------------------------------------
  task run_old_short_test_vector;
    begin
      inc_test_ctr();
      display_state = 0;
      tb_key = 128'h0f0e0d0c0b0a09080706050403020100;
      $display("Running test with vectors from the SipHash paper.");
      $display("Key: 0x%016x", tb_key);
      tb_initalize = 1;
      #(CLK_PERIOD);
      tb_initalize = 0;
      #(2 * CLK_PERIOD);
      $display("State after key init.");
      dump_state();

      // Add first block.
      #(CLK_PERIOD);
      $display("State before block 1.");
      dump_state();
      tb_compress = 1;
      tb_mi = 64'h0706050403020100;
      #(CLK_PERIOD);
      tb_compress = 0;
      #(10 * CLK_PERIOD);
      $display("State after block 1.");
      dump_state();

      // Wait a number of cycle and
      // try and start the next iteration.
      #(50 * CLK_PERIOD);
      display_state = 0;
      $display("State before block 2.");
      dump_state();
      #(2 * CLK_PERIOD);
      tb_compress = 1;
      tb_mi = 64'h0f0e0d0c0b0a0908;
      #(CLK_PERIOD);
      tb_compress = 0;
      #(10 * CLK_PERIOD);
      $display("State after block 2.");
      dump_state();
      #(2 * CLK_PERIOD);

      // Wait a number of cycles and
      // and pull finalizaition.
      #(4 * CLK_PERIOD);
      $display("State before finalization.");
      dump_state();
      tb_finalize = 1;
      #(CLK_PERIOD);
      tb_finalize = 0;
      #(20 * CLK_PERIOD);
      $display("State after finalization.");
      dump_state();

      if (tb_siphash_word == 64'ha129ca6149be45e5)
        begin
          $display("Correct digest for siphash paper test vector received.");
        end
      else
        begin
          inc_error_ctr();
          $display("Error: incorrect digest for siphash paper test vector received.");
          $display("Expected: 0x%016x", 64'ha129ca6149be45e5);
          $display("Recived:  0x%016x", tb_siphash_word);
        end
    end
  endtask // run_old_short_test_vector


  //----------------------------------------------------------------
  // siphash_core_test
  // The main test functionality.
  //----------------------------------------------------------------
  initial
    begin : siphash_core_test
      $display("   -- Test of siphash core started --");
      tb_init();

      dump_state();
      display_state = 0;

      #(10 * CLK_PERIOD);
      @(negedge tb_clk)
      tb_reset_n = 1;
      dump_state();

      #(2 * CLK_PERIOD);
      dump_state();
      dump_outputs();

      run_old_short_test_vector();
      run_long_test();

      #(100 * CLK_PERIOD);
      $display("Processing done..");
      dump_state();
      dump_outputs();

      $display("");
      $display("   -- Test of siphash core completed --");
      $display("Tests executed: %04d", test_ctr);
      $display("Tests failed:   %04d", error_ctr);
      $finish;
    end // siphash_core_test

endmodule // tb_siphash_core

//======================================================================
// EOF tb_siphash_core.v
//======================================================================
