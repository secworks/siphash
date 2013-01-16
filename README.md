# SipHash Core #

## Introduction ##

This is a hardware implementation of the SipHash [1] keyed hash
function written in Verilog 2001.

The implementation is designed as a self contained core that performs
the message block processing including initialization, compression and
finalization operations. The core does not implement the functionality
to divide a message into 64 bit message blocks.

The core is suitable as an application specific SipHash coprocessor
offloading compact 8, 16 or 32 bit processors from hashing and Message
Authentication Code (MAC) processing. The core is substantially faster
and more compact in terms of hardware resources than for example cores
implementing the MD5 cryptographic hash function.

The project includes a testbench that tests the core using the
Appendix A testvectors in the SipHash paper [1]. The project also
includes a simple Makefile for compiling the core using Icarus Verilog.

The core has been as hardware for an Altera Cyclone IV GX FPGA, see
Implementation notes below for more information.

This core is licensed for use under a BSD license, see LICENSE.txt for
more information.


## Usage ##

The core accepts 64 bit blocks (mi) of a given message to process. Prior
to processing a key dependent initalization. Initalization is done by
setting the key port (k) and assering the (initalize) flag for at least
one cycle and then deassert the flag.

Processing a message block is done by assigning the block to the message
block port (mi) and asserting the (compress) flag.

After all blocks in the message has been processed the processing is
completed by asserting the (finalize) flag for one cycle.

The core will assert the (siphash_word_valid) flag when the new SipHash
word for the message is ready.

The core will only accept new commands (initialize, compress, finalize)
when the (ready) flag is asserted.


## Implementation notes ## 

The core is implemented using the Verilog 2001 hardware description
language. The core uses synchronous reset for all registers and all
registers are equipped with write enable. The core should integrate and
build cleanly into any standard FPGA project.

The core implements the SipRound function with two 64 bit adders capable
of performin operations in parallel. A single SipRound operation takes
four cycles to perform. Total latency for processing a single 64 bit
block using SipHash-2-4 is:

 -                  1 cycle for initialization
 - 1 + 2 * 4 + 1 = 10 cycles for compression
 - 4 * 4 + 1     = 17 cycles for finalization

In total: 28 cycles or 3.5 cycles/byte


## Implementation results ##

A test implementation of the core for Altera Cyclone IV GX has been done
using the Altera Quartus 12 design tool. The resource usage for the core
is:

  - Number of LEs: 1451
  - Number of regs: 332
  - Max frequency:  117 MHz

Note: Quartus might add three regs due to FSM encoding.


As a comparison, building the OpenCores MD5 core [2] using the same
tools and for the same target device requires the following amount of
resources: 

  - Number of LEs: 1883
  - Number of regs: 910
  - Max frequency:   62 MHz

Note: MD5 processing takes at least 64 cycles for a message block.


## TODOs ##
* Create compact as well as high performance versions of the core.

* Add a top level wrapper with a simple API for easy integration with
  WISHBONE or AMBA APB bus standards.

* Add more test cases. Vectors as well as use cases.


## References ##

[1] J-P. Aumasson, D. J. Bernstein. SipHash: a fast short-input PRF.

  - SipHash Project: https://131002.net/siphash/
  - Siphash Paper: https://131002.net/siphash/siphash.pdf        


[2] OpenCores. MD5 core.

  - Core home page: http://opencores.org/project,systemcmd5