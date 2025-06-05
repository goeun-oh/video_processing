`timescale 1ns / 1ps

module game_controller(
    input logic clk_25MHZ,
    input logic reset,
    input logic upscale,
    input logic collision_detected,
    output logic [9:0] ball_x_out,
    output logic [9:0] ball_y_out,
    output logic is_ball_moving_left,
    input logic [9:0] estimated_speed,
    input logic game_start
);

    typedef enum logic [1:0] {
        IDLE = 0,
        RUNNING_RIGHT = 1,
        RUNNING_LEFT  = 2
    } state_t;

    state_t state, next;

    logic [9:0] ball_x_next, ball_y_next;
    logic signed [9:0] ball_y_vel, ball_y_vel_next;

    logic [31:0] ball_counter, ball_counter_next;
    logic [1:0] gravity_counter, gravity_counter_next;
    logic [1:0] x_counter, x_counter_next;
    logic [9:0] safe_speed;
    // 속도 갱신용
    logic [19:0] ball_speed, ball_speed_next;
    logic [9:0] y_min = 0;
    logic [9:0] y_max;

    always_ff @(posedge clk_25MHZ or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            ball_x_out <= 100;
            ball_y_out <= 80;
            ball_counter <= 0;
            gravity_counter <= 0;
            x_counter <= 0;
            ball_y_vel <= -3;
            ball_speed <= 20'd270000;
        end else begin
            state <= next;
            ball_x_out <= ball_x_next;
            ball_y_out <= ball_y_next;
            ball_counter <= ball_counter_next;
            gravity_counter <= gravity_counter_next;
            x_counter <= x_counter_next;
            ball_y_vel <= ball_y_vel_next;
            ball_speed <= ball_speed_next;
        end
    end

    always_comb begin
        next = state;
        ball_x_next = ball_x_out;
        ball_y_next = ball_y_out;
        ball_counter_next = ball_counter;
        gravity_counter_next = gravity_counter;
        x_counter_next = x_counter;
        ball_y_vel_next = ball_y_vel;
        is_ball_moving_left = 1'b0;
        ball_speed_next = ball_speed;

        y_max = upscale ? 479 : 239;

        case (state)
            IDLE: begin
                if (game_start) begin
                    next = RUNNING_LEFT;
                end            
            end

            RUNNING_RIGHT: begin
                if (collision_detected) begin
                    next = RUNNING_LEFT;
                    ball_counter_next = 0;
                    x_counter_next = 0;
                end else if (ball_x_out >= (upscale ? 640 - 20 : 320 - 20)) begin
                    next = IDLE;
                end

                else begin
                    if (ball_counter >= ball_speed) begin
                        ball_x_next = ball_x_out + 4;
                        ball_counter_next = 0;

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

            RUNNING_LEFT: begin
                is_ball_moving_left = 1'b1;

                if (collision_detected) begin
                    safe_speed = (estimated_speed < 2) ? 2 : estimated_speed;
                    ball_speed_next = 32'd270000 / safe_speed;
                end

                if (ball_x_out <= 0) begin
                    next = RUNNING_RIGHT;
                    ball_counter_next = 0;
                    x_counter_next = 0;
                    ball_speed_next = 20'd270000; // 속도 초기화
                end else begin
                    if (ball_counter >= ball_speed) begin
                        ball_x_next = ball_x_out - 4;
                        ball_counter_next = 0;

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
