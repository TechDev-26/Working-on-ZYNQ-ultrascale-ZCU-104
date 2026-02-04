module tb_lcd_controller;

    reg clk = 0;
    reg reset = 1;
    reg UP_DNb = 1;
    
    wire [7:0] lcd_data;
    wire lcd_rs, lcd_en; 
    wire led_UP_DNb;

    always #10 clk = ~clk;   // 50 MHz

    lcd_controller dut (
        .clk(clk),
        .reset(reset),
        .UP_DNb(UP_DNb),
        .lcd_data(lcd_data),
        .lcd_rs(lcd_rs),
        .lcd_en(lcd_en),
        .led_UP_DNb(led_UP_DNb)
    );

    initial begin
        $display("=== LCD TEST START ===");
        #200 reset = 0;

        #5_000_000;
        UP_DNb = 0;
        $display("=== SWITCH TO DOWN ===");

        #5_000_000;
        $display("=== TEST END ===");
        $stop;
    end

    always @(posedge lcd_en) begin
        if (!lcd_rs)
            $display("[%0t] CMD  = 0x%02X", $time, lcd_data);
        else
            $display("[%0t] DATA = '%c'", $time, lcd_data);
    end

endmodule