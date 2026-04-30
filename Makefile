# Project: Design and UVM-based functional verification of AXI4-Lite Slave Interface

# Paths
UVM_ROOT ?= $(shell pwd)/uvm-src
UVM_SRC = $(UVM_ROOT)/src

# Verilator settings
VERILATOR = verilator
VERILATOR_FLAGS += --binary --timing -j 8
VERILATOR_FLAGS += --timescale 1ns/1ps
VERILATOR_FLAGS += -Wno-fatal -Wno-lint -Wno-style -Wno-SYMRSVDWORD -Wno-DECLFILENAME
VERILATOR_FLAGS += -Wno-COVERIGN -Wno-CONSTRAINTIGN -Wno-TIMESCALEMOD
VERILATOR_FLAGS += --trace
VERILATOR_FLAGS += --coverage
VERILATOR_FLAGS += +incdir+$(UVM_SRC)
VERILATOR_FLAGS += +incdir+tb +incdir+tests +incdir+rtl
VERILATOR_FLAGS += +define+UVM_NO_DPI
VERILATOR_FLAGS += +define+DATA_WIDTH=32
VERILATOR_FLAGS += +define+ADDR_WIDTH=8
VERILATOR_FLAGS += $(UVM_SRC)/uvm_pkg.sv

# Project Files (Ordered by dependency)
SV_FILES = \
	tb/axi_test_pkg.sv \
	tb/transaction.sv \
	tb/command_monitor.sv \
	tb/result_monitor.sv \
	tb/coverage.sv \
	tb/scoreboard.sv \
	tb/driver.sv \
	tb/env.sv \
	tests/write_sequence.sv \
	tests/read_sequence.sv \
	tests/multi_write_sequence.sv \
	tests/multi_read_sequence.sv \
	tests/seq_write_sequence.sv \
	tests/seq_read_sequence.sv \
	tests/base_test.sv \
	tests/write_test.sv \
	tests/read_test.sv \
	tests/test_all.sv \
	tb/axi_lite_if.sv \
	rtl/axi_lite_slave.sv \
	rtl/top.sv

# Compilation Target
TOP_MODULE = top
TEST_NAME ?= test_all

all: run

compile: files.f
	$(VERILATOR) $(VERILATOR_FLAGS) \
		-f ./files.f \
		--top-module $(TOP_MODULE) \
		-o sim_vlt

run: compile
	./obj_dir/sim_vlt +UVM_TESTNAME=$(TEST_NAME) +uvm_set_action="*,UVM/COMP/NAME,UVM_WARNING,UVM_NO_ACTION"
# Helper to create file list
files.f:
	@echo "Creating files.f..."
	@rm -f files.f
	@for file in $(SV_FILES); do echo $$file >> files.f; done

clean:
	rm -rf obj_dir
	rm -f files.f
	rm -f *.vcd
	rm -rf logs
	rm -f coverage.dat


.PHONY: all compile run clean
