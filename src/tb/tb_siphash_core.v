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

//------------------------------------------------------------------
// Compiler directives.
//------------------------------------------------------------------
`timescale 1ns/100ps

module tb_siphash_core();

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


  //----------------------------------------------------------------
  // siphash_core device under test.
  //----------------------------------------------------------------
  siphash_core dut(
                   // Clock and reset.
                   .clk(tb_clk),
                   .reset_n(tb_reset_n),

                   // Control
                   .initalize(tb_initalize),
                   .compress(tb_compress),
                   .finalize(tb_finalize),
                   .long(tb_long),

                   .c(tb_c),
                   .d(tb_d),
                   .k(tb_key),
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

      $display("cycle = %8x:", cycle_ctr);
      // $display("v0_reg = %016x, v1_reg = %016x", dut.v0_reg, dut.v1_reg);
      // $display("v2_reg = %016x, v3_reg = %016x", dut.v2_reg, dut.v3_reg);
      // $display("loop_ctr = %02x, dp_state = %02x, fsm_state = %02x",
      // dut.loop_ctr_reg, dut.dp_state_reg, dut.siphash_ctrl_reg);
      // $display("");
    end // dut_monitor


  //----------------------------------------------------------------
  // dump_inputs
  // Dump the internal SIPHASH state to std out.
  //----------------------------------------------------------------
  task dump_inputs();
    begin
      $display("Inputs:");
      $display("init = %b, compress = %b, finalize = %b",
               tb_initalize, tb_compress, tb_finalize);
      $display("reset = %b, c = %02x, d = %02x, mi = %08x",
               tb_reset_n, tb_c, tb_d, tb_mi);
      $display("");
    end
  endtask // dump_inputs


  //----------------------------------------------------------------
  // dump_outputs
  // Dump the outputs from the SipHash to std out.
  //----------------------------------------------------------------
  task dump_outputs();
    begin
      $display("Outputs:");
      $display("ready = %d", tb_ready);
      $display("siphash_word = 0x%032x, valid = %d",
               tb_siphash_word, tb_siphash_word_valid);
      $display("");
    end
  endtask // dump_inputs


  //----------------------------------------------------------------
  // dump_state
  // Dump the internal SIPHASH state to std out.
  //----------------------------------------------------------------
  task dump_state();
    begin
      $display("Internal state:");
      $display("v0_reg = %016x, v1_reg = %016x", dut.v0_reg, dut.v1_reg);
      $display("v2_reg = %016x, v3_reg = %016x", dut.v2_reg, dut.v3_reg);
      $display("mi_reg = %016x", dut.mi_reg);
      $display("loop_ctr = %02x, dp_state = %02x, fsm_state = %02x",
               dut.loop_ctr_reg, dut.dp_state_reg, dut.siphash_ctrl_reg);
      $display("");
    end
  endtask // dump_state


  //----------------------------------------------------------------
  //----------------------------------------------------------------
  task run_long_test(
                      input reg [063 : 0] block,
                      input reg [127 : 0] expected
                     );
    begin
      tb_key = 128'h000102030405060708090a0b0c0d0e0f;

    end
  endtask // run_short_test


  //----------------------------------------------------------------
  // test_long()
  //
  // Test cases for long mode.
  //----------------------------------------------------------------
  task test_long();
    reg [127 : 000] long_test_vector;
    begin
      $display("*** Test case for long started.");

      run_long_test(64'h0000000000000000, 128'ha3817f04ba25a8e66df67214c7550293);
      run_long_test(64'h0000000000000000, 128'hda87c1d86b99af44347659119b22fc45);
      run_long_test(64'h0000000000000000, 128'h8177228da4a45dc7fca38bdef60affe4);
      run_long_test(64'h0000000000000000, 128'h9c70b60c5267a94e5f33b6b02985ed51);
      run_long_test(64'h0000000000000000, 128'hf88164c12d9c8faf7d0f6e7c7bcd5579);
      run_long_test(64'h0000000000000000, 128'h1368875980776f8854527a07690e9627);
      run_long_test(64'h0000000000000000, 128'h14eeca338b208613485ea0308fd7a15e);
      run_long_test(64'h0000000000000000, 128'ha1f1ebbed8dbc153c0b84aa61ff08239);
      run_long_test(64'h0000000000000000, 128'h3b62a9ba6258f5610f83e264f31497b4);
      run_long_test(64'h0000000000000000, 128'h264499060ad9baabc47f8b02bb6d71ed);
      run_long_test(64'h0000000000000000, 128'h00110dc378146956c95447d3f3d0fbba);
      run_long_test(64'h0000000000000000, 128'h0151c568386b6677a2b4dc6f81e5dc18);
      run_long_test(64'h0000000000000000, 128'hd626b266905ef35882634df68532c125);
      run_long_test(64'h0000000000000000, 128'h9869e247e9c08b10d029934fc4b952f7);
      run_long_test(64'h0000000000000000, 128'h31fcefac66d7de9c7ec7485fe4494902);
      run_long_test(64'h0000000000000000, 128'h5493e99933b0a8117e08ec0f97cfc3d9);
      run_long_test(64'h0000000000000000, 128'h6ee2a4ca67b054bbfd3315bf85230577);
      run_long_test(64'h0000000000000000, 128'h473d06e8738db89854c066c47ae47740);
      run_long_test(64'h0000000000000000, 128'ha426e5e423bf4885294da481feaef723);
      run_long_test(64'h0000000000000000, 128'h78017731cf65fab074d5208952512eb1);
      run_long_test(64'h0000000000000000, 128'h9e25fc833f2290733e9344a5e83839eb);
      run_long_test(64'h0000000000000000, 128'h568e495abe525a218a2214cd3e071d12);
      run_long_test(64'h0000000000000000, 128'h4a29b54552d16b9a469c10528eff0aae);
      run_long_test(64'h0000000000000000, 128'hc9d184ddd5a9f5e0cf8ce29a9abf691c);
      run_long_test(64'h0000000000000000, 128'h2db479ae78bd50d8882a8a178a6132ad);
      run_long_test(64'h0000000000000000, 128'h8ece5f042d5e447b5051b9eacb8d8f6f);
      run_long_test(64'h0000000000000000, 128'h9c0b53b4b3c307e87eaee08678141f66);
      run_long_test(64'h0000000000000000, 128'habf248af69a6eae4bfd3eb2f129eeb94);
      run_long_test(64'h0000000000000000, 128'h0664da1668574b88b935f3027358aef4);
      run_long_test(64'h0000000000000000, 128'haa4b9dc4bf337de90cd4fd3c467c6ab7);
      run_long_test(64'h0000000000000000, 128'hea5c7f471faf6bde2b1ad7d4686d2287);
      run_long_test(64'h0000000000000000, 128'h2939b0183223fafc1723de4f52c43d35);
      run_long_test(64'h0000000000000000, 128'h7c3956ca5eeafc3e363e9d556546eb68);
      run_long_test(64'h0000000000000000, 128'h77c6077146f01c32b6b69d5f4ea9ffcf);
      run_long_test(64'h0000000000000000, 128'h37a6986cb8847edf0925f0f1309b54de);
      run_long_test(64'h0000000000000000, 128'ha705f0e69da9a8f907241a2e923c8cc8);
      run_long_test(64'h0000000000000000, 128'h3dc47d1f29c448461e9e76ed904f6711);
      run_long_test(64'h0000000000000000, 128'h0d62bf01e6fc0e1a0d3c4751c5d3692b);
      run_long_test(64'h0000000000000000, 128'h8c03468bca7c669ee4fd5e084bbee7b5);
      run_long_test(64'h0000000000000000, 128'h528a5bb93baf2c9c4473cce5d0d22bd9);
      run_long_test(64'h0000000000000000, 128'hdf6a301e95c95dad97ae0cc8c6913bd8);
      run_long_test(64'h0000000000000000, 128'h801189902c857f39e73591285e70b6db);
      run_long_test(64'h0000000000000000, 128'he617346ac9c231bb3650ae34ccca0c5b);
      run_long_test(64'h0000000000000000, 128'h27d93437efb721aa401821dcec5adf89);
      run_long_test(64'h0000000000000000, 128'h89237d9ded9c5e78d8b1c9b166cc7342);
      run_long_test(64'h0000000000000000, 128'h4a6d8091bf5e7d651189fa94a250b14c);
      run_long_test(64'h0000000000000000, 128'h0e33f96055e7ae893ffc0e3dcf492902);
      run_long_test(64'h0000000000000000, 128'he61c432b720b19d18ec8d84bdc63151b);
      run_long_test(64'h0000000000000000, 128'hf7e5aef549f782cf379055a608269b16);
      run_long_test(64'h0000000000000000, 128'h438d030fd0b7a54fa837f2ad201a6403);
      run_long_test(64'h0000000000000000, 128'ha590d3ee4fbf04e3247e0d27f286423f);
      run_long_test(64'h0000000000000000, 128'h5fe2c1a172fe93c4b15cd37caef9f538);
      run_long_test(64'h0000000000000000, 128'h2c97325cbd06b36eb2133dd08b3a017c);
      run_long_test(64'h0000000000000000, 128'h92c814227a6bca949ff0659f002ad39e);
      run_long_test(64'h0000000000000000, 128'hdce850110bd8328cfbd50841d6911d87);
      run_long_test(64'h0000000000000000, 128'h67f14984c7da791248e32bb5922583da);
      run_long_test(64'h0000000000000000, 128'h1938f2cf72d54ee97e94166fa91d2a36);
      run_long_test(64'h0000000000000000, 128'h74481e9646ed49fe0f6224301604698e);
      run_long_test(64'h0000000000000000, 128'h57fca5de98a9d6d8006438d0583d8a1d);
      run_long_test(64'h0000000000000000, 128'h9fecde1cefdc1cbed4763674d9575359);
      run_long_test(64'h0000000000000000, 128'he3040c00eb28f15366ca73cbd872e740);
      run_long_test(64'h0000000000000000, 128'h7697009a6a831dfecca91c5993670f7a);
      run_long_test(64'h0000000000000000, 128'h5853542321f567a005d547a4f04759bd);
      run_long_test(64'h0000000000000000, 128'h5150d1772f50834a503e069a973fbd7c);
    end
  endtask // test_long


  //----------------------------------------------------------------
  //----------------------------------------------------------------
  task run_short_test(
                      input reg [63 : 0] block,
                      input reg [63 : 0] expected
                     );
    begin
      tb_key = 128'h000102030405060708090a0b0c0d0e0f;

    end
  endtask // run_short_test


  //----------------------------------------------------------------
  // test_short()
  //
  // test cases for 64 bit digests.
  //----------------------------------------------------------------
  task test_short();
    reg [063 : 000] short_test_vector;
    begin
      $display("*** Test case for short started.");
      run_short_test(64'h0000000000000000, 64'h310e0edd47db6f72);
      run_short_test(64'h0000000000000000, 64'hfd67dc93c539f874);
      run_short_test(64'h0000000000000000, 64'h5a4fa9d909806c0d);
      run_short_test(64'h0000000000000000, 64'h2d7efbd796666785);
      run_short_test(64'h0000000000000000, 64'hb7877127e09427cf);
      run_short_test(64'h0000000000000000, 64'h8da699cd64557618);
      run_short_test(64'h0000000000000000, 64'hcee3fe586e46c9cb);
      run_short_test(64'h0000000000000000, 64'h37d1018bf50002ab);
      run_short_test(64'h0000000000000000, 64'h6224939a79f5f593);
      run_short_test(64'h0000000000000000, 64'hb0e4a90bdf82009e);
      run_short_test(64'h0000000000000000, 64'hf3b9dd94c5bb5d7a);
      run_short_test(64'h0000000000000000, 64'ha7ad6b22462fb3f4);
      run_short_test(64'h0000000000000000, 64'hfbe50e86bc8f1e75);
      run_short_test(64'h0000000000000000, 64'h903d84c02756ea14);
      run_short_test(64'h0000000000000000, 64'heef27a8e90ca23f7);
      run_short_test(64'h0000000000000000, 64'he545be4961ca29a1);
      run_short_test(64'h0000000000000000, 64'hdb9bc2577fcc2a3f);
      run_short_test(64'h0000000000000000, 64'h9447be2cf5e99a69);
      run_short_test(64'h0000000000000000, 64'h9cd38d96f0b3c14b);
      run_short_test(64'h0000000000000000, 64'hbd6179a71dc96dbb);
      run_short_test(64'h0000000000000000, 64'h98eea21af25cd6be);
      run_short_test(64'h0000000000000000, 64'hc7673b2eb0cbf2d0);
      run_short_test(64'h0000000000000000, 64'h883ea3e395675393);
      run_short_test(64'h0000000000000000, 64'hc8ce5ccd8c030ca8);
      run_short_test(64'h0000000000000000, 64'h94af49f6c650adb8);
      run_short_test(64'h0000000000000000, 64'heab8858ade92e1bc);
      run_short_test(64'h0000000000000000, 64'hf315bb5bb835d817);
      run_short_test(64'h0000000000000000, 64'hadcf6b0763612e2f);
      run_short_test(64'h0000000000000000, 64'ha5c91da7acaa4dde);
      run_short_test(64'h0000000000000000, 64'h716595876650a2a6);
      run_short_test(64'h0000000000000000, 64'h28ef495c53a387ad);
      run_short_test(64'h0000000000000000, 64'h42c341d8fa92d832);
      run_short_test(64'h0000000000000000, 64'hce7cf2722f512771);
      run_short_test(64'h0000000000000000, 64'he37859f94623f3a7);
      run_short_test(64'h0000000000000000, 64'h381205bb1ab0e012);
      run_short_test(64'h0000000000000000, 64'hae97a10fd434e015);
      run_short_test(64'h0000000000000000, 64'hb4a31508beff4d31);
      run_short_test(64'h0000000000000000, 64'h81396229f0907902);
      run_short_test(64'h0000000000000000, 64'h4d0cf49ee5d4dcca);
      run_short_test(64'h0000000000000000, 64'h5c73336a76d8bf9a);
      run_short_test(64'h0000000000000000, 64'hd0a704536ba93e0e);
      run_short_test(64'h0000000000000000, 64'h925958fcd6420cad);
      run_short_test(64'h0000000000000000, 64'ha915c29bc8067318);
      run_short_test(64'h0000000000000000, 64'h952b79f3bc0aa6d4);
      run_short_test(64'h0000000000000000, 64'hf21df2e41d4535f9);
      run_short_test(64'h0000000000000000, 64'h87577519048f53a9);
      run_short_test(64'h0000000000000000, 64'h10a56cf5dfcd9adb);
      run_short_test(64'h0000000000000000, 64'heb75095ccd986cd0);
      run_short_test(64'h0000000000000000, 64'h51a9cb9ecba312e6);
      run_short_test(64'h0000000000000000, 64'h96afadfc2ce666c7);
      run_short_test(64'h0000000000000000, 64'h72fe52975a4364ee);
      run_short_test(64'h0000000000000000, 64'h5a1645b276d592a1);
      run_short_test(64'h0000000000000000, 64'hb274cb8ebf87870a);
      run_short_test(64'h0000000000000000, 64'h6f9bb4203de7b381);
      run_short_test(64'h0000000000000000, 64'heaecb2a30b22a87f);
      run_short_test(64'h0000000000000000, 64'h9924a43cc1315724);
      run_short_test(64'h0000000000000000, 64'hbd838d3aafbf8db7);
      run_short_test(64'h0000000000000000, 64'h0b1a2a3265d51aea);
      run_short_test(64'h0000000000000000, 64'h135079a3231ce660);
      run_short_test(64'h0000000000000000, 64'h932b2846e4d70666);
      run_short_test(64'h0000000000000000, 64'he1915f5cb1eca46c);
      run_short_test(64'h0000000000000000, 64'hf325965ca16d629f);
      run_short_test(64'h0000000000000000, 64'h575ff28e60381be5);
      run_short_test(64'h0000000000000000, 64'h724506eb4c328a95);

    end
  endtask // test_short


  //----------------------------------------------------------------
  // siphash_core_test
  // The main test functionality.
  //----------------------------------------------------------------
  initial
    begin : siphash_core_test
      $display("   -- Testbench for siphash_core started --");

      // Set clock, reset and DUT input signals to
      // defined values at simulation start.
      tb_c         = 8'h02;
      tb_d         = 8'h04;
      tb_mi        = 64'h0000000000000000;
      tb_key       = 128'h00000000000000000000000000000000;
      tb_initalize = 0;
      tb_compress  = 0;
      tb_finalize  = 0;
      tb_long      = 0;

      cycle_ctr    = 0;
      tb_clk       = 0;
      tb_reset_n   = 0;
      dump_state();

      // Wait ten clock cycles and release reset.
      #(10 * CLK_PERIOD);
      @(negedge tb_clk)
      tb_reset_n = 1;
      dump_state();

      // Dump the state to check reset.
      #(2 * CLK_PERIOD);
      dump_state();
      dump_outputs();

      // Pull init flag for a cycle
      // We use the SipHash paper Appendix A key.
      #(10 * CLK_PERIOD);
      tb_key = 128'h0f0e0d0c0b0a09080706050403020100;
      tb_initalize = 1;
      #(CLK_PERIOD);
      tb_initalize = 0;
      dump_outputs();

      // Add first block.
      #(CLK_PERIOD);
      tb_compress = 1;
      tb_mi = 64'h0706050403020100;
      #(CLK_PERIOD);
      tb_compress = 0;
      dump_state();
      dump_outputs();

      // Wait a number of cycle and
      // try and start the next iteration.
      #(50 * CLK_PERIOD);
      dump_outputs();
      tb_compress = 1;
      tb_mi = 64'h0f0e0d0c0b0a0908;
      #(CLK_PERIOD);
      tb_compress = 0;
      dump_state();
      dump_outputs();

      // Wait a number of cycles and
      // and pull finalizaition.
      #(50 * CLK_PERIOD);
      dump_outputs();
      tb_finalize = 1;
      #(CLK_PERIOD);
      tb_finalize = 0;
      dump_state();
      dump_outputs();

      // Wait some cycles.
      #(100 * CLK_PERIOD);
      $display("Processing done..");
      dump_state();
      dump_outputs();

      // Finish in style.
      $display("siphash_core simulation done.");
      $finish;
    end // siphash_core_test

endmodule // tb_siphash_core

//======================================================================
// EOF tb_siphash_core.v
//======================================================================
