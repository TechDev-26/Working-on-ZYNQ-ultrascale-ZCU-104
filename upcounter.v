`timescale 1ns / 1ps
module Upcounter(
    input clk,           // clock input
    input reset,         // reset button
    input up_down,       // 1 = count up, 0 = count down
    output reg [6:0] seg, // 7-segment display segments (a-g)
    output reg [3:0] an   // anode control (for 4 displays)
);

    reg [25:0] slow_clk = 0;
    reg [3:0] counter = 0;

    // Slow down the clock so digits change visibly
    always @(posedge clk) begin
        if (reset) begin
            slow_clk <= 0;
            counter <= 0;
        end else begin
            slow_clk <= slow_clk + 1;
            if (slow_clk == 26'd0) begin
                if (up_down)
                    counter <= (counter == 4'd15) ? 4'd0 : counter + 1; // Up count 0→15
                else
                    counter <= (counter == 4'd0) ? 4'd15 : counter - 1; // Down count 15→0
            end
        end
    end

    // 7-segment decoder (active low)
    always @(*) begin
        case (counter)
            4'd0:  seg = 7'b1000000; // 0
            4'd1:  seg = 7'b1111001; // 1
            4'd2:  seg = 7'b0100100; // 2
            4'd3:  seg = 7'b0110000; // 3
            4'd4:  seg = 7'b0011001; // 4
            4'd5:  seg = 7'b0010010; // 5
            4'd6:  seg = 7'b0000010; // 6
            4'd7:  seg = 7'b1111000; // 7
            4'd8:  seg = 7'b0000000; // 8
            4'd9:  seg = 7'b0010000; // 9
            4'd10: seg = 7'b0001000; // A
            4'd11: seg = 7'b0000011; // b
            4'd12: seg = 7'b1000110; // C
            4'd13: seg = 7'b0100001; // d
            4'd14: seg = 7'b0000110; // E
            4'd15: seg = 7'b0001110; // F
            default: seg = 7'b1111111; // off
        endcase
    end

    // Enable only one display (rightmost)
    always @(*) begin
        an = 4'b1110; // active low: only the rightmost display ON
    end

endmodule


module Upcounter_tb;

    reg clk;
    reg reset;
    wire [3:0] counter;

    // Instantiate the DUT (Device Under Test)
    Upcounter uut (
        .clk(clk),
        .reset(reset),
        .counter(counter)
    );

    // Clock generation: 10ns period = 100MHz clock
    initial clk = 0;
    always #5 clk = ~clk;  // toggle every 5ns

    // Test sequence
    initial begin
        // Initialize
        reset = 1;
        #20;
        reset = 0;

        // Run simulation for some time
        #20000;  // run long enough to see changes
        $stop;
    end

    // Monitor values
    initial begin
        $monitor("Time=%0t | reset=%b | counter=%b", $time, reset, counter);
    end
