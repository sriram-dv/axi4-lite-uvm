class read_sequence extends uvm_sequence #(axi_transaction);
    `uvm_object_utils(read_sequence)
    axi_transaction cmd;

    function new(string name = "read_sequence");
        super.new(name);
    endfunction

    task body();
        cmd = axi_transaction#()::type_id::create("cmd");
        start_item(cmd);
        
        // Explicitly trigger the SV solver and force a Read operation
        if (!cmd.randomize() with { op == r_op; }) begin
            `uvm_fatal("RAND_FAIL", "Transaction randomization failed in read_sequence")
        end
        
        finish_item(cmd);
    endtask 
endclass
