module fifo #(
    parameter DEPTH = 256,    // FIFO depth (default 16)
    parameter ADDR_WIDTH = $clog2(DEPTH)  // Address width calculated from depth
)(
    input wire clk,
    input wire reset,
    input wire wr_en,        // Write enable
    input wire [7:0] data_in, // 8-bit input data
    input wire rd_en,        // Read enable
    output wire [7:0] data_out, // 8-bit output data
    output wire full,        // FIFO full flag
    output wire empty,       // FIFO empty flag
    output wire [ADDR_WIDTH:0] count // Current number of items in FIFO
);

    // Memory array
    reg [7:0] mem [0:DEPTH-1];
    
    // Pointers
    reg [ADDR_WIDTH-1:0] wr_ptr;
    reg [ADDR_WIDTH-1:0] rd_ptr;
    
    // Counter
    reg [ADDR_WIDTH:0] count_reg;
    
    // Data out register
    reg [7:0] data_out_reg;
    
    // Assign outputs
    assign data_out = data_out_reg;
    assign full = (count_reg == DEPTH);
    assign empty = (count_reg == 0);
    assign count = count_reg;
    
    // FIFO write operation
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            wr_ptr <= 0;
        end
        else if (wr_en && !full) begin
            mem[wr_ptr] <= data_in;
            wr_ptr <= wr_ptr + 1;
        end
    end
    
    // FIFO read operation
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            rd_ptr <= 0;
            data_out_reg <= 0;
        end
        else if (rd_en && !empty) begin
            data_out_reg <= mem[rd_ptr];
            rd_ptr <= rd_ptr + 1;
        end
    end
    
    // Update count
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            count_reg <= 0;
        end
        else begin
            case ({wr_en, rd_en})
                2'b01: if (!empty) count_reg <= count_reg - 1; // Read only
                2'b10: if (!full)  count_reg <= count_reg + 1; // Write only
                2'b11: begin // Both read and write (count stays same)
                    if (empty) // Can't read if empty, but can write
                        count_reg <= count_reg + 1;
                    else if (full) // Can't write if full, but can read
                        count_reg <= count_reg - 1;
                    // else count stays same
                end
                default: count_reg <= count_reg; // No change
            endcase
        end
    end
    
endmodule