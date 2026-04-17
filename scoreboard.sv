class scoreboard extends uvm_subscriber #(axi_transaction);
    `uvm_component_utils(scoreboard)
    uvm_tlm_analysis_fifo #(axi_transaction) res;
    logic [DATA_WIDTH-1:0] mem [63:0];
    int total_count, success_count;

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        res = new ("res", this);
        total_count = 0;
        success_count = 0;
    endfunction

    // 1. Capture Command (Instantly updates memory model on write)
    function void write(axi_transaction t);
        if (t.op == rst_op) begin
            foreach (mem[i]) mem[i] = '0;
        end else if (t.op == w_op) begin
            mem[t.addr] = t.data; 
        end
    endfunction 

    // 2. Evaluate Result (Blocks until response arrives from the slave)
    task run_phase(uvm_phase phase);
        axi_transaction result;
        forever begin
            // Blocking get: Waits patiently for the result monitor to push data
            res.get(result); 
            total_count += 1;
            
            if (result.op == r_op) begin
                if (mem[result.addr] !== result.data) begin
                    `uvm_error("SCOREBOARD", $sformatf("FAILED: addr: %2h expected: %8h actual: %8h", result.addr, mem[result.addr], result.data))
                end else begin
                    success_count += 1;
                end
            end else begin
                // Write responses just indicate completion
                success_count += 1; 
            end
        end
    endtask

    function void final_phase(uvm_phase phase);
        super.final_phase(phase);
        `uvm_info("SCOREBOARD", $sformatf("Total ops: %0d, Success: %0d, Fail: %0d", 
                total_count, success_count, total_count - success_count), UVM_LOW)
    endfunction
endclass
