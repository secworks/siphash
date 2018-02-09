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

module tb_siphash();

  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  parameter DEBUG = 0;

  parameter CLK_HALF_PERIOD = 2;
  parameter CLK_PERIOD      = 2 * CLK_HALF_PERIOD;

  localparam ADDR_NAME0        = 8'h00;
  localparam ADDR_NAME1        = 8'h01;
  localparam ADDR_VERSION      = 8'h02;

  localparam ADDR_CTRL         = 8'h08;
  localparam CTRL_INIT_BIT     = 0;
  localparam CTRL_COMPRESS_BIT = 1;
  localparam CTRL_FINALIZE_BIT = 2;

  localparam ADDR_STATUS       = 8'h09;
  localparam STATUS_READY_BIT  = 0;
  localparam STATUS_VALID_BIT  = 1;

  localparam ADDR_CONFIG       = 8'h0a;
  localparam CONFIG_LONG_BIT   = 0;

  localparam ADDR_PARAM        = 8'h0b;
  localparam SIPHASH_START_C   = 0;
  localparam SIPHASH_SIZE_C    = 4;
  localparam SIPHASH_DEFAULT_C = 4'h2;
  localparam SIPHASH_START_D   = 3;
  localparam SIPHASH_SIZE_D    = 4;
  localparam SIPHASH_DEFAULT_D = 4'h4;

  localparam ADDR_KEY0         = 8'h10;
  localparam ADDR_KEY1         = 8'h11;
  localparam ADDR_KEY2         = 8'h12;
  localparam ADDR_KEY3         = 8'h13;

  localparam ADDR_MI0          = 8'h18;
  localparam ADDR_MI1          = 8'h19;

  localparam ADDR_WORD0        = 8'h20;
  localparam ADDR_WORD1        = 8'h21;
  localparam ADDR_WORD2        = 8'h22;
  localparam ADDR_WORD3        = 8'h23;

  localparam CORE_NAME0        = 32'h73697068; // "siph"
  localparam CORE_NAME1        = 32'h61736820; // "ash "
  localparam CORE_VERSION      = 32'h322e3030; // "2.00"


  //----------------------------------------------------------------
  // Register and Wire declarations.
  //----------------------------------------------------------------
  reg [31 : 0] cycle_ctr;
  reg [31 : 0] test_ctr;
  reg [31 : 0] error_ctr;

  reg tb_clk;
  reg tb_reset_n;

  reg           tb_cs;
  reg           tb_we;
  reg [7 : 0]   tb_addr;
  reg [31 : 0]  tb_write_data;
  wire [31 : 0] tb_read_data;
  wire          tb_error;
  reg [31 : 0]  read_data;


  //----------------------------------------------------------------
  // siphash device under test.
  //----------------------------------------------------------------
  siphash dut(
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

      if (DEBUG)
        $display("cycle = %8x:", cycle_ctr);
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
      $display("Internal top state:");
      $display("key0_reg = 0x%08x, key1_reg = 0x%08x", dut.key0_reg, dut.key1_reg);
      $display("key2_reg = 0x%08x, key3_reg = 0x%08x", dut.key2_reg, dut.key3_reg);
      $display("mi0_reg  = 0x%08x, mi1_reg  = 0x%08x", dut.mi0_reg, dut.mi1_reg);
      $display("");

      $display("Internal core state:");
      $display("key    = 0x%016x", dut.core.key);
      $display("mi     = 0x%016x", dut.core.mi);
      $display("v0_reg = 0x%016x, v1_reg = 0x%016x", dut.core.v0_reg, dut.core.v1_reg);
      $display("v2_reg = 0x%016x, v3_reg = 0x%016x", dut.core.v2_reg, dut.core.v3_reg);
      $display("sword  = 0x%016x", dut.core.siphash_word);
      $display("state  = 0x%02x, ready  = 0x%1x, valid = 0x%1x",
               dut.core.siphash_ctrl_reg, dut.core.ready, dut.core.siphash_word_valid);
      $display("");
    end
  endtask // dump_state


  //----------------------------------------------------------------
  // tb_init
  // Initialize varibles, dut inputs at start.
  //----------------------------------------------------------------
  task tb_init;
    begin
      test_ctr      = 0;
      error_ctr     = 0;
      cycle_ctr     = 0;
      tb_clk        = 0;
      tb_reset_n    = 1;
      tb_cs         = 1'b0;
      tb_we         = 1'b0;
      tb_addr       = 8'h00;
      tb_write_data = 32'h00000000;
    end
  endtask // tb_init


  //----------------------------------------------------------------
  // toggle_reset
  // Toggle the reset.
  //----------------------------------------------------------------
  task toggle_reset;
    begin
      $display("Toggling reset.");
      dump_state();
      #(2 * CLK_PERIOD);
      tb_reset_n = 0;
      #(10 * CLK_PERIOD);
      @(negedge tb_clk)
      tb_reset_n = 1;
      dump_state();
      $display("Toggling of reset done.");
    end
  endtask // toggle_reset


  //----------------------------------------------------------------
  // read_word()
  //
  // Read a data word from the given address in the DUT.
  // the word read will be available in the global variable
  // read_data.
  //----------------------------------------------------------------
  task read_word(input [7 : 0]  address);
    begin
      tb_addr = address;
      tb_cs = 1;
      tb_we = 0;
      #(CLK_PERIOD);
      read_data = tb_read_data;
      tb_cs = 0;

      if (DEBUG)
        begin
          $display("*** Reading 0x%08x from 0x%02x.", read_data, address);
          $display("");
        end
    end
  endtask // read_word


  //----------------------------------------------------------------
  // write_word()
  //
  // Write the given word to the DUT using the DUT interface.
  //----------------------------------------------------------------
  task write_word(input [7 : 0]  address,
                  input [31 : 0] word);
    begin
      if (DEBUG)
        begin
          $display("*** Writing 0x%08x to 0x%02x.", word, address);
          $display("");
        end

      tb_addr = address;
      tb_write_data = word;
      tb_cs = 1;
      tb_we = 1;
      #(CLK_PERIOD);
      tb_cs = 0;
      tb_we = 0;
    end
  endtask // write_word


  //----------------------------------------------------------------
  // wait_ready()
  //
  // Wait for ready word to be set in the DUT API.
  //----------------------------------------------------------------
  task wait_ready;
    reg ready;
    begin
      ready = 0;

      while (ready == 0)
        begin
          read_word(ADDR_STATUS);
          ready = read_data & 32'h00000001;
        end
    end
  endtask // read_word


  //----------------------------------------------------------------
  // check_name_version()
  //
  // Read the name and version from the DUT.
  //----------------------------------------------------------------
  task check_name_version;
    reg [31 : 0] name0;
    reg [31 : 0] name1;
    reg [31 : 0] version;
    begin
      inc_test_ctr();

      $display("\nTC1: Reading name and version from dut.");

      read_word(ADDR_NAME0);
      name0 = read_data;
      read_word(ADDR_NAME1);
      name1 = read_data;
      read_word(ADDR_VERSION);
      version = read_data;

      if ((name0 == CORE_NAME0) && (name1 == CORE_NAME1) && (version == CORE_VERSION))
        $display("Correct name and version read from dut.");
      else
        begin
          inc_error_ctr();
          $display("Error:");
          $display("Got name:      %c%c%c%c%c%c%c%c",
                   name0[31 : 24], name0[23 : 16], name0[15 : 8], name0[7 : 0],
                   name1[31 : 24], name1[23 : 16], name1[15 : 8], name1[7 : 0]);
          $display("Expected name: %c%c%c%c%c%c%c%c",
                   CORE_NAME0[31 : 24], CORE_NAME0[23 : 16], CORE_NAME0[15 : 8], CORE_NAME0[7 : 0],
                   CORE_NAME1[31 : 24], CORE_NAME1[23 : 16], CORE_NAME1[15 : 8], CORE_NAME1[7 : 0]);

          $display("Got version:      %c%c%c%c",
                   version[31 : 24], version[23 : 16], version[15 : 8], version[7 : 0]);
          $display("Expected version: %c%c%c%c",
                   CORE_VERSION[31 : 24], CORE_VERSION[23 : 16], CORE_VERSION[15 : 8], CORE_VERSION[7 : 0]);
        end
    end
  endtask // check_name_version


  //----------------------------------------------------------------
  // run_long_test()
  //
  // Perform testing of long hash based on the reference model.
  //----------------------------------------------------------------
  task run_long_test;
    reg [127 : 0] result;
    begin
      inc_test_ctr();
      $display("\nTC2: Testing long hash.");

      $display("Setting long hash mode..");
      write_word(ADDR_CONFIG, 32'h01);
      wait_ready();

      $display("Starting key based init.");
      write_word(ADDR_KEY0, 32'h03020100);
      write_word(ADDR_KEY1, 32'h07060504);
      write_word(ADDR_KEY2, 32'h0b0a0908);
      write_word(ADDR_KEY3, 32'h0f0e0d0c);
      write_word(ADDR_CTRL, 3'h1);
      wait_ready();

      $display("\nStarting compression of first block.");
      write_word(ADDR_MI0, 32'h03020100);
      write_word(ADDR_MI1, 32'h07060504);
      write_word(ADDR_CTRL, 3'h2);
      wait_ready();

      $display("\nStarting compression of second block.");
      write_word(ADDR_MI0, 32'h0b0a0908);
      write_word(ADDR_MI1, 32'h0f0e0d0c);
      write_word(ADDR_CTRL, 3'h2);
      wait_ready();

      $display("\nStarting finalization.");
      write_word(ADDR_CTRL, 3'h4);
      wait_ready();

      $display("\nReading out digest.");
      read_word(ADDR_WORD0);
      result[031 : 000] = read_data;
      read_word(ADDR_WORD1);
      result[063 : 032] = read_data;
      read_word(ADDR_WORD2);
      result[095 : 064] = read_data;
      read_word(ADDR_WORD3);
      result[127 : 096] = read_data;

      if (result == 128'hd9c3cf970fec087e11a8b03399e99354)
        begin
          $display("Correct hash for long test received.");
        end
      else
        begin
          inc_error_ctr();
          $display("Error: incorrect hash for long test received.");
          $display("Expected: 0x%016x", 128'hd9c3cf970fec087e11a8b03399e99354);
          $display("Recived:  0x%016x", result);
        end
    end
  endtask // run_long_test


  //----------------------------------------------------------------
  // run_paper_test_vector()
  //
  // Perform testing of short mac using the testvectors
  // from the the SipHash paper Appendix A.
  //----------------------------------------------------------------
  task run_paper_test_vector;
    reg [127 : 0] result;
    begin
      inc_test_ctr();
      $display("\nTC2: Testing with test vectors from SipHash paper.");

      $display("Starting key based init.");
      write_word(ADDR_KEY0, 32'h03020100);
      write_word(ADDR_KEY1, 32'h07060504);
      write_word(ADDR_KEY2, 32'h0b0a0908);
      write_word(ADDR_KEY3, 32'h0f0e0d0c);
      write_word(ADDR_CTRL, 3'h1);
      wait_ready();

      $display("\nStarting compression of first block.");
      write_word(ADDR_MI0, 32'h03020100);
      write_word(ADDR_MI1, 32'h07060504);
      write_word(ADDR_CTRL, 3'h2);
      wait_ready();

      $display("\nStarting compression of second block.");
      write_word(ADDR_MI0, 32'h0b0a0908);
      write_word(ADDR_MI1, 32'h0f0e0d0c);
      write_word(ADDR_CTRL, 3'h2);
      wait_ready();

      $display("\nStarting finalization.");
      write_word(ADDR_CTRL, 3'h4);
      wait_ready();

      $display("\nReading out digest.");
      read_word(ADDR_WORD0);
      result[031 : 000] = read_data;
      read_word(ADDR_WORD1);
      result[063 : 032] = read_data;
      read_word(ADDR_WORD2);
      result[095 : 064] = read_data;
      read_word(ADDR_WORD3);
      result[127 : 096] = read_data;

      if (result == 128'h0000000000000000a129ca6149be45e5)
        begin
          $display("Correct digest for SipHash paper test vector received.");
        end
      else
        begin
          inc_error_ctr();
          $display("Error: incorrect digest for SipHash paper test vector received.");
          $display("Expected: 0x%016x", 128'h0000000000000000a129ca6149be45e5);
          $display("Recived:  0x%016x", result);
        end
    end
  endtask // run_paper_test_vector


  //----------------------------------------------------------------
  // siphash_test
  // The main test functionality.
  //----------------------------------------------------------------
  initial
    begin : siphash_test
      $display("   -- Test of SipHash top level wrapper started --");

      tb_init();
      toggle_reset();
      check_name_version();
      run_paper_test_vector();
      run_long_test();

      $display("");
      $display("   -- Test of SipHash top level wrapper completed --");
      $display("Tests executed: %04d", test_ctr);
      $display("Tests failed:   %04d", error_ctr);
      $finish;
    end // siphash_test

endmodule // tb_siphash

//======================================================================
// EOF tb_siphash.v
//======================================================================
