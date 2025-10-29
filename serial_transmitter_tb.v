`timescale 1ns/1ps

module serial_transmitter_tb;

    reg clk, rst_n, start;
    reg [7:0] data_in;
    wire serial_out, busy, done;

    serial_transmitter_fixed dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .data_in(data_in),
        .serial_out(serial_out),
        .busy(busy),
        .done(done)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    integer pass_count = 0;
    integer total_tests = 0;

    // Procedure to send a byte
    task send_byte(input [7:0] d);
        begin
            data_in = d;
            start = 1; #10; start = 0;
            wait(done);
            #10;
        end
    endtask

    // Test control
    initial begin
        $dumpfile("serial_tx.vcd");
        $dumpvars(0, serial_transmitter_tb);

        rst_n = 0; start = 0; data_in = 8'h00;
        #20; rst_n = 1; #10;

        $display("=== TESTCASE: SERIAL TRANSMITTER ===");

        total_tests = total_tests + 1;
        send_byte(8'hA5);  // 1st transmission
        if (done === 1'b1) begin
            $display("\033[32m[PASS]\033[0m Done asserted in 1st transmission");
            pass_count = pass_count + 1;
        end else
            $display("\033[31m[FAIL]\033[0m Done not asserted properly in 1st transmission");

        total_tests = total_tests + 1;
        send_byte(8'h3C);  // 2nd transmission
        if (done === 1'b1) begin
            $display("\033[32m[PASS]\033[0m Done asserted in 2nd transmission");
            pass_count = pass_count + 1;
        end else
            $display("\033[31m[FAIL]\033[0m Done not asserted properly in 2nd transmission");

        total_tests = total_tests + 1;
        if (busy === 1'b0) begin
            $display("\033[32m[PASS]\033[0m Busy flag cleared correctly");
            pass_count = pass_count + 1;
        end else
            $display("\033[31m[FAIL]\033[0m Busy flag not cleared after completion");

        total_tests = total_tests + 1;
        if (serial_out === 1'b1) begin
            $display("\033[32m[PASS]\033[0m Line returned to idle after transmission");
            pass_count = pass_count + 1;
        end else
            $display("\033[31m[FAIL]\033[0m Line did not return to idle");

        #20;
        $display("\n=== TEST SUMMARY ===");
        $display("Total Tests : %0d", total_tests);
        $display("Tests Passed: %0d", pass_count);

        if (pass_count == total_tests)
            $display("\033[32mFINAL RESULT : ALL TESTS PASSED ✅\033[0m");
        else
            $display("\033[31mFINAL RESULT : %0d TEST(S) FAILED ❌\033[0m", total_tests - pass_count);

        #20;
        $finish;
    end
endmodule
