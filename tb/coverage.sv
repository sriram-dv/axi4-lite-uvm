class coverage extends uvm_subscriber #(axi_transaction);
   `uvm_component_utils(coverage)
   axi_transaction cmd;

   int prev_addr;
   int consecutive_count;
   
   covergroup cg_axi_lite;
      coverpoint cmd.addr;
      coverpoint cmd.data;

      coverpoint cmd.op {
         bins rst   = {rst_op};
         bins write = {w_op};
         bins read  = {r_op};
         bins noop  = {no_op};
         
         // Replaced unsupported array history with native SV transition bins
         bins write_to_read = (w_op => r_op);
         bins read_to_write = (r_op => w_op);
         bins consecutive_writes = (w_op => w_op);
         bins consecutive_reads = (r_op => r_op);
      }
      
      coverpoint consecutive_count {
        bins consecutive_bins[] = {1,2,3,4,5};
      }
      
      cross cmd.addr, cmd.data;

   endgroup

   function new (string name, uvm_component parent);
      super.new(name, parent);
      cg_axi_lite = new();
   endfunction

   function void write(axi_transaction t);
      cmd = t.get_copy();
      
      // Calculate consecutive identical address accesses
      if(prev_addr == cmd.addr) begin
        consecutive_count += 1;
      end else begin
        consecutive_count = 0;
      end
      prev_addr = cmd.addr;
      
      cg_axi_lite.sample();
   endfunction
endclass
