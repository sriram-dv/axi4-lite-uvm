// multi_read_sequence.sv - CORRECTED
class multi_read_sequence extends uvm_sequence #(axi_transaction);
    `uvm_object_utils(multi_read_sequence) // Fixed macro
    axi_transaction cmd;
    rand int num_reads; // Renamed for clarity
    
    constraint num_reads_range { num_reads inside {[1:10]}; }

    function new(string name = "multi_read_sequence"); // Fixed constructor
        super.new(name);
    endfunction

    task body();
        if(!this.randomize()) `uvm_fatal("RAND_FAIL", "Failed to randomize num_reads")
        
        for (int i = 0; i < num_reads; i++) begin
            cmd = axi_transaction#()::type_id::create("cmd");
            start_item(cmd);
            
            if (!cmd.randomize() with { op == r_op; }) begin // Fixed constraint
                `uvm_fatal("RAND_FAIL", "Randomization failed in multi_read")
            end
            
            finish_item(cmd);
        end
    endtask
endclass
