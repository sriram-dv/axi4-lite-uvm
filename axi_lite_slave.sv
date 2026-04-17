`timescale 1ns / 1ps

module axi_lite_slave #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32
)(
    axi_lite_if.Slave slave_if,
    output reg [DATA_WIDTH-1:0] dut_mem [(1<<ADDR_WIDTH)-1:0] 
);
    reg [DATA_WIDTH-1:0] mem [(1<<ADDR_WIDTH)-1:0]; 
    
    //-----------------------------------------
    // 1. Write Channel Logic
    //-----------------------------------------
    logic aw_en;
    
    // AWREADY & WREADY generation
    always_ff @(posedge slave_if.clk) begin
        if (!slave_if.rst_n) begin
            slave_if.AWREADY <= 1'b0;
            slave_if.WREADY  <= 1'b0;
            aw_en            <= 1'b1;
        end else begin
            // Accept Address
            if (~slave_if.AWREADY && slave_if.AWVALID && slave_if.WVALID && aw_en) begin
                slave_if.AWREADY <= 1'b1;
                slave_if.WREADY  <= 1'b1;
                aw_en            <= 1'b0;
            end else if (slave_if.BREADY && slave_if.BVALID) begin
                aw_en            <= 1'b1;
                slave_if.AWREADY <= 1'b0;
                slave_if.WREADY  <= 1'b0;
            end else begin
                slave_if.AWREADY <= 1'b0;
                slave_if.WREADY  <= 1'b0;
            end
        end
    end

    // Memory Write & BVALID Generation
    always_ff @(posedge slave_if.clk) begin
        if (!slave_if.rst_n) begin
            slave_if.BVALID <= 1'b0;
        end else begin
            if (slave_if.AWREADY && slave_if.AWVALID && slave_if.WREADY && slave_if.WVALID) begin
                // Write to memory using strobes
                if (slave_if.WSTRB[0]) mem[slave_if.AWADDR][7:0]   <= slave_if.WDATA[7:0];
                if (slave_if.WSTRB[1]) mem[slave_if.AWADDR][15:8]  <= slave_if.WDATA[15:8];
                if (slave_if.WSTRB[2]) mem[slave_if.AWADDR][23:16] <= slave_if.WDATA[23:16];
                if (slave_if.WSTRB[3]) mem[slave_if.AWADDR][31:24] <= slave_if.WDATA[31:24];
                
                slave_if.BVALID <= 1'b1; // Assert Response
            end else if (slave_if.BVALID && slave_if.BREADY) begin
                slave_if.BVALID <= 1'b0; // Clear Response after handshake
            end
        end
    end

    //-----------------------------------------
    // 2. Read Channel Logic
    //-----------------------------------------
    logic [ADDR_WIDTH-1:0] read_addr;

    // ARREADY generation
    always_ff @(posedge slave_if.clk) begin
        if (!slave_if.rst_n) begin
            slave_if.ARREADY <= 1'b0;
            read_addr        <= '0;
        end else begin
            if (~slave_if.ARREADY && slave_if.ARVALID) begin
                slave_if.ARREADY <= 1'b1;
                read_addr        <= slave_if.ARADDR; // Latch address
            end else begin
                slave_if.ARREADY <= 1'b0;
            end
        end
    end

    // RVALID & RDATA generation
    always_ff @(posedge slave_if.clk) begin
        if (!slave_if.rst_n) begin
            slave_if.RVALID <= 1'b0;
            slave_if.RDATA  <= '0;
        end else begin
            if (slave_if.ARREADY && slave_if.ARVALID && ~slave_if.RVALID) begin
                slave_if.RVALID <= 1'b1;
                slave_if.RDATA  <= mem[read_addr]; // Output data
            end else if (slave_if.RVALID && slave_if.RREADY) begin
                slave_if.RVALID <= 1'b0;
            end
        end
    end

    // Output dut_mem for UVM (Continuous Assignment)
    always_comb begin
        dut_mem = mem;
    end

endmodule
