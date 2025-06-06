`timescale 1ns / 1ps

module ball_send_controller (
    input  logic       clk,
    input  logic       reset,
    input  logic       ball_send_trigger,
    input  logic       is_transfer,
    input  logic [9:0] i_ball_y,
    input  logic [7:0] i_ball_vy,
    output logic [9:0] o_ball_y,
    output logic [7:0] o_ball_vy
);

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            o_ball_y  <= 0;
            o_ball_vy <= 0;
        end else if (ball_send_trigger && !is_transfer) begin
            o_ball_y  <= i_ball_y;
            o_ball_vy <= i_ball_vy;
        end
    end

endmodule
