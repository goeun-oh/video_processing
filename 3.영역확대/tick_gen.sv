`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/25 09:32:05
// Design Name: 
// Module Name: tick_gen
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


module tick_gen #(
    parameter TICK_HZ = 100_000_000
)(
    input logic clk,
    input logic reset,
    output logic tick
);

    reg [$clog2(TICK_HZ) -1 : 0] r_cnt;
    reg r_tick;

    assign tick = r_tick;

    always_ff @ (posedge clk, posedge reset) begin
        if(reset) begin
            r_cnt <= 0;
            r_tick <= 0;
        end
        else begin
            if(r_cnt == TICK_HZ -1) begin
                r_cnt <= 0;
                r_tick <= 1;
            end
            else begin
                r_cnt <= r_cnt +1;
                r_tick <= 0;
            end
        end

    end

endmodule
