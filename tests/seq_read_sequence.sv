class seq_read_sequence extends uvm_sequence #(axi_transaction);
    `uvm_object_utils(seq_read_sequence)
    axi_transaction cmd;
    rand int num_reads;
    int initial_addr;

    constraint num_reads_range { num_reads inside {[1:10]}; }

    function new(string name = "seq_read_sequence");
        super.new(name);
    endfunction

    task body();
        if(!this.randomize()) `uvm_fatal("RAND_FAIL","Failed num_reads");
        
        // 1. Establish random initial address and force a read operation
        cmd = axi_transaction#()::type_id::create("cmd");
        start_item(cmd);
        if (!cmd.randomize() with { op == r_op; }) `uvm_fatal("RAND_FAIL", "rand failed")
        initial_addr = cmd.addr;
        finish_item(cmd);
        
        // 2. Loop with sequential addressing
        for (int i = 0; i < num_reads; i++) begin
            cmd = axi_transaction#()::type_id::create("cmd");
            start_item(cmd);
            
            // Force a read operation, then explicitly overwrite the address sequentially
            if (!cmd.randomize() with { op == r_op; }) `uvm_fatal("RAND_FAIL", "rand failed")
            cmd.addr = initial_addr + 4 * (i + 1); 
            
            finish_item(cmd);
        end
    endtask
endclass
