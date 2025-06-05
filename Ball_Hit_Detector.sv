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
    assign is_target_color = ((R >= 4'd12) && (G >= 4'd12) && (B >= 4'd12));


endmodule

module Collision_Detector (
    input logic clk_25MHz,
    input logic reset,
    input logic [9:0] x_pixel,
    input logic [9:0] y_pixel,
    input logic is_hit_area,       // 화면 상 물체와 공이 겹치는 위치
    input logic is_target_color,    // 해당 픽셀이 빨간색인지 여부
    input logic is_ball_moving_left,
    output logic collision_detected,
    output logic [9:0] estimated_speed
    );

    typedef enum  {
        IDLE = 0,
        DETECT = 1,
        TRACK = 2,
        CALC = 3,
        WAIT_RELEASE=4
    } state_t;

    state_t state, next;

    //충돌 탐지용
    logic [15:0] detect_x_sum, detect_x_sum_next;
    logic [9:0] detect_pixel_count, detect_pixel_count_next;
    logic [9:0] prev_center_x, prev_center_x_next;
    
    // 추적용
    logic [15:0] track_x_sum, track_x_sum_next;
    logic [9:0]  track_pixel_count, track_pixel_count_next;
    logic [9:0] curr_center_x, curr_center_x_next;

    //결과  
    logic collision_detected_next;
    logic [9:0] estimated_speed_next;


    parameter COLLISION_THRESHOLD = 19;
    parameter TRACK_DURATION = 15;



    always_ff @(posedge clk_25MHz or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            detect_x_sum <= 0;
            detect_pixel_count <= 0;
            prev_center_x <= 0;
            track_x_sum <=0;
            track_pixel_count <=0;
            curr_center_x <= 0;
            collision_detected <= 0;
            estimated_speed <= 0;
        end
        else begin
            state <= next;
            detect_x_sum <= detect_x_sum_next;
            detect_pixel_count <= detect_pixel_count_next;
            prev_center_x <= prev_center_x_next;
            track_x_sum <= track_x_sum_next;
            track_pixel_count <= track_pixel_count_next;
            curr_center_x <= curr_center_x_next;
            collision_detected <= collision_detected_next;
            estimated_speed <= estimated_speed_next;
        end
    end

    // collusion
    always_comb begin
        next = state;
        detect_x_sum_next = detect_x_sum;
        detect_pixel_count_next = detect_pixel_count;
        prev_center_x_next = prev_center_x;
        track_x_sum_next = track_x_sum;
        track_pixel_count_next = track_pixel_count;
        curr_center_x_next = curr_center_x;
        collision_detected_next = 0;
        estimated_speed_next = estimated_speed;

        case (state)
            IDLE: begin
                if (is_hit_area && is_target_color) begin
                    next = DETECT;
                    detect_x_sum_next = x_pixel;
                    detect_pixel_count_next = 1;
                end
            end
            DETECT: begin
                if (is_hit_area && is_target_color) begin
                    detect_x_sum_next = detect_x_sum + x_pixel;
                    detect_pixel_count_next = detect_pixel_count + 1;
                    if (detect_pixel_count >= COLLISION_THRESHOLD) begin
                        prev_center_x_next = detect_x_sum / detect_pixel_count;
                        next = TRACK;
                        track_x_sum_next = 0;
                        track_pixel_count_next = 0;
                    end
                end else begin
                    next = IDLE;
                end
            end
            TRACK: begin
                    if (is_hit_area && is_target_color) begin
                        track_x_sum_next = track_x_sum + x_pixel;
                        track_pixel_count_next = track_pixel_count + 1;
                        if (track_pixel_count >= TRACK_DURATION) begin
                            curr_center_x_next = track_x_sum / track_pixel_count;
                            next = CALC;
                        end
                    end else begin
                        next = IDLE;
                    end
                end

           CALC: begin
                logic signed [10:0] delta_x;
                delta_x = curr_center_x - prev_center_x;
                if ((is_ball_moving_left && delta_x > 0) || (!is_ball_moving_left && delta_x < 0)) begin
                    collision_detected_next = 1;
                    estimated_speed_next = (delta_x > 0) ? delta_x : -delta_x;
                end
                next = WAIT_RELEASE;
            end

        WAIT_RELEASE: begin
            // 색깔이 사라지면 다시 idle로
            if (!is_hit_area || !is_target_color) begin
                next = IDLE;
            end
            // 새 충돌이 또 시작되면 DETECT로 다시 감
            else if (is_hit_area && is_target_color && is_ball_moving_left) begin
                next = DETECT;
            end
        end

            
        endcase
    end

endmodule
