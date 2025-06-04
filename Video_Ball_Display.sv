`timescale 1ns / 1ps

module Video_Ball_Display(
    input logic [9:0] x_pixel,
    input logic [9:0] y_pixel,
    input logic [15:0] camera_pixel,
    input logic [15:0] rom_pixel,

    output logic [3:0] red_port,
    output logic [3:0] green_port,
    output logic [3:0] blue_port,
    output logic [4:0] x_offset,
    output logic [4:0] y_offset,

    input logic [9:0] ball_x,  // 움직이는 공의 x 위치
    input logic [9:0] ball_y,  // 움직이는 공의 y 위치

    output logic is_hit_area
    );

    parameter OVERLAY_X = 100;
    parameter OVERLAY_Y = 80;

    logic in_overlay_area;

    // overlay offset
    assign x_offset = x_pixel - ball_x;
    assign y_offset = y_pixel - ball_y;

    // overlay 영역 판단
    // h cnt 가 100 ~ 120, v cnt가 80 ~ 100 일 때, 참 
    assign in_overlay_area = (x_pixel >= ball_x && x_pixel < ball_x + 20) &&
                             (y_pixel >= ball_y && y_pixel < ball_y + 20);

    // 최종 출력 픽셀 결정
    //wire [15:0] display_pixel = in_overlay_area ? rom_pixel : camera_pixel;
    logic [15:0] display_pixel = (in_overlay_area && rom_pixel != 16'h0000) ? rom_pixel : camera_pixel; // 탁구공 하얀색 테투리 없애기 위한 작업.

    assign is_hit_area = (x_pixel >= ball_x) && (x_pixel < ball_x + 20) &&
                        (y_pixel >= ball_y) && (y_pixel < ball_y + 20);

    assign red_port   = display_pixel[15:12];
    assign green_port = display_pixel[10:7];
    assign blue_port  = display_pixel[4:1];


endmodule
