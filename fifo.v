//---------------------------------------------
// BUGGY FIFO DESIGN - For Debugging Practice
//---------------------------------------------
module fifo (
    input  wire        clock,
    input  wire        resetn,
    input  wire        write_enb,
    input  wire        read_enb,
    input  wire [7:0]  data_in,
    output reg  [7:0]  data_out,
    output reg         full,
    output reg         empty
);
    parameter DEPTH = 4;
    parameter ADDR_WIDTH = 2; // log2(DEPTH)

    reg [7:0] mem [0:DEPTH-1];
    reg [ADDR_WIDTH:0] wr_ptr, rd_ptr;  // MSB for wrap tracking

    wire full_next  = (wr_ptr[ADDR_WIDTH-1:0] == rd_ptr[ADDR_WIDTH-1:0]);
    wire empty_next = (wr_ptr == rd_ptr);

    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            wr_ptr   <= 0;
            rd_ptr   <= 0;
            full     <= 1'b0;
            empty    <= 1'b1;
            data_out <= 8'h00;
        end else begin
            if (write_enb)
                mem[wr_ptr[ADDR_WIDTH-1:0]] <= data_in;
            if (read_enb)
                data_out <= mem[rd_ptr[ADDR_WIDTH-1:0]];
            if (write_enb)
                wr_ptr <= wr_ptr + 1;
            if (read_enb)
                rd_ptr <= rd_ptr + 1;

            full  <= full_next;
            empty <= empty_next;
        end
    end
endmodule