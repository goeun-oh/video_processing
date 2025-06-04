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

    output logic collision_detected,
    output logic [9:0] estimated_speed
);

    typedef enum logic [1:0] {
        IDLE = 0,
        START = 1,
        CALC_SPEED = 2
    } state_t;

    state_t state, next;

    logic [15:0] x_sum, x_sum_next;
    logic [9:0] collision_pixel_count, collision_pixel_count_next;
    logic collision_detected_next;

    logic [9:0] curr_center_x, curr_center_x_next;
    logic [9:0] prev_center_x, prev_center_x_next;
    logic [9:0] estimated_speed_next;

    parameter COLLISION_THRESHOLD = 16;

    always_ff @(posedge clk_25MHz or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            collision_pixel_count <= 0;
            collision_detected <= 0;
            curr_center_x <= 0;
            prev_center_x <= 0;
            estimated_speed <= 0;
            x_sum <= 0;
        end
        else begin
            state <= next;
            collision_pixel_count <= collision_pixel_count_next;
            collision_detected <= collision_detected_next;
            curr_center_x <= curr_center_x_next;
            prev_center_x <= prev_center_x_next;
            estimated_speed <= estimated_speed_next;
            x_sum <= x_sum_next;
        end
    end

    // collusion
    always_comb begin
        next = state;

        //collusion
        collision_pixel_count_next = collision_pixel_count;
        collision_detected_next = collision_detected;    

        // speed
        x_sum_next = x_sum;
        curr_center_x_next = curr_center_x;
        prev_center_x_next = prev_center_x;
        estimated_speed_next = estimated_speed;

        case (state)
            IDLE: begin
                x_sum_next       = 0;
                collision_detected_next = 0;
                collision_pixel_count_next = 0;
                if (is_hit_area && is_target_color) begin
                    next = START;
                    prev_center_x_next = x_pixel;
                    x_sum_next = x_pixel;
                    collision_pixel_count_next = collision_pixel_count + 1;
                    //curr_center_x_next = x_pixel; // hit 한 순간 x pixel
                end
            end 

            START: begin
                if (is_hit_area && is_target_color) begin
                    if (collision_pixel_count >= COLLISION_THRESHOLD) begin
                        next = CALC_SPEED;
                        collision_detected_next = 1;
                        curr_center_x_next   = x_sum / collision_pixel_count;
                    end
                    else begin
                        x_sum_next = x_sum + x_pixel;
                        collision_pixel_count_next = collision_pixel_count + 1;
                    end
                end

                else begin
                    next = IDLE;
                end
            end

            CALC_SPEED: begin
                estimated_speed_next = curr_center_x - prev_center_x;
                collision_detected_next = 1;
                curr_center_x_next = 0;
                prev_center_x_next = 0;
                next = IDLE;
            end

        endcase
    end

endmodule
