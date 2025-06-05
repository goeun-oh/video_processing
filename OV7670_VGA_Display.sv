`timescale 1ns / 1ps

module OV7670_VGA_Display (
    // global signals
    input logic clk,
    input logic reset,

    // ov7670 signals
    output logic       ov7670_xclk,
    input  logic       ov7670_pclk,
    input  logic       ov7670_href,
    input  logic       ov7670_v_sync,
    input  logic [7:0] ov7670_data,
    output logic scl,
    output logic sda,

    // export signals
    output logic       h_sync,
    output logic       v_sync,
    output logic [3:0] red_port,
    output logic [3:0] green_port,
    output logic [3:0] blue_port,

    input logic upscale,
    output logic [9:0] estimated_speed,
    input logic game_start,

    output [7:0] seg,
    output [3:0] seg_comm
    );
    logic w_game_start;


    logic we;
    logic [16:0] wAddr;
    logic [15:0] wData;
    logic [16:0] rAddr;
    logic [15:0] rData;

    logic [9:0] x_pixel;
    logic [9:0] y_pixel;
    logic DE;
    logic w_rclk, rclk;
    logic [15:0] camera_pixel;
    logic [15:0] rom_pixel;

    logic [4:0] x_offset;
    logic [4:0] y_offset;

    SCCB U_SCCB (.*);
    
    pix_clk_gen U_OV7670_clk_gen(
        .clk(clk),
        .reset(reset),
        .pclk(ov7670_xclk)
    );

    VGA_Controller U_VGA_CTRL(
       .clk(clk),
       .reset(reset),
       .rclk(w_rclk),
       .h_sync(h_sync),
       .v_sync(v_sync),
       .DE(DE),
       .x_pixel(x_pixel),
       .y_pixel(y_pixel)
    );


    OV7670_MemController U_OV7670_MemController(
        .pclk(ov7670_pclk),
        .reset(reset),
        .href(ov7670_href),
        .v_sync(ov7670_v_sync),
        .ov7670_data(ov7670_data),
        .we(we),
        .wAddr(wAddr),
        .wData(wData)
    );

    frame_buffer U_FRAME_BUFFER(
        // write side
        .wclk(ov7670_pclk),
        .we(we),
        .wAddr(wAddr),
        .wData(wData),

        // read side
        .rclk(rclk),
        .oe(oe),
        .rAddr(rAddr),
        .rData(rData)
    );

    QVGA_MemController U_QVGA_MC(
        // VGA Controller side
        .clk(w_rclk),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .DE(DE),

        // frame
        .rclk(rclk),
        .d_en(oe),
        .rAddr(rAddr),
        .rData(rData),

        // export
        //.red_port(red_port),
        //.green_port(green_port),
        //.blue_port(blue_port)
        .camera_pixel(camera_pixel),
        .upscale(upscale)
    );

   ball_rom U_BALL_ROM(
        .x_offset(x_offset),
        .y_offset(y_offset),
        .pixel_data(rom_pixel)
    );

    logic [9:0] ball_x, ball_y;
    logic is_hit_area;
    logic collision_detected;
    logic is_target_color;
    //logic [9:0] estimated_speed;
    logic [6:0] score;
    game_controller U_GAME_CONTROLLER(
        .clk_25MHZ(ov7670_xclk),
        .reset(reset),
        .ball_x_out(ball_x),    // 공의 X 좌표
        .ball_y_out(ball_y),    // 공의 Y 좌표 (고정)
        .upscale(upscale),
        .collision_detected(collision_detected),
        .estimated_speed(estimated_speed),
        .is_ball_moving_left(is_ball_moving_left),
        .game_start(w_game_start)
    );



    Video_Display U_VIDEO_DISPLAY(
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .camera_pixel(camera_pixel),
        .rom_pixel(rom_pixel),
        .score(score),
        .red_port(red_port),
        .green_port(green_port),
        .blue_port(blue_port),
        .x_offset(x_offset),
        .y_offset(y_offset),
        .ball_x(ball_x),
        .ball_y(ball_y),
        .is_hit_area(is_hit_area)
        );

    color_detector U_COLOR_DETECT(
        .camera_pixel(camera_pixel),
        .is_target_color(is_target_color)
    );

    Collision_Detector U_COLLISION_DETECTOR(
        .is_ball_moving_left(is_ball_moving_left),
        .clk_25MHz(ov7670_xclk),
        .reset(reset),
        .x_pixel(x_pixel),
        .y_pixel(y_pixel),
        .is_hit_area(is_hit_area),       // 화면 상 물체와 공이 겹치는 위치
        .is_target_color(is_target_color),    // 해당 픽셀이 빨간색인지 여부

        .collision_detected(collision_detected),
        .estimated_speed(estimated_speed)
    );

    btn_debounce U_BTN_DEBOUNCE(
        .clk(clk),
        .reset(reset),
        .i_btn(game_start),
        .o_btn(w_game_start)
    );


    score_calculator U_SCORE(
        .clk_25MHz(ov7670_xclk),
        .reset(reset),
        .collision_detected(collision_detected),
        .is_ball_moving_left(is_ball_moving_left),
        .x_pixel(x_pixel),
        .game_start(w_game_start),
        .score(score)
    );
    fnd_controller U_FND(
        .*,
        .Digit({1'b0,score})
        );
endmodule
