class multi_read_sequence extends uvm_sequence #(axi_transaction);
    `uvm_object_utils(multi_write_sequence)
    axi_transaction cmd;
    rand int num_writes;
    
    constraint num_writes_range { num_writes inside {[1:10]}; }

    function new(string name = "multi_write_sequence");
        super.new(name);
    endfunction

    task body();
        if(!this.randomize()) `uvm_fatal("RAND_FAIL", "Failed to randomize num_writes")
        
        for (int i = 0; i < num_writes; i++) begin
            cmd = axi_transaction#()::type_id::create("cmd");
            start_item(cmd);
            
            if (!cmd.randomize() with { op == w_op; }) begin
                `uvm_fatal("RAND_FAIL", "Randomization failed in multi_write")
            end
            
            finish_item(cmd);
        end
    endtask
endclass
