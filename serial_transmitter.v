//==============================================================================
// Module: serial_transmitter (BUGGY VERSION)
// Description: 8-bit parallel-to-serial transmitter with start bit (0)
//
// Bugs:
//   1. Start bit sometimes missed on 2nd transmission
//   2. bit_count not reset between transmissions
//   3. done signal stays high for too long
//   4. Missing semicolon in DONE state
//==============================================================================

module serial_transmitter (
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire [7:0] data_in,
    output reg serial_out,
    output reg busy,
    output reg done
);

    // FSM States
    localparam IDLE  = 2'b00,
               START = 2'b01,
               DATA  = 2'b10,
               DONE  = 2'b11;

    reg [1:0] state, next_state;
    reg [7:0] shift_reg;
    reg [2:0] bit_count;

    // FSM sequential
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    // FSM next-state logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE:  if (start) next_state = START;
            START: next_state = DATA;
            DATA:  if (bit_count == 3'b111) next_state = DONE;
            DONE:  next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // Datapath + outputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            serial_out <= 1'b1;
            busy <= 1'b0;
            done <= 1'b0;
            bit_count <= 3'b000;
            shift_reg <= 8'h00;
        end else begin
            case (state)
                IDLE: begin
                    busy <= 1'b0;
                    if (start) begin
                        shift_reg <= data_in;
                        busy <= 1'b1;
                    end
                end

                START: begin
                    serial_out <= 1'b0; // start bit
                    busy <= 1'b1;
                end

                DATA: begin
                    serial_out <= shift_reg[0];
                    shift_reg <= shift_reg >> 1;
                    bit_count <= bit_count + 1;
                end

                DONE: begin
                    serial_out <= 1'b1;
                    done <= 1'b1;
                    busy <= 1'b0;
                end
            endcase
        end
    end
endmodule
