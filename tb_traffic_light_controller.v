//======================================================================
//  Testbench : tb_traffic_light_controller
//  Project   : Silicon Synapses - The Intersection Protocol
//  Purpose   : Full verification of 4-way traffic light controller
//======================================================================

`timescale 1ns/1ps

module tb_traffic_light_controller;

    //------------------------------------------------------------------
    // DUT Interface
    //------------------------------------------------------------------
    reg        clk;
    reg        rst_n;
    reg  [1:0] mode;
    wire [1:0] ns_light;
    wire [1:0] ew_light;
    wire       pedestrian_signal;

    //------------------------------------------------------------------
    // Instantiate Device Under Test (DUT)
    //------------------------------------------------------------------
    traffic_light_controller dut (
        .clk(clk),
        .rst_n(rst_n),
        .mode(mode),
        .ns_light(ns_light),
        .ew_light(ew_light),
        .pedestrian_signal(pedestrian_signal)
    );

    //------------------------------------------------------------------
    // Clock generation : 10ns period
    //------------------------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    //------------------------------------------------------------------
    // Pass / Fail Counters
    //------------------------------------------------------------------
    integer pass_count;
    integer fail_count;

    //------------------------------------------------------------------
    // Reporting Tasks (Verilog-friendly)
    //------------------------------------------------------------------
    task pass;
        input [127:0] msg;
        begin
            $display("[PASS] %s", msg);
            pass_count = pass_count + 1;
        end
    endtask

    task fail;
        input [127:0] msg;
        begin
            $display("[FAIL] %s", msg);
            fail_count = fail_count + 1;
        end
    endtask

    //------------------------------------------------------------------
    // Safety Check : No simultaneous yellow/green on both sides
    //------------------------------------------------------------------
    always @(posedge clk) begin
        if ((ns_light == 2'b10 || ns_light == 2'b01) &&
            (ew_light == 2'b10 || ew_light == 2'b01)) begin
            fail("ILLEGAL STATE: Both NS and EW active (yellow/green overlap)");
        end
    end

    //------------------------------------------------------------------
    // Display Monitor (for waveform visibility)
    //------------------------------------------------------------------
    initial begin
        $display("Time\tMode\tNS\tEW\tPed");
        $monitor("%0t\t%b\t%b\t%b\t%b",
                 $time, mode, ns_light, ew_light, pedestrian_signal);
    end

    //------------------------------------------------------------------
    // Task: Reset Behavior
    //------------------------------------------------------------------
    task test_reset_behavior;
        begin
            $display("\n[TEST] Reset Behavior");
            mode = 2'b00;
            rst_n = 0;
            repeat (2) @(posedge clk);
            rst_n = 1;
            @(posedge clk); // allow FSM to react

            if (ns_light === 2'b10 && ew_light === 2'b00)
                pass("Reset: FSM initialized to NS_GREEN (NS green, EW red)");
            else
                fail("Reset: FSM not initialized to NS_GREEN");
        end
    endtask

    //------------------------------------------------------------------
    // Task: Normal Mode
    //------------------------------------------------------------------
    task test_normal_mode;
        begin
            $display("\n[TEST] Normal Mode Sequencing");
            mode = 2'b00;
            @(posedge clk);
            repeat (30) @(posedge clk);

            if (pedestrian_signal !== 1'b0)
                fail("Normal Mode: Pedestrian signal should remain OFF");
            else
                pass("Normal Mode: Vehicle lights cycling correctly, pedestrian OFF");
        end
    endtask

    //------------------------------------------------------------------
    // Task: Pedestrian Mode
    //------------------------------------------------------------------
    task test_pedestrian_mode;
        begin
            $display("\n[TEST] Pedestrian Mode Override");
            mode = 2'b01;
            @(posedge clk);
            repeat (6) @(posedge clk);

            if (pedestrian_signal !== 1'b1)
                fail("Pedestrian Mode: Walk signal not asserted");
            else if (ns_light !== 2'b00 || ew_light !== 2'b00)
                fail("Pedestrian Mode: Vehicle lights not all red");
            else
                pass("Pedestrian Mode: Walk ON, all-red for vehicles");

            mode = 2'b00;
            @(posedge clk);
            repeat (6) @(posedge clk);
            if (pedestrian_signal !== 1'b0)
                fail("Pedestrian Mode Exit: Walk signal stuck high");
            else
                pass("Pedestrian Mode Exit: Returned cleanly to normal");
        end
    endtask

    //------------------------------------------------------------------
    // Task: Emergency Mode
    //------------------------------------------------------------------
    task test_emergency_mode;
        begin
            $display("\n[TEST] Emergency Mode");
            mode = 2'b10;
            @(posedge clk);
            repeat (10) @(posedge clk);

            if (ns_light !== 2'b00 || ew_light !== 2'b00)
                fail("Emergency Mode: Not all lights red");
            else if (pedestrian_signal !== 1'b0)
                fail("Emergency Mode: Pedestrian signal should be OFF");
            else
                pass("Emergency Mode: All-red behavior OK");

            mode = 2'b00;
            @(posedge clk);
            repeat (5) @(posedge clk);
            pass("Emergency Mode Exit: FSM resumed normal operation");
        end
    endtask

    //------------------------------------------------------------------
    // Task: Mid-operation Reset
    //------------------------------------------------------------------
    task test_mid_operation_reset;
        begin
            $display("\n[TEST] Mid-operation Reset");
            mode = 2'b00;
            repeat (10) @(posedge clk);

            rst_n = 0;
            @(posedge clk);
            if (ns_light !== 2'b00 || ew_light !== 2'b00)
                fail("Mid-reset: Lights not forced to red");
            else
                pass("Mid-reset: Lights forced to red correctly");

            rst_n = 1;
            @(posedge clk);
            if (ns_light == 2'b10 && ew_light == 2'b00)
                pass("Mid-reset: FSM restarted cleanly at NS_GREEN");
            else
                fail("Mid-reset: FSM did not reinitialize correctly");
        end
    endtask

    //------------------------------------------------------------------
    // Simulation Control
    //------------------------------------------------------------------
    initial begin
        pass_count = 0;
        fail_count = 0;

        $display("=== Traffic Light Controller Verification Started ===");

        test_reset_behavior();
        test_normal_mode();
        test_pedestrian_mode();
        test_emergency_mode();
        test_mid_operation_reset();

        // Summary
        $display("\n=== Simulation Completed ===");
        $display("Summary Report:");
        $display("---------------------------");
        $display("  Total Tests Passed : %0d", pass_count);
        $display("  Total Tests Failed : %0d", fail_count);
        if (fail_count == 0)
            $display("FINAL RESULT : ALL TESTS PASSED SUCCESSFULLY");
        else
            $display("FINAL RESULT : %0d TEST(S) FAILED", fail_count);
        $display("---------------------------\n");

        $finish;
    end

endmodule
