
    module seven(
    input [1:0] lsb,
    input clk,
    input reset,
    input UP_DNb,
    output reg led_UP_DNb,
    output reg [7:0] seg,
    output reg [3:0] an,
    output led_lsb0,           // LED for lsb[0]
    output led_lsb1           // LED for lsb[1]
        );
    reg [25:0] highfreq_counter;
    reg slow_clk;
    reg [3:0] count;

    always @(posedge clk or posedge reset) begin
        if (reset)
            led_UP_DNb <= 0;
        else
            led_UP_DNb <= UP_DNb;
    end

    //////////////// Counter ////////////////////////
    always @(posedge slow_clk or posedge(reset) )
    begin
        if (reset)
            count <= 4'd0;
         else
         begin
            case (lsb)
                2'd0: count <= (UP_DNb)? count + 2'd1: count - 2'd1;
                2'd1: count <= (UP_DNb)? count + 2'd2: count - 2'd2;
                2'd2: count <= (UP_DNb)? count + 2'd3: count - 2'd3;
                2'd3: count <= (UP_DNb)? count + 3'd4: count - 3'd4;
                default: count <= count;
             endcase
         end
    end

    ///////////////////////////////////////////////////

    // Directly assign LEDs for LSB
    assign led_lsb0 = lsb[0];
    assign led_lsb1 = lsb[1];


    /////// Generate slow clock///////////////////////
    always @ (posedge (clk) or posedge (reset))
    begin
        if (reset)
            slow_clk <= 0;
         else
         begin
           if (highfreq_counter<= 26'd25_000_000)
               slow_clk <= 0;
            else
                slow_clk <= 1;
    end
    end


    ///////////////////////////////////////////////////

    always @(posedge(clk) or posedge (reset))
    begin
        if (reset)
            highfreq_counter <= 26'd0;
        else
        begin
            if(highfreq_counter == 26'd50_000_000)
                highfreq_counter <= 26'd0;
             else
                highfreq_counter <= highfreq_counter + 1'd1;
        end
    end

    ///////////////////////////////////////////////////

    reg [15:0] mux_cnt;

    always @(posedge clk or posedge reset) begin
        if (reset)
            mux_cnt <= 0;
        else
            mux_cnt <= mux_cnt + 1;
    end

    ///////////////////////////////////////////////////

    reg [1:0] sel_display;
    always @(posedge clk or posedge reset) begin
        if (reset)
            sel_display <= 2'd0;
        else
            sel_display <= mux_cnt[15:14];  // <<< SLOW multiplexing
    end

    ///////////////////////////////////////////////////

    always @(*) begin
        if (reset) begin
            an  = 4'b1111;          // enable ALL digits
            seg = 8'b1100_0000;     // display '0'
        end
        else begin
            case (sel_display)
                2'd0: begin
                    an = 4'b1000;
                    seg = (count[0]) ? 8'b1111_1001 : 8'b1100_0000;
                end
                2'd1: begin
                    an = 4'b0100;
                    seg = (count[1]) ? 8'b1111_1001 : 8'b1100_0000;
                end
                2'd2: begin
                    an = 4'b0010;
                    seg = (count[2]) ? 8'b1111_1001 : 8'b1100_0000;
                end
                2'd3: begin
                    an = 4'b0001;
                    seg = (count[3]) ? 8'b1111_1001 : 8'b1100_0000;
                end
                default: begin
                    an  = 4'b1111;
                    seg = 8'b1111_1001;
                end
            endcase
        end
    end


    endmodule
    ///////////////////////////////////////////////////

#=====================================================
# Clock
#=====================================================
set_property -dict { PACKAGE_PIN H11 IOSTANDARD LVCMOS33 } [get_ports clk]
create_clock -period 20.000 -name sys_clk [get_ports clk]

#=====================================================
# 7-segment anodes
#=====================================================
set_property -dict { PACKAGE_PIN H4 IOSTANDARD LVCMOS33 } [get_ports {an[0]}]
set_property -dict { PACKAGE_PIN H3 IOSTANDARD LVCMOS33 } [get_ports {an[1]}]
set_property -dict { PACKAGE_PIN H2 IOSTANDARD LVCMOS33 } [get_ports {an[2]}]
set_property -dict { PACKAGE_PIN H1 IOSTANDARD LVCMOS33 } [get_ports {an[3]}]

#=====================================================
# 7-segment segments
#=====================================================
set_property -dict { PACKAGE_PIN L3 IOSTANDARD LVCMOS33 } [get_ports {seg[0]}]  ;# A
set_property -dict { PACKAGE_PIN P4 IOSTANDARD LVCMOS33 } [get_ports {seg[1]}]  ;# B
set_property -dict { PACKAGE_PIN P2 IOSTANDARD LVCMOS33 } [get_ports {seg[2]}]  ;# C
set_property -dict { PACKAGE_PIN M3 IOSTANDARD LVCMOS33 } [get_ports {seg[3]}]  ;# D
set_property -dict { PACKAGE_PIN M1 IOSTANDARD LVCMOS33 } [get_ports {seg[4]}]  ;# E
set_property -dict { PACKAGE_PIN J4 IOSTANDARD LVCMOS33 } [get_ports {seg[5]}]  ;# F
set_property -dict { PACKAGE_PIN K4 IOSTANDARD LVCMOS33 } [get_ports {seg[6]}]  ;# G
set_property -dict { PACKAGE_PIN J2 IOSTANDARD LVCMOS33 } [get_ports {seg[7]}]  ;# DP

#=====================================================
# LEDs
#=====================================================
set_property -dict { PACKAGE_PIN K12 IOSTANDARD LVCMOS33 } [get_ports led_lsb0]
set_property -dict { PACKAGE_PIN M12 IOSTANDARD LVCMOS33 } [get_ports led_lsb1]
set_property -dict { PACKAGE_PIN M14 IOSTANDARD LVCMOS33 } [get_ports led_UP_DNb]

#=====================================================
# LSB switches
#=====================================================
set_property -dict { PACKAGE_PIN K11 IOSTANDARD LVCMOS33 } [get_ports {lsb[0]}]
set_property -dict { PACKAGE_PIN M11 IOSTANDARD LVCMOS33 } [get_ports {lsb[1]}]

#=====================================================
# UP/DOWN switch
#=====================================================
set_property -dict { PACKAGE_PIN N14 IOSTANDARD LVCMOS33 } [get_ports UP_DNb]

#=====================================================
# Reset button
#=====================================================
set_property -dict { PACKAGE_PIN J13 IOSTANDARD LVCMOS33 PULLDOWN true } [get_ports reset]
