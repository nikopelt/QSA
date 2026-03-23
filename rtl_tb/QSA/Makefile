# Makefile

SIM ?= verilator
WAVES?= 1
EXTRA_ARGS = --trace --trace-fst
TOPLEVEL_LANG ?= verilog

# MVM ROW MODULE 
VERILOG_SOURCES += $(PWD)/../MVM/*.sv

# CFG ARRAY MODULE 
VERILOG_SOURCES += $(PWD)/../cfg_array/*.sv

# QSA MODULES
VERILOG_SOURCES += $(PWD)/*.sv


COCOTB_TOPLEVEL = QSA

COCOTB_TEST_MODULES = tb_fixed

include $(shell cocotb-config --makefiles)/Makefile.sim

wave:
	gtkwave dump.fst waves.gtkw > /dev/null 2>&1 &
