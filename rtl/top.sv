`timescale 1ns / 1ps

module top ();
    import uvm_pkg::*;
    import   axi_test_pkg::*;
    `include "uvm_macros.svh"
    
    axi_lite_if    axi_if();
    axi_lite_slave DUT (.slave_if(axi_if), .dut_mem(axi_if.dut_mem));
    
    initial begin
        uvm_config_db #(virtual axi_lite_if)::set(null, "*", "axi_if", axi_if);

        // GLOBALLY SUPPRESS FALSE-POSITIVE DPI NAMING WARNINGS USING THE OOP SINGLETON
        uvm_root::get().set_report_id_action_hier("UVM/COMP/NAME", UVM_NO_ACTION);

        run_test();
    end
    
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, top);
    end
endmodule
