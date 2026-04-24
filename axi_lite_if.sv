typedef class command_monitor;
typedef class axi_transaction;

interface axi_lite_if #(parameter ADDR_WIDTH=8, DATA_WIDTH=32);
    import axi_test_pkg::*;
    
    logic                  clk;
    logic                  rst_n;
    
    // AXI SIGNALS
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
    
    logic [DATA_WIDTH-1:0] dut_mem [(1<<ADDR_WIDTH)-1:0];

    modport Master (
        input  AWREADY, WREADY, BVALID, ARREADY, RVALID, RDATA,
        output AWVALID, AWADDR, WVALID, WDATA, WSTRB, BREADY, ARVALID, ARADDR, RREADY
    );

    modport Slave (
        input  clk, rst_n, AWVALID, AWADDR, WVALID, WDATA, WSTRB, BREADY, ARVALID, ARADDR, RREADY,
        output AWREADY, WREADY, BVALID, ARREADY, RVALID, RDATA
    );

    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    initial begin
        rst_n = 0;
        #25 rst_n = 1;
    end

    task axi_write(input [ADDR_WIDTH-1:0] addr, input [DATA_WIDTH-1:0] data, input [3:0] strb = 4'hF);
        AWADDR  <= addr;
        AWVALID <= 1;
        WDATA   <= data;
        WSTRB   <= strb;
        WVALID  <= 1;
        BREADY  <= 1;
        do begin @(posedge clk); end while (!(AWREADY && WREADY));
        AWVALID <= 0;
        WVALID  <= 0;
        do begin @(posedge clk); end while (!BVALID);
        BREADY <= 0;
    endtask

    task axi_read(input [ADDR_WIDTH-1:0] addr);
        ARADDR  <= addr;
        ARVALID <= 1;
        RREADY  <= 1;
        do begin @(posedge clk); end while (!ARREADY);
        ARVALID <= 0;
        do begin @(posedge clk); end while (!RVALID);
        RREADY <= 0;
    endtask
    
    task reset();
        rst_n = 0;
        #20 rst_n = 1;
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
endinterface
