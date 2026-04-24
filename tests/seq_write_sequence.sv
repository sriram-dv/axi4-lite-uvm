class seq_write_sequence extends uvm_sequence #(axi_transaction);
    `uvm_object_utils(seq_write_sequence)
    axi_transaction cmd;
    rand int num_writes;
    int initial_addr;

    constraint num_writes_range { num_writes inside {[1:10]}; }

    function new(string name = "seq_write_sequence");
        super.new(name);
    endfunction

    task body();
        if(!this.randomize()) `uvm_fatal("RAND_FAIL","Failed num_writes");
        
        // 1. Establish random initial address and initial data
        cmd = axi_transaction#()::type_id::create("cmd");
        start_item(cmd);
        if (!cmd.randomize() with { op == w_op; }) `uvm_fatal("RAND_FAIL", "rand failed")
        initial_addr = cmd.addr;
        finish_item(cmd);
        
        // 2. Loop with sequential addressing
        for (int i = 0; i < num_writes; i++) begin
            cmd = axi_transaction#()::type_id::create("cmd");
            start_item(cmd);
            
            // Randomize data first, then explicitly overwrite the address
            if (!cmd.randomize() with { op == w_op; }) `uvm_fatal("RAND_FAIL", "rand failed")
            cmd.addr = initial_addr + 4 * (i + 1); 
            
            finish_item(cmd);
        end
    endtask
endclass
