`timescale 1ns / 1ps

module top_game_controller (
    input  logic       sw,
    input  logic       clk_25MHZ,
    input  logic       reset,
    input  logic       upscale,
    input  logic       collision_detected,
    output logic [9:0] ball_x_out,
    output logic [9:0] ball_y_out,
    output logic       is_ball_moving_left,
    output logic       is_ball_moving_right,
    input  logic [9:0] estimated_speed,
    input  logic       game_start,
    output logic       game_over,

    //상대 보드에 공 정보 전송 wire
    output logic       ball_send_trigger,
    output logic [7:0] ball_vy,
    output logic [1:0] gravity_counter,
    output logic is_collusion,

    input logic        [7:0] slv_reg0_y0,
    input logic        [7:0] slv_reg1_y1,
    input logic signed [7:0] slv_reg2_Yspeed,
    input logic        [7:0] slv_reg3_gravity,
    input logic        [7:0] slv_reg4_ballspeed,
    input logic        [7:0] slv_reg5_win_flag,

    input logic is_slave_done,
    output logic responsing_i2c,
    output logic [7:0] contrl_led,
    input logic is_i2c_master_done,
    output logic is_you_win
);

    logic [9:0] ball_x_out_for_one, ball_x_out_for_two;
    logic [9:0] ball_y_out_for_one, ball_y_out_for_two;
    logic is_ball_moving_left_for_one, is_ball_moving_left_for_two;
    logic game_over_for_one, game_over_for_two;


    assign ball_x_out = sw ? ball_x_out_for_two : ball_x_out_for_one;
    assign ball_y_out = sw ? ball_y_out_for_two : ball_y_out_for_one;
    assign is_ball_moving_left = sw? is_ball_moving_left_for_two : is_ball_moving_left_for_one;
    assign game_over = sw ? game_over_for_two : game_over_for_one;

    game_controller_for_one U_GAME_CONTROLLER_FOR_ONE (
        .*,
        .ball_x_out(ball_x_out_for_one),
        .ball_y_out(ball_y_out_for_one),
        .is_ball_moving_left(is_ball_moving_left_for_one),
        .game_over(game_over_for_one)
    );
    game_controller_for_two U_GAME_CONTROLLER_FOR_TWO (
        .*,
        .ball_x_out(ball_x_out_for_two),
        .ball_y_out(ball_y_out_for_two),
        .is_ball_moving_left(is_ball_moving_left_for_two),
        .game_over(game_over_for_two)
    );
endmodule
