typedef class command_monitor;
typedef class result_monitor;
typedef class axi_transaction;

interface axi_lite_if #(parameter ADDR_WIDTH=8, DATA_WIDTH=32);
    import axi_test_pkg::*;

    logic                  clk;
    logic                  rst_n;

    //AXI SIGNALS
    logic                  AWVALID;
    logic                  AWREADY;
    logic [ADDR_WIDTH-1:0] AWADDR;

    logic                  WVALID;
    logic                  WREADY;
    logic [DATA_WIDTH-1:0] WDATA;
    logic [3:0]            WSTRB;

    logic                  BREADY;
    logic                  BVALID;

    logic                  ARVALID;
    logic                  ARREADY;
    logic [ADDR_WIDTH-1:0] ARADDR;

    logic                  RVALID;
    logic                  RREADY;
    logic [DATA_WIDTH-1:0] RDATA;
    
    // UVM communication
    command_monitor        command_monitor_h;
    result_monitor         result_monitor_h;

    // For UVM checking only - Expanded to prevent out-of-bounds
    logic [DATA_WIDTH-1:0] dut_mem [(1<<ADDR_WIDTH)-1:0];

    modport Master (
        input  AWREADY, WREADY, BVALID, ARREADY, RVALID, RDATA,
        output AWVALID, AWADDR,
        output WVALID, WDATA, WSTRB, 
        output BREADY, 
        output ARVALID, ARADDR,
        output RREADY
    );
    
    modport Slave (
        input  clk, rst_n,
        output AWREADY, WREADY, BVALID, ARREADY, RVALID, RDATA,
        input  AWVALID, AWADDR,
        input  WVALID, WDATA, WSTRB, 
        input  BREADY, 
        input  ARVALID, ARADDR,
        input  RREADY
    );

   // 1. Clock Generation
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    // 2. Hardware Wake-up Sequence
    initial begin
        rst_n = 0;      // Hold in reset
        #25 rst_n = 1;  // Release reset after 2.5 clock cycles
    end

    // -------------------------
    // AXI-Lite WRITE
    // -------------------------
    task axi_write(input [ADDR_WIDTH-1:0] addr,
                   input [DATA_WIDTH-1:0] data,
                   input [3:0]            strb = 4'hF);
        // 1. Assert Address and Data
        AWADDR  <= addr;
        AWVALID <= 1;
        WDATA   <= data;
        WSTRB   <= strb;
        WVALID  <= 1;
        BREADY  <= 1;

        // 2. Block until Slave accepts BOTH Address and Data
        do begin
            @(posedge clk);
        end while (!(AWREADY && WREADY));

        // 3. Handshake complete -> Safely drop VALID signals
        AWVALID <= 0;
        WVALID  <= 0;

        // 4. Block until Slave pushes the Write Response
        do begin
            @(posedge clk);
        end while (!BVALID);

        // 5. Complete transaction
        BREADY <= 0;
    endtask

    // -------------------------
    // AXI-Lite READ
    // -------------------------
    task axi_read(input [ADDR_WIDTH-1:0] addr);
        // 1. Assert Address
        ARADDR  <= addr;
        ARVALID <= 1;
        RREADY  <= 1;

        // 2. Block until Slave accepts Address
        do begin
            @(posedge clk);
        end while (!ARREADY);

        // 3. Handshake complete -> Drop Address Valid
        ARVALID <= 0;

        // 4. Block until Slave returns Read Data
        do begin
            @(posedge clk);
        end while (!RVALID);

        // 5. Complete transaction
        RREADY <= 0;
    endtask
    
    task reset();
        rst_n = 0;
        #20
        rst_n = 1;
    endtask

    axi_transaction write_buffer[$];
    axi_transaction read_buffer[$];

    task do_op(axi_transaction cmd);
        command_monitor_h.write_to_monitor(cmd);
        
        case (cmd.op)
            w_op: begin
                write_buffer.push_back(cmd);
                axi_write(cmd.addr, cmd.data);
            end
            r_op: begin 
                read_buffer.push_back(cmd);
                axi_read(cmd.addr);
            end
            rst_op: reset();
        endcase
    endtask

    always @(posedge clk) begin : rslt_monitor
        if (RVALID == 1 && RREADY == 1) begin
            if (read_buffer.size() == 0) begin
                `uvm_info("AXI_IF", "READ FAILED DUE TO MISSING BUFFER", UVM_LOW)
            end else begin
                axi_transaction tr = read_buffer.pop_front();
                if (tr != null) begin
                    tr.data = RDATA; 
                    if (result_monitor_h != null) begin
                        result_monitor_h.write_to_monitor(tr);
                    end
                end
            end
        end

        if (BVALID == 1 && BREADY == 1) begin
            if (write_buffer.size() == 0) begin
                `uvm_info("AXI_IF", "WRITE FAILED DUE TO MISSING BUFFER", UVM_LOW)
            end else begin
                axi_transaction tr = write_buffer.pop_front();
                if (tr != null) begin
                    
                    // Safe array access to prevent C++ Segmentation Faults
                    if (tr.addr < (1<<ADDR_WIDTH)) begin
                        tr.data = dut_mem[tr.addr]; 
                    end else begin
                        tr.data = 32'hDEADBEEF; // Indicates out-of-bounds access
                    end

                    if (result_monitor_h != null) begin
                        result_monitor_h.write_to_monitor(tr);
                    end
                end
            end
        end
    end
endinterface
