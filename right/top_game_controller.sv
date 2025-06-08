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
    input  logic [9:0] estimated_speed,
    input  logic       game_start,
    output logic       game_over,

    //상대 보드에 공 정보 전송 wire
    output logic       ball_send_trigger,
    output logic [7:0] ball_vy,
    output logic [1:0] gravity_counter,

    output logic [7:0] ball_speed_reg0,
    output logic [7:0] ball_speed_reg1,
    output logic [3:0] ball_speed_reg2,

    // p2
    input logic        [7:0] slv_reg0_y0_pl,
    input logic        [7:0] slv_reg1_y1_pl,
    input logic signed [7:0] slv_reg2_Yspeed_pl,
    input logic        [7:0] slv_reg3_gravity_pl,
    input logic        [7:0] slv_reg4_ballspeed0_pl,
    input logic        [7:0] slv_reg4_ballspeed1_pl,
    input logic        [7:0] slv_reg4_ballspeed2_pl,

    input logic go_left,
    output logic responsing_i2c_pl,
    output logic [7:0] LED,

    output logic is_idle_pl
);

    logic [9:0] ball_x_out_for_one, ball_x_out_for_two;
    logic [9:0] ball_y_out_for_one, ball_y_out_for_two;
    logic is_ball_moving_left_for_one, is_ball_moving_left_for_two;
    logic game_over_for_one, game_over_for_two;
    logic ball_send_trigger_two;


    assign ball_x_out = sw ? ball_x_out_for_two : ball_x_out_for_one;
    assign ball_y_out = sw ? ball_y_out_for_two : ball_y_out_for_one;
    assign is_ball_moving_left = sw? is_ball_moving_left_for_two : is_ball_moving_left_for_one;
    assign game_over = sw ? game_over_for_two : game_over_for_one;
    assign ball_send_trigger = sw ? ball_send_trigger_two : 0;

    game_controller_for_one U_GAME_CONTROLLER_FOR_ONE (
        .*,
        .ball_x_out(ball_x_out_for_one),
        .ball_y_out(ball_y_out_for_one),
        .is_ball_moving_left(is_ball_moving_left_for_one),
        .game_over(game_over_for_one)
    );


    game_controller_for_two U_GAME_CONTROLLER_FOR_TWO(
        .clk_25MHZ(clk_25MHZ),
        .reset(reset),
        .upscale(upscale),
        .collision_detected(collision_detected),
        .ball_x_out(ball_x_out_for_two),
        .ball_y_out(ball_y_out_for_two),
        .is_ball_moving_left(is_ball_moving_left_for_two),
        .estimated_speed(estimated_speed),
        .game_start(game_start),
        .game_over(game_over_for_two),
    
    //상대 보드에 공 정보 전송 wire
        .ball_send_trigger(ball_send_trigger_two),
        .ball_vy(ball_vy),
        .gravity_counter(gravity_counter),
        .ball_speed_reg0(ball_speed_reg0),
        .ball_speed_reg1(ball_speed_reg1),
        .ball_speed_reg2(ball_speed_reg2),
    // slave 추가 (p2)
        .*
);
endmodule
