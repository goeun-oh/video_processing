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
    assign is_target_color = (R >= 4'd12) && (G >= 4'd12) && (B >= 4'd12);

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

    typedef enum logic [1:0] {
        IDLE = 0,
        START = 1
    } state_t;

    state_t state, next;

    logic [9:0] collision_pixel_count, collision_pixel_count_next;
    logic collision_detected_next;

    parameter COLLISION_THRESHOLD = 10;

    logic [9:0] prev_x;

    always_ff @(posedge clk_25MHz or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            collision_pixel_count <= 0;
            collision_detected <= 0;
        end
        else begin
            state <= next;
            collision_pixel_count <= collision_pixel_count_next;
            collision_detected <= collision_detected_next;
        end
    end

    always_comb begin
        next = state;
        collision_pixel_count_next = collision_pixel_count;
        collision_detected_next = collision_detected;    

        case (state)
            IDLE: begin
                collision_pixel_count_next = 0;
                collision_detected_next = 0;
                if (is_hit_area && is_target_color) begin
                    next = START;
                    collision_pixel_count_next = collision_pixel_count + 1;
                end
            end 

            START: begin
                if (is_hit_area && is_target_color) begin
                    if (collision_pixel_count >= COLLISION_THRESHOLD) begin
                        next = IDLE;
                        collision_detected_next = 1;
                    end
                    else begin
                        collision_pixel_count_next = collision_pixel_count + 1;
                    end
                end

                else begin
                    next = IDLE;
                end

            end

        endcase
    end
endmodule
