class result_monitor extends uvm_monitor;
    `uvm_component_utils(result_monitor)

    uvm_analysis_port #(axi_transaction) ap;
    virtual axi_lite_if axi_if;
    
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Retrieve the virtual interface using correct hierarchy
        if(!uvm_config_db #(virtual axi_lite_if)::get(this, "", "axi_if", axi_if)) begin
            `uvm_fatal("NO_VIF", "Failed to get axi_if in result_monitor");
        end
        
        ap = new("ap", this);
        
        // Hand the monitor's memory pointer back to the interface
        axi_if.result_monitor_h = this;
    endfunction
    
    // The interface calls this function when it pops a completed transaction
    function void write_to_monitor(axi_transaction cmd);
        axi_transaction copy;
        copy = cmd.get_copy();
        
        `uvm_info("RES_MON", $sformatf("addr:0x%8h data:0x%8h op: %s", copy.addr, copy.data, copy.op.name()), UVM_LOW)
        
        // Broadcast to the scoreboard
        ap.write(copy);
    endfunction
endclass
