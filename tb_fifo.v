`timescale 1ns/1ps

module tb_fifo_fixed;

    // DUT I/O
    reg         clock;
    reg         resetn;
    reg         write_enb, read_enb;
    reg  [7:0]  data_in;
    wire [7:0]  data_out;
    wire        full, empty;

    // Clock generation (10ns period)
    always #5 clock = ~clock;

    // Instantiate FIFO DUT
    fifo dut (
        .clock(clock),
        .resetn(resetn),
        .write_enb(write_enb),
        .read_enb(read_enb),
        .data_in(data_in),
        .data_out(data_out),
        .full(full),
        .empty(empty)
    );

    // Task for printing signal status
    task print_status;
        $display("Time=%0t | write=%0b read=%0b | data_in=0x%0h data_out=0x%0h | full=%0b empty=%0b",
                 $time, write_enb, read_enb, data_in, data_out, full, empty);
    endtask

    initial begin
        $display("==============================================");
        $display("          FIFO FUNCTIONAL TEST START          ");
        $display("==============================================\n");

        clock = 0;
        resetn = 0;
        write_enb = 0;
        read_enb  = 0;
        data_in   = 8'h00;

        // Reset sequence
        @(posedge clock);
        @(posedge clock);
        resetn = 1;
        @(posedge clock);
        print_status();

        if (empty && !full)
            $display("[PASS] FIFO reset correctly. Empty=1, Full=0\n");
        else
            $display("[FAIL] FIFO reset failed.\n");

        // ==========================================================
        // TEST 2: Write until FULL
        // ==========================================================
        $display("[TEST 2] Writing data until FIFO becomes FULL...");
        write_enb = 1;

        data_in = 8'h24; @(posedge clock); #1; print_status();
        data_in = 8'h81; @(posedge clock); #1; print_status();
        data_in = 8'h09; @(posedge clock); #1; print_status();
        data_in = 8'h63; @(posedge clock); #1; print_status();

        if (full)
            $display("[PASS] FIFO full condition detected correctly.\n");
        else
            $display("[FAIL] FIFO full condition failed.\n");

        // ==========================================================
        // TEST 3: Write when FULL
        // ==========================================================
        $display("[TEST 3] Trying to write when FIFO is FULL...");
        data_in = 8'haa; @(posedge clock); #1; print_status();

        if (full)
            $display("[PASS] Extra write ignored correctly when FULL.\n");
        else
            $display("[FAIL] FIFO allowed write when FULL.\n");

        // ==========================================================
        // TEST 4: Read until EMPTY
        // ==========================================================
        $display("[TEST 4] Reading all data until FIFO becomes EMPTY...");
        write_enb = 0;
        read_enb  = 1;

        repeat (4) begin
            @(posedge clock); #1; print_status();
        end

        if (empty)
            $display("[PASS] FIFO empty condition detected correctly.\n");
        else
            $display("[FAIL] FIFO empty condition failed.\n");

        // ==========================================================
        // TEST 5: Read when EMPTY
        // ==========================================================
        $display("[TEST 5] Trying to read when FIFO is EMPTY...");
        @(posedge clock); #1; print_status();

        if (empty)
            $display("[PASS] Extra read ignored correctly when EMPTY.\n");
        else
            $display("[FAIL] FIFO read incorrectly when EMPTY.\n");

        // ==========================================================
        // TEST 6: Simultaneous READ & WRITE
        // ==========================================================
        $display("[TEST 6] Simultaneous READ and WRITE operations...");
        read_enb  = 1;
        write_enb = 1;

        data_in = 8'h0d; @(posedge clock); #1; print_status();
        data_in = 8'h8d; @(posedge clock); #1; print_status();
        data_in = 8'h65; @(posedge clock); #1; print_status();
        data_in = 8'h12; @(posedge clock); #1; print_status();
        $display("[INFO] Simultaneous read/write completed.\n");

        // ==========================================================
        // TEST 7: Final state check
        // ==========================================================
        write_enb = 0;
        read_enb  = 0;
        @(posedge clock); #1; print_status();

        if (!full && !empty)
            $display("[PASS] FIFO in intermediate valid state.\n");
        else
            $display("[FAIL] FIFO state invalid at end.\n");

        $display("==============================================");
        $display("          FIFO FUNCTIONAL TEST END            ");
        $display("==============================================");
        $finish;
    end
endmodule