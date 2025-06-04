`timescale 1ns / 1ps

module color_detector (
    input logic [15:0] camera_pixel,
    output logic is_target_color
);
    // RGB 4:4:4 기준 (빨간색 계열 판단 예시)
    logic [3:0] R, G, B;
    assign R = camera_pixel[15:12];
    assign G = camera_pixel[10:7];
    assign B = camera_pixel[4:1];

    // 빨간색: R 크고, G/B 작을 때
    assign is_target_color = (R >= 4'd6) && (G >= 4'd6) && (B <= 4'd2);
endmodule

module Collision_Detector (
    input logic clk_25MHz,
    input logic reset,
    input logic [9:0] x_pixel,
    input logic [9:0] y_pixel,
    input logic is_hit_area,       // 화면 상 물체와 공이 겹치는 위치
    input logic is_target_color,    // 해당 픽셀이 빨간색인지 여부

    output logic collision_detected
);
    logic [9:0] collision_pixel_count;
    parameter COLLISION_THRESHOLD = 50;

    logic [9:0] prev_x;

    always_ff @(posedge clk_25MHz or posedge reset) begin
        if (reset) begin
            collision_pixel_count <= 0;
            collision_detected <= 0;
        end
        else begin
            // 특정 위치에 물체가 있고 빨간색이면 충돌
            if (is_hit_area && is_target_color)
                collision_pixel_count <= collision_pixel_count + 1;

            if (collision_pixel_count >= COLLISION_THRESHOLD)
                collision_detected <= 1;

            prev_x <= x_pixel;
        end
    end
endmodule
