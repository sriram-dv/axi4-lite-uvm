class result_monitor extends uvm_monitor;
    `uvm_component_utils(result_monitor)

    uvm_analysis_port #(axi_transaction) ap;
    virtual axi_lite_if axi_if;
    
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db #(virtual axi_lite_if)::get(this, "", "axi_if", axi_if)) begin
            `uvm_fatal("NO_VIF", "Failed to get axi_if in result_monitor");
        end
        ap = new("ap", this);
    endfunction

    // Monitor now independently polls the interface, removing Verilator boundary drops
    task run_phase(uvm_phase phase);
        axi_transaction tr;
        forever begin
            @(posedge axi_if.clk);
            
            // 1. Passively sample Read Responses
            if (axi_if.RVALID == 1'b1 && axi_if.RREADY == 1'b1) begin
                if (axi_if.read_buffer.size() > 0) begin
                    tr = axi_if.read_buffer.pop_front();
                    tr.data = axi_if.RDATA;
                    write_to_monitor(tr);
                end
            end

            // 2. Passively sample Write Responses
            if (axi_if.BVALID == 1'b1 && axi_if.BREADY == 1'b1) begin
                if (axi_if.write_buffer.size() > 0) begin
                    tr = axi_if.write_buffer.pop_front();
                    
                    // Match the RTL's word-aligned addressing logic
                    if (tr.addr < 256) begin
                        tr.data = axi_if.dut_mem[tr.addr >> 2]; 
                    end else begin
                        tr.data = 32'hDEADBEEF;
                    end
                    write_to_monitor(tr);
                end
            end
        end
    endtask
    
    function void write_to_monitor(axi_transaction cmd);
        axi_transaction copy;
        copy = cmd.get_copy();
        
        `uvm_info("RES_MON", $sformatf("addr:0x%8h data:0x%8h op: %s", copy.addr, copy.data, copy.op.name()), UVM_LOW)
        ap.write(copy);
    endfunction
endclass
