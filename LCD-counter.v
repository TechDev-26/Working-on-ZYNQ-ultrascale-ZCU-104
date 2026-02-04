
module lcd_controller (
    input  clk,              // 50 MHz clock
    input  reset,            // Reset
    input [1:0] lsb, 
     input UP_DNb, 
    output reg [7:0] lcd_data,
    output reg lcd_rs,
    output reg lcd_en,
    output reg led_UP_DNb
);




    // FSM states
    localparam PWR_DELAY  = 3'd0,
           INIT_SEND  = 3'd1,
           INIT_WAIT  = 3'd2,
           DATA_SEND  = 3'd3,
           DATA_WAIT  = 3'd4,
           IDLE       = 3'd5,
           CLEAR_SEND = 3'd6,
           CLEAR_WAIT = 3'd7;
            reg [2:0]  state;
            reg [2:0]  init_index;
            reg [19:0] delay_cnt;
            reg [3:0] char_index; // 0-7
            reg [25:0] highfreq_counter;


    // LCD init commands
    reg [7:0] init_rom [0:3];
        initial begin
        init_rom[0] = 8'h38;
        init_rom[1] = 8'h0C;
        init_rom[2] = 8'h06;
        init_rom[3] = 8'h01;
    end
    
        
reg [25:0] clk_div;
reg [7:0]  counter;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        clk_div <= 0;
        counter <= 8'b0000_0000;
    end else begin
        if (clk_div == 50_000_000 - 1) begin
            clk_div <= 0;
           if (UP_DNb)
                counter <= counter + 1;
            else
                counter <= counter - 1;
        end else
            clk_div <= clk_div + 1;
    end
end

   
    
    reg [7:0] msg [0:7];
  
    always @(*) begin
        msg[0] = bit_to_ascii(counter[7]);
        msg[1] = bit_to_ascii(counter[6]);
        msg[2] = bit_to_ascii(counter[5]);
        msg[3] = bit_to_ascii(counter[4]);
        msg[4] = bit_to_ascii(counter[3]);
        msg[5] = bit_to_ascii(counter[2]);
        msg[6] = bit_to_ascii(counter[1]);
        msg[7] = bit_to_ascii(counter[0]);
    end

//always @(*) begin
//    msg[0] = "0";
//    msg[1] = "0";
//    msg[2] = "0";
//    msg[3] = "0";
//    msg[4] = "0";
//    msg[5] = "0";
//    msg[6] = "0";
//    msg[7] = "1";
//end

    wire at_max = (counter == 8'b1111_1111);
    function [7:0] bit_to_ascii;
        input bit_val;
        begin
            bit_to_ascii = bit_val ? 8'h31 : 8'h30; // '1' : '0'
        end
    endfunction
    
    
    //  switch to LED
    always @(posedge clk or posedge reset) begin
        if (reset)
            led_UP_DNb <= 1'b0;
        else
            led_UP_DNb <= UP_DNb;
    end
    
    reg counter_tick;
    
    always @(posedge clk or posedge reset) begin
        if (reset)
            counter_tick <= 0;
        else if (clk_div == 50_000_000 - 1)
            counter_tick <= 1;
        else
            counter_tick <= 0;
    end
    
        // LCD FSM
        always @(posedge clk or posedge reset) begin
            if (reset) begin
                state      <= PWR_DELAY;
                delay_cnt  <= 0;
                init_index <= 0;
                char_index <= 0;
                lcd_en     <= 0;
                lcd_rs     <= 0;
            end else begin
            case (state)

                PWR_DELAY: begin
                    if (delay_cnt < 1_000_000)
                        delay_cnt <= delay_cnt + 1;
                    else begin
                        delay_cnt <= 0;
                        state <= INIT_SEND;
                    end
                end

                INIT_SEND: begin
                    lcd_rs   <= 0;
                    lcd_data <= init_rom[init_index];
                    lcd_en   <= 1;
                    state    <= INIT_WAIT;
                end

                INIT_WAIT: begin
                    lcd_en <= 0;
                    if (delay_cnt < 100_000)
                        delay_cnt <= delay_cnt + 1;
                    else begin
                        delay_cnt <= 0;
                        if (init_index < 3) begin
                            init_index <= init_index + 1;
                            state <= INIT_SEND;
                        end else begin
                            init_index <= 0;
                            char_index <= 0;
                            state <= DATA_SEND;
                        end
                    end
                end

                DATA_SEND: begin
                    lcd_rs   <= 1;
                    lcd_data <= msg[char_index];
                    lcd_en   <= 1;
                    state    <= DATA_WAIT;
                end

                DATA_WAIT: begin
                    lcd_en <= 0;
                    if (delay_cnt < 50_000)
                        delay_cnt <= delay_cnt + 1;
                    else begin
                        delay_cnt <= 0;
                           if (char_index < 7) begin
                              char_index <= char_index + 1;
                                state <= DATA_SEND;
                             end else
                                state <= IDLE;

                    end
                end
            
                    IDLE:begin
                        lcd_en <= 0;
                        if (counter_tick) 
                        begin
                            state <= CLEAR_SEND;
                          end
                        end
                    CLEAR_SEND: begin
                            lcd_rs   <= 0;
                            lcd_data <= 8'h01;   // clear display
                            lcd_en   <= 1;
                            delay_cnt <= 0;  
                            state    <= CLEAR_WAIT;
                        end
                        
                    CLEAR_WAIT: begin
                        lcd_en <= 0;
                        if (delay_cnt < 100_000)  // clear needs longer delay
                            delay_cnt <= delay_cnt + 1;
                        else begin
                            delay_cnt <= 0;
                            char_index <= 0;
                            state <= DATA_SEND;
                        end
                      end
                default: begin
                state      <= PWR_DELAY;
                delay_cnt  <= 0;
                init_index <= 0;
                char_index <= 0;
                lcd_en     <= 0;
                lcd_rs     <= 0;
            end
            endcase
        end
    end
endmodule