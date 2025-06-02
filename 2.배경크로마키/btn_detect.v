`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/02/05 18:52:52
// Design Name: 
// Module Name: btn_detect
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module btn_detector (
    input  clk,
    input  reset,
    input  btn,
    output rising_edge,
    output falling_edge,
    output both_edge
);
    wire debounce;
    reg tick;
    reg q_reg;
    reg [$clog2(100_000)-1 : 0] counter;
    reg [7:0] shift_reg;

    // clock divider for 1Khz
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter <= 0;
            tick <= 1'b0;
        end else begin
            if (counter == 100_000 - 1) begin
                counter <= 0;
                tick <= 1'b1;
            end else begin
                counter <= counter + 1;
                tick <= 1'b0;
            end
        end
    end

    //shift register with debounce circuit
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            shift_reg <= 0;
        end else begin
            if (tick) begin
                shift_reg <= {btn, shift_reg [7:1]};                
            end else begin
                shift_reg <= shift_reg;
            end
        end
    end

    assign debounce = &shift_reg;

    // d flipflop
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            q_reg <= 0;
        end else begin
            q_reg <= debounce;
        end
    end

    //edge detector
    assign rising_edge = debounce & ~q_reg;
    assign falling_edge = ~debounce & q_reg;
    assign both_edge = rising_edge | falling_edge;

endmodule