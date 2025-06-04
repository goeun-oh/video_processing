`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/25 14:20:21
// Design Name: 
// Module Name: btn_debounce
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

module btn_debounce #(
    parameter COUNT = 100_000
) (
    input  clk,
    input  reset,
    input  i_btn,
    output o_rising_edge,
    output o_falling_edge,
    output o_both_edge
);

    reg [$clog2(COUNT)-1:0] r_debounce_cnt;
    reg r_debounce_tick;
    reg [3:0] r_shift_reg;
    reg r_ff;
    wire w_debounce;

    //clk gen for shift register
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_debounce_tick <= 0;
            r_debounce_cnt  <= 0;
        end else begin
            if (r_debounce_cnt == COUNT) begin
                r_debounce_cnt  <= 0;
                r_debounce_tick <= 1'b1;
            end else begin
                r_debounce_cnt  <= r_debounce_cnt + 1;
                r_debounce_tick <= 1'b0;
            end
        end
    end

    //sequential logic for shift register
    always @(posedge r_debounce_tick, posedge reset) begin
        if (reset) begin
            r_shift_reg <= 0;
        end else begin
            r_shift_reg <= {
                i_btn, r_shift_reg[3:1]
            };  //shift left for 4 r_debounce_tick
        end
    end

    assign w_debounce = &r_shift_reg;

    //filtering AND gate
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            r_ff <= 0;
        end else begin
            r_ff <= w_debounce;
        end
    end

    assign o_rising_edge = w_debounce & ~r_ff;
    assign o_falling_edge = ~w_debounce & r_ff;
    assign o_both_edge = o_rising_edge | o_falling_edge;

endmodule
