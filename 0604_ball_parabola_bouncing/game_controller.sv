`timescale 1ns / 1ps

module game_controller(
    input logic clk_25MHZ,
    input logic reset,
    input logic upscale,
    input logic collision_detected,
    output logic [9:0] ball_x_out,    // 공의 X 좌표
    output logic [9:0] ball_y_out     // 공의 Y 좌표
    );
    

    // 상태 정의
    typedef enum logic [1:0] {
        IDLE          = 0,
        RUNNING_RIGHT = 1,
        RUNNING_LEFT  = 2
    } state_t;

    state_t state, next;

    // 공 위치 및 속도
    logic [9:0] ball_x_next, ball_y_next;
    logic signed [9:0] ball_y_vel, ball_y_vel_next;

    logic [19:0] ball_counter, ball_counter_next;
    logic [1:0] gravity_counter, gravity_counter_next;

    logic [19:0] ball_speed = 20'd500000;

    // 화면 높이 제한 (upscale에 따라 다르게)
    logic [9:0] y_min = 0;
    logic [9:0] y_max;

    always_ff @(posedge clk_25MHZ or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            ball_x_out <= 100;
            ball_y_out <= 80;
            ball_counter <= 0;
            gravity_counter <= 0;
            ball_y_vel <= -3;
        end else begin
            state <= next;
            ball_x_out <= ball_x_next;
            ball_y_out <= ball_y_next;
            ball_counter <= ball_counter_next;
            gravity_counter <= gravity_counter_next;
            ball_y_vel <= ball_y_vel_next;
        end
    end

    always_comb begin
        next = state;
        ball_x_next = ball_x_out;
        ball_y_next = ball_y_out;
        ball_counter_next = ball_counter;
        gravity_counter_next = gravity_counter;
        ball_y_vel_next = ball_y_vel;

        y_max = upscale ? 479 : 239;

        case (state)
            IDLE: begin
                next = RUNNING_LEFT;
            end

            RUNNING_RIGHT: begin
                if ((ball_x_out >= (upscale ? 640 - 20 : 320 - 20)) || collision_detected) begin
                    next = RUNNING_LEFT;
                    ball_counter_next = 0;
                end else begin
                    if (ball_counter >= ball_speed) begin
                        ball_x_next = ball_x_out + 1;
                        ball_counter_next = 0;

                        // 중력 느리게 증가
                        if (gravity_counter == 2'd3) begin
                            ball_y_vel_next = ball_y_vel + 1;
                            gravity_counter_next = 0;
                        end else begin
                            gravity_counter_next = gravity_counter + 1;
                        end

                        ball_y_next = ball_y_out + ball_y_vel;

                        // 천장 또는 바닥 충돌 처리
                        if (ball_y_next >= y_max) begin
                            ball_y_next = y_max;
                            ball_y_vel_next = -ball_y_vel_next;
                        end else if (ball_y_next <= y_min) begin
                            ball_y_next = y_min;
                            ball_y_vel_next = -ball_y_vel_next;
                        end
                    end else begin
                        ball_counter_next = ball_counter + 1;
                    end
                end
            end

            RUNNING_LEFT: begin
                if (ball_x_out == 0) begin
                    next = RUNNING_RIGHT;
                    ball_counter_next = 0;
                end else begin
                    if (ball_counter >= ball_speed) begin
                        ball_x_next = ball_x_out - 1;
                        ball_counter_next = 0;

                        // 중력 느리게 증가
                        if (gravity_counter == 2'd3) begin
                            ball_y_vel_next = ball_y_vel + 1;
                            gravity_counter_next = 0;
                        end else begin
                            gravity_counter_next = gravity_counter + 1;
                        end

                        ball_y_next = ball_y_out + ball_y_vel;

                        if (ball_y_next >= y_max) begin
                            ball_y_next = y_max;
                            ball_y_vel_next = -ball_y_vel_next;
                        end else if (ball_y_next <= y_min) begin
                            ball_y_next = y_min;
                            ball_y_vel_next = -ball_y_vel_next;
                        end
                    end else begin
                        ball_counter_next = ball_counter + 1;
                    end
                end
            end
        endcase
    end
endmodule
