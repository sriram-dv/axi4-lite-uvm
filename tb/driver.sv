class driver extends uvm_driver #(axi_transaction);
   `uvm_component_utils(driver)
   virtual axi_lite_if axi_if;
 
    function void build_phase(uvm_phase phase);
        if(!uvm_config_db #(virtual axi_lite_if)::get(this, "", "axi_if", axi_if)) begin
    `uvm_fatal("NO_VIF", "Virtual interface not found in driver!")
end
    endfunction
    
    task run_phase(uvm_phase phase);
        axi_transaction cmd;
        forever begin
            seq_item_port.get_next_item(cmd);
            axi_if.do_op(cmd);
            seq_item_port.item_done();
        end
    endtask 
    
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass
