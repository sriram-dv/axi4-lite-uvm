class write_sequence extends uvm_sequence #(axi_transaction);
    `uvm_object_utils(write_sequence);
    axi_transaction cmd;

    function new(string name = "short_random_sequence");
        super.new(name);
    endfunction
    
    task body();
        cmd = axi_transaction#()::type_id::create("cmd");
        start_item(cmd);
        
        // Use the built-in SV solver to generate random data/addr, 
        // and constrain the operation to be a write.
        if (!cmd.randomize() with { op == w_op; }) begin
            `uvm_fatal("RAND_FAIL", "Transaction randomization failed in write_sequence")
        end
        
        finish_item(cmd);
        `uvm_info("WRITE", $sformatf("write test: %s", cmd.convert2string()), UVM_HIGH)
    endtask
endclass
