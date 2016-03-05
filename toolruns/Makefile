#=======================================================================
#
# Makefile
# --------
# Makefile for building the SipHash core.
#
#
# Copyright (c) 2012, Secworks Sweden AB
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or
# without modification, are permitted provided that the following
# conditions are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in
#    the documentation and/or other materials provided with the
#    distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
# COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#=======================================================================

CORE_SRC = ../src/rtl/siphash_core.v
TOP_SRC = ../src/rtl/siphash.v $(CORE_SRC)

TOP_TB = ../src/tb/tb_siphash.v
CORE_TB = ../src/tb/tb_siphash_core.v

CC = iverilog
LINT=verilator


all:    top core


top:	$(TOP_TB) $(TOP_SRC)
	iverilog -Wall -o top.sim $(TOP_TB) $(TOP_SRC)


core:	$(CORE_TB) $(CORE_SRC)
	iverilog -Wall -o core.sim $(CORE_TB) $(CORE_SRC)


lint:
	verilator --lint-only -Wall $(TOP_SRC)


clean:
	rm *.sim


help:
	@echo "Supported targets:"
	@echo "------------------"
	@echo "all:      Build all simulation targets."
	@echo "top:      Build the top simulation target."
	@echo "core:     Build the core simulation target."
	@echo "lint:     Run the linter on the source"
	@echo "clean:    Delete all built files."

#=======================================================================
# EOF Makefile
#=======================================================================
