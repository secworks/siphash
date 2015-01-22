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
  reg [127 : 0]  tb_k;
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
                   .k(tb_k),
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
      $display("siphash_word = 0x%032x, valid = %d", tb_siphash_word, tb_siphash_word_valid);
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


  task test_long()
    begin
      $display("*** Test case for long started.");

      long_vector00 = 128'ha3817f04ba25a8e66df67214c7550293;
      long_vector01 = 128'hda87c1d86b99af44347659119b22fc45;
      long_vector02 = 128'h8177228da4a45dc7fca38bdef60affe4;
      long_vector03 = 128'h9c70b60c5267a94e5f33b6b02985ed51;
      long_vector04 = 128'hf88164c12d9c8faf7d0f6e7c7bcd5579;
      long_vector05 = 128'h1368875980776f8854527a07690e9627;
      long_vector06 = 128'h14eeca338b208613485ea0308fd7a15e;
      long_vector07 = 128'ha1f1ebbed8dbc153c0b84aa61ff08239;
      long_vector08 = 128'h3b62a9ba6258f5610f83e264f31497b4;
      long_vector09 = 128'h264499060ad9baabc47f8b02bb6d71ed;
      long_vector10 = 128'h00110dc378146956c95447d3f3d0fbba;
      long_vector11 = 128'h0151c568386b6677a2b4dc6f81e5dc18;
      long_vector12 = 128'hd626b266905ef35882634df68532c125;
      long_vector13 = 128'h9869e247e9c08b10d029934fc4b952f7;
      long_vector14 = 128'h31fcefac66d7de9c7ec7485fe4494902;
      long_vector15 = 128'h5493e99933b0a8117e08ec0f97cfc3d9;
      long_vector16 = 128'h6ee2a4ca67b054bbfd3315bf85230577;
      long_vector17 = 128'h473d06e8738db89854c066c47ae47740;
      long_vector18 = 128'ha426e5e423bf4885294da481feaef723;
      long_vector19 = 128'h78017731cf65fab074d5208952512eb1;
      long_vector20 = 128'h9e25fc833f2290733e9344a5e83839eb;
      long_vector21 = 128'h568e495abe525a218a2214cd3e071d12;
      long_vector22 = 128'h4a29b54552d16b9a469c10528eff0aae;
      long_vector23 = 128'hc9d184ddd5a9f5e0cf8ce29a9abf691c;
      long_vector24 = 128'h2db479ae78bd50d8882a8a178a6132ad;
      long_vector25 = 128'h8ece5f042d5e447b5051b9eacb8d8f6f;
      long_vector26 = 128'h9c0b53b4b3c307e87eaee08678141f66;
      long_vector27 = 128'habf248af69a6eae4bfd3eb2f129eeb94;
      long_vector28 = 128'h0664da1668574b88b935f3027358aef4;
      long_vector29 = 128'haa4b9dc4bf337de90cd4fd3c467c6ab7;
      long_vector30 = 128'hea5c7f471faf6bde2b1ad7d4686d2287;
      long_vector31 = 128'h2939b0183223fafc1723de4f52c43d35;
      long_vector32 = 128'h7c3956ca5eeafc3e363e9d556546eb68;
      long_vector33 = 128'h77c6077146f01c32b6b69d5f4ea9ffcf;
      long_vector34 = 128'h37a6986cb8847edf0925f0f1309b54de;
      long_vector35 = 128'ha705f0e69da9a8f907241a2e923c8cc8;
      long_vector36 = 128'h3dc47d1f29c448461e9e76ed904f6711;
      long_vector37 = 128'h0d62bf01e6fc0e1a0d3c4751c5d3692b;
      long_vector38 = 128'h8c03468bca7c669ee4fd5e084bbee7b5;
      long_vector39 = 128'h528a5bb93baf2c9c4473cce5d0d22bd9;
      long_vector40 = 128'hdf6a301e95c95dad97ae0cc8c6913bd8;
      long_vector41 = 128'h801189902c857f39e73591285e70b6db;
      long_vector42 = 128'he617346ac9c231bb3650ae34ccca0c5b;
      long_vector43 = 128'h27d93437efb721aa401821dcec5adf89;
      long_vector44 = 128'h89237d9ded9c5e78d8b1c9b166cc7342;
      long_vector45 = 128'h4a6d8091bf5e7d651189fa94a250b14c;
      long_vector46 = 128'h0e33f96055e7ae893ffc0e3dcf492902;
      long_vector47 = 128'he61c432b720b19d18ec8d84bdc63151b;
      long_vector48 = 128'hf7e5aef549f782cf379055a608269b16;
      long_vector49 = 128'h438d030fd0b7a54fa837f2ad201a6403;
      long_vector50 = 128'ha590d3ee4fbf04e3247e0d27f286423f;
      long_vector51 = 128'h5fe2c1a172fe93c4b15cd37caef9f538;
      long_vector52 = 128'h2c97325cbd06b36eb2133dd08b3a017c;
      long_vector53 = 128'h92c814227a6bca949ff0659f002ad39e;
      long_vector54 = 128'hdce850110bd8328cfbd50841d6911d87;
      long_vector55 = 128'h67f14984c7da791248e32bb5922583da;
      long_vector56 = 128'h1938f2cf72d54ee97e94166fa91d2a36;
      long_vector57 = 128'h74481e9646ed49fe0f6224301604698e;
      long_vector58 = 128'h57fca5de98a9d6d8006438d0583d8a1d;
      long_vector59 = 128'h9fecde1cefdc1cbed4763674d9575359;
      long_vector60 = 128'he3040c00eb28f15366ca73cbd872e740;
      long_vector61 = 128'h7697009a6a831dfecca91c5993670f7a;
      long_vector62 = 128'h5853542321f567a005d547a4f04759bd;
      long_vector63 = 128'h5150d1772f50834a503e069a973fbd7c;

    end
  endtask // test_long


  //----------------------------------------------------------------
  // test_short()
  //
  // test cases for 64 bit digests.
  //----------------------------------------------------------------
  task test_short();
    begin
      $display("*** Test case for short started.");

      short_vectors00 = 64'h310e0edd47db6f72;
      short_vectors01 = 64'hfd67dc93c539f874;
      short_vectors02 = 64'h5a4fa9d909806c0d;
      short_vectors03 = 64'h2d7efbd796666785;
      short_vectors04 = 64'hb7877127e09427cf;
      short_vectors05 = 64'h8da699cd64557618;
      short_vectors06 = 64'hcee3fe586e46c9cb;
      short_vectors07 = 64'h37d1018bf50002ab;
      short_vectors08 = 64'h6224939a79f5f593;
      short_vectors09 = 64'hb0e4a90bdf82009e;
      short_vectors10 = 64'hf3b9dd94c5bb5d7a;
      short_vectors11 = 64'ha7ad6b22462fb3f4;
      short_vectors12 = 64'hfbe50e86bc8f1e75;
      short_vectors13 = 64'h903d84c02756ea14;
      short_vectors14 = 64'heef27a8e90ca23f7;
      short_vectors15 = 64'he545be4961ca29a1;
      short_vectors16 = 64'hdb9bc2577fcc2a3f;
      short_vectors17 = 64'h9447be2cf5e99a69;
      short_vectors18 = 64'h9cd38d96f0b3c14b;
      short_vectors19 = 64'hbd6179a71dc96dbb;
      short_vectors20 = 64'h98eea21af25cd6be;
      short_vectors21 = 64'hc7673b2eb0cbf2d0;
      short_vectors22 = 64'h883ea3e395675393;
      short_vectors23 = 64'hc8ce5ccd8c030ca8;
      short_vectors24 = 64'h94af49f6c650adb8;
      short_vectors25 = 64'heab8858ade92e1bc;
      short_vectors26 = 64'hf315bb5bb835d817;
      short_vectors27 = 64'hadcf6b0763612e2f;
      short_vectors28 = 64'ha5c91da7acaa4dde;
      short_vectors29 = 64'h716595876650a2a6;
      short_vectors30 = 64'h28ef495c53a387ad;
      short_vectors31 = 64'h42c341d8fa92d832;
      short_vectors32 = 64'hce7cf2722f512771;
      short_vectors33 = 64'he37859f94623f3a7;
      short_vectors34 = 64'h381205bb1ab0e012;
      short_vectors35 = 64'hae97a10fd434e015;
      short_vectors36 = 64'hb4a31508beff4d31;
      short_vectors37 = 64'h81396229f0907902;
      short_vectors38 = 64'h4d0cf49ee5d4dcca;
      short_vectors39 = 64'h5c73336a76d8bf9a;
      short_vectors40 = 64'hd0a704536ba93e0e;
      short_vectors41 = 64'h925958fcd6420cad;
      short_vectors42 = 64'ha915c29bc8067318;
      short_vectors43 = 64'h952b79f3bc0aa6d4;
      short_vectors44 = 64'hf21df2e41d4535f9;
      short_vectors45 = 64'h87577519048f53a9;
      short_vectors46 = 64'h10a56cf5dfcd9adb;
      short_vectors47 = 64'heb75095ccd986cd0;
      short_vectors48 = 64'h51a9cb9ecba312e6;
      short_vectors49 = 64'h96afadfc2ce666c7;
      short_vectors50 = 64'h72fe52975a4364ee;
      short_vectors51 = 64'h5a1645b276d592a1;
      short_vectors52 = 64'hb274cb8ebf87870a;
      short_vectors53 = 64'h6f9bb4203de7b381;
      short_vectors54 = 64'heaecb2a30b22a87f;
      short_vectors55 = 64'h9924a43cc1315724;
      short_vectors56 = 64'hbd838d3aafbf8db7;
      short_vectors57 = 64'h0b1a2a3265d51aea;
      short_vectors58 = 64'h135079a3231ce660;
      short_vectors59 = 64'h932b2846e4d70666;
      short_vectors60 = 64'he1915f5cb1eca46c;
      short_vectors61 = 64'hf325965ca16d629f;
      short_vectors62 = 64'h575ff28e60381be5;
      short_vectors63 = 64'h724506eb4c328a95;
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
      tb_k         = 128'h00000000000000000000000000000000;
      tb_initalize = 0;
      tb_compress  = 0;
      tb_finalize  = 0;
      tb_long      = 0;

      cycle_ctr    = 0;
      tb_clk       = 0;
      tb_reset_n   = 0;
      dump_state();

      // Wait ten clock cycles and release reset.
      #(20 * CLK_HALF_PERIOD);
      @(negedge tb_clk)
      tb_reset_n = 1;
      dump_state();

      // Dump the state to check reset.
      #(4 * CLK_HALF_PERIOD);
      dump_state();
      dump_outputs();

      // Pull init flag for a cycle
      // We use the SipHash paper Appendix A key.
      #(20 * CLK_HALF_PERIOD);
      tb_k = 128'h0f0e0d0c0b0a09080706050403020100;
      tb_initalize = 1;
      #(2 * CLK_HALF_PERIOD);
      tb_initalize = 0;
      dump_outputs();

      // Add first block.
      #(2 * CLK_HALF_PERIOD);
      tb_compress = 1;
      tb_mi = 64'h0706050403020100;
      #(2 * CLK_HALF_PERIOD);
      tb_compress = 0;
      dump_state();
      dump_outputs();

      // Wait a number of cycle and
      // try and start the next iteration.
      #(100 * CLK_HALF_PERIOD);
      dump_outputs();
      tb_compress = 1;
      tb_mi = 64'h0f0e0d0c0b0a0908;
      #(2 * CLK_HALF_PERIOD);
      tb_compress = 0;
      dump_state();
      dump_outputs();

      // Wait a number of cycles and
      // and pull finalizaition.
      #(100 * CLK_HALF_PERIOD);
      dump_outputs();
      tb_finalize = 1;
      #(2 * CLK_HALF_PERIOD);
      tb_finalize = 0;
      dump_state();
      dump_outputs();

      // Wait some cycles.
      #(200 * CLK_HALF_PERIOD);
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
