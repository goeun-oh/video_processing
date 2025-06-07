`timescale 1ns / 1ps

module OV7670_VGA_Display (
    // global signals
    input logic clk,
    input logic reset,
    input logic [2:0] sw,

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
    output logic [15:0] LED,
    input logic game_start,

    output logic [3:0] fndCom,
    output logic [7:0] fndFont,

    // i2c 관련//
    input logic i2c_scl,
    inout logic i2c_sda,

    input logic ball_receive_from_master
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
    logic [9:0] estimated_speed;
    logic [7:0] score;
    logic game_over;
    logic [7:0] score_test;


    //ball 전송 관련 //
    logic [7:0] ball_vy;

    logic ball_send_trigger;
    logic is_transfer;

    logic [7:0] slv_reg0_y0;
    logic [7:0] slv_reg1_y1;
    logic [7:0] slv_reg2_speed;
    logic [7:0] slv_reg3_trig;

    game_controller U_GAME_CONTROLLER(
        .*,
        .clk_25MHZ(ov7670_xclk),
        .ball_x_out(ball_x),    // 공의 X 좌표
        .ball_y_out(ball_y),    // 공의 Y 좌표 (고정)
        .collision_detected(collision_detected),
        .game_start(w_game_start),

        // master로 부터 데이터 받기
        .slv_reg0_y0(slv_reg0_y0),
        .slv_reg1_y1(slv_reg1_y1),
        .slv_reg2_speed(slv_reg2_speed),

        .ball_receive_from_master(ball_receive_from_master),
        .slv_reg3_trig(slv_reg3_trig)
    );
    
    top_i2c_slave U_I2C_SLAVE(
        .clk(clk),
        .reset(reset),
        .sw(sw),
        .SCL(i2c_scl),
        .SDA(i2c_sda),
        .fndFont(fndFont),
        .fndCom(fndCom),
        .LED(LED),

        .slv_reg0_y0(slv_reg0_y0),
        .slv_reg1_y1(slv_reg1_y1),
        .slv_reg2_speed(slv_reg2_speed),
        .slv_reg3_trig(slv_reg3_trig)
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
        .is_hit_area(is_hit_area),
        .game_over(game_over)
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
        .clk(ov7670_xclk),
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
        .score(score) // 잠시대기
    );
    
endmodule
