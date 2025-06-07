`timescale 1ns / 1ps

module game_controller (
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
    output logic [7:0] score_test,
    
    //상대 보드에 공 정보 전송 wire
    output logic       ball_send_trigger,
    output logic [7:0] ball_vy,

    input logic [7:0] slv_reg0_y0,
    input logic [7:0] slv_reg1_y1,
    input logic [7:0] slv_reg2_speed,
    input logic [7:0] slv_reg3_trig,

    input logic go_right
);

    typedef enum logic [1:0] {
        IDLE = 0,
        RUNNING_RIGHT = 1,
        RUNNING_LEFT = 2,
        STOP = 3
    } state_t;

    state_t state, next;

    logic [9:0] ball_x_next, ball_y_next;
    logic signed [9:0] ball_y_vel, ball_y_vel_next;
    logic ball_send_trigger_reg, ball_send_trigger_next;
    logic [31:0] ball_counter, ball_counter_next;
    logic [1:0] gravity_counter, gravity_counter_next;
    logic [1:0] x_counter, x_counter_next;
    logic [9:0] safe_speed;
    // 속도 갱신용
    logic [19:0] ball_speed, ball_speed_next;
    logic [9:0] y_min = 0;
    logic [9:0] y_max;

    logic game_over_next;

    logic [7:0] score_test_next;
    
    assign ball_send_trigger = ball_send_trigger_reg;
    assign ball_vy = ball_y_vel;


    always_ff @(posedge clk_25MHZ or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            ball_x_out <= 10;
            ball_y_out <= 80;
            ball_counter <= 0;
            gravity_counter <= 0;
            x_counter <= 0;
            ball_y_vel <= -3;
            ball_speed <= 20'd270000;
            game_over <= 0;
            score_test <= 0;
            ball_send_trigger_reg <=0;
        end else begin
            state <= next;
            ball_x_out <= ball_x_next;
            ball_y_out <= ball_y_next;
            ball_counter <= ball_counter_next;
            gravity_counter <= gravity_counter_next;
            x_counter <= x_counter_next;
            ball_y_vel <= ball_y_vel_next;
            ball_speed <= ball_speed_next;
            game_over <= game_over_next;
            score_test <= score_test_next;
            ball_send_trigger_reg <= ball_send_trigger_next;
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
        game_over_next = game_over;
        score_test_next = score_test;
        ball_send_trigger_next = 1'b0;

        y_max = upscale ? 479 : 239;

        case (state)
            IDLE: begin
                game_over_next  = 0;
                score_test_next = 0;
                if (go_right) begin
                    next = RUNNING_RIGHT;
                    ball_y_next = {slv_reg0_y0[9:8], slv_reg1_y1};
                    ball_x_next = 0;
                    ball_y_vel_next = slv_reg2_speed;
                end
            end

            STOP: begin
                game_over_next = 1;
                ball_send_trigger_next =1;
                if (game_start) begin
                    score_test_next = 0;
                    next = RUNNING_LEFT;
                    ball_send_trigger_next =0;
                end
            end

            RUNNING_RIGHT: begin
                game_over_next = 0;
                if (collision_detected) begin
                    next = RUNNING_LEFT;
                    ball_counter_next = 0;
                    x_counter_next = 0;
                end else if (ball_x_out >= (upscale ? 640 - 20 : 320 - 20)) begin
                    next = STOP;
                end else begin
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
                game_over_next = 0;

                if (collision_detected) begin
                    safe_speed = (estimated_speed < 2) ? 1.6 : estimated_speed;
                    ball_speed_next = 32'd270000 / safe_speed;
                end

                if (ball_x_out <= 0) begin
                    score_test_next = score_test + 1;
                    next = RUNNING_RIGHT;
                    ball_counter_next = 0;
                    x_counter_next = 0;
                    ball_speed_next = 20'd270000;  // 속도 초기화
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
