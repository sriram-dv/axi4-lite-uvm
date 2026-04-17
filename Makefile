# Makefile for AXI4-Lite Slave UVM Verification with Verilator
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
VERILATOR_FLAGS += +incdir+$(UVM_SRC)
VERILATOR_FLAGS += +define+UVM_NO_DPI
VERILATOR_FLAGS += +define+DATA_WIDTH=32
VERILATOR_FLAGS += +define+ADDR_WIDTH=8
VERILATOR_FLAGS += $(UVM_SRC)/uvm_pkg.sv

# Project Files (Ordered by dependency)
SV_FILES = \
	axi_test_pkg.sv \
	transaction.sv \
	command_monitor.sv \
	result_monitor.sv \
	coverage.sv \
	scoreboard.sv \
	driver.sv \
	env.sv \
	write_sequence.sv \
	read_sequence.sv \
	multi_write_sequence.sv \
	multi_read_sequence.sv \
	seq_write_sequence.sv \
	seq_read_sequence.sv \
	base_test.sv \
	write_test.sv \
	read_test.sv \
	test_all.sv \
	axi_lite_if.sv \
	axi_lite_slave.sv \
	top.sv

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
	./obj_dir/sim_vlt +UVM_TESTNAME=$(TEST_NAME)

# Helper to create file list
files.f:
	@echo "Creating files.f..."
	@rm -f files.f
	@for file in $(SV_FILES); do echo $$file >> files.f; done

clean:
	rm -rf obj_dir
	rm -f files.f
	rm -f *.vcd

.PHONY: all compile run clean
