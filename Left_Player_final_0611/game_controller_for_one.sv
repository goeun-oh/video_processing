`timescale 1ns / 1ps

module game_controller_for_one (
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

    output logic rand_en,
    input logic [1:0] rand_ball
);

    typedef enum logic [1:0] {
        IDLE = 0,
        RUNNING_RIGHT = 1,
        RUNNING_LEFT = 2,
        STOP = 3
    } state_t;

    parameter BALL_PINGPONG = 0, BALL_SOCCER = 1, BALL_BASKET = 2;

    state_t state, next;

    logic [9:0] ball_x_next, ball_y_next;
    logic signed [9:0] ball_y_vel, ball_y_vel_next;
    logic ball_send_trigger_reg, ball_send_trigger_next;
    logic [31:0] ball_counter, ball_counter_next;
    logic [1:0] gravity_counter_reg, gravity_counter_next;
    logic [1:0] x_counter, x_counter_next;
    logic [9:0] safe_speed_reg, safe_speed_next;
    // 속도 갱신용
    logic [19:0] ball_speed_reg, ball_speed_next;
    logic [9:0] y_min = 0;
    logic [9:0] y_max;

    logic game_over_next;

    logic rand_en_next;    

    
    always_ff @(posedge clk_25MHZ or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            ball_x_out <= 100;
            ball_y_out <= 80;
            ball_counter <= 0;
            gravity_counter_reg <= 0;
            x_counter <= 0;
            ball_y_vel <= -3;
            ball_speed_reg <= 20'd270000;
            game_over <= 0;
            ball_send_trigger_reg <=0;
            safe_speed_reg <=1;
            rand_en <= 0;
        end else begin
            state <= next;
            ball_x_out <= ball_x_next;
            ball_y_out <= ball_y_next;
            ball_counter <= ball_counter_next;
            gravity_counter_reg <= gravity_counter_next;
            x_counter <= x_counter_next;
            ball_y_vel <= ball_y_vel_next;
            ball_speed_reg <= ball_speed_next;
            game_over <= game_over_next;
            ball_send_trigger_reg <= ball_send_trigger_next;
            safe_speed_reg <= safe_speed_next;
            rand_en <= rand_en_next;
        end
    end

    always_comb begin
        next = state;
        ball_x_next = ball_x_out;
        ball_y_next = ball_y_out;
        ball_counter_next = ball_counter;
        gravity_counter_next = gravity_counter_reg;
        x_counter_next = x_counter;
        ball_y_vel_next = ball_y_vel;
        is_ball_moving_left = 1'b0;
        ball_speed_next = ball_speed_reg;
        game_over_next = game_over;
        ball_send_trigger_next = 1'b0;
        safe_speed_next = safe_speed_reg;
        y_max = upscale ? 479 : 239;
        rand_en_next = rand_en;

        case (state)
            IDLE: begin
                game_over_next  = 0;
                rand_en_next = 0;
                if (game_start) begin
                    next = RUNNING_LEFT;
                end
            end

            STOP: begin
                game_over_next = 1;
                rand_en_next = 0;
                ball_send_trigger_next =1;
                if (game_start) begin
                    next = RUNNING_LEFT;
                    ball_send_trigger_next =0;
                end
            end

            RUNNING_RIGHT: begin
                game_over_next = 0;
                rand_en_next = 0;
                case (rand_ball)
                    BALL_PINGPONG: ball_speed_next = 20'd270000;
                    BALL_SOCCER:   ball_speed_next = 20'd360000;
                    BALL_BASKET:   ball_speed_next = 20'd520000;
                    default:       ball_speed_next = 20'd270000;
                endcase
                if (collision_detected) begin
                    next = RUNNING_LEFT;
                    ball_counter_next = 0;
                    x_counter_next = 0;
                    rand_en_next = 0;
                end else if (ball_x_out >= (upscale ? 640 - 20 : 320 - 20)) begin
                    next = STOP;
                end else begin
                    if (ball_counter >= ball_speed_reg) begin
                        ball_x_next = ball_x_out + 4;
                        ball_counter_next = 0;

                        if (gravity_counter_reg == 2'd3) begin
                            ball_y_vel_next = ball_y_vel + 1;
                            gravity_counter_next = 0;
                        end else begin
                            gravity_counter_next = gravity_counter_reg + 1;
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
                    safe_speed_reg = (estimated_speed < 2) ? 1.6 : 1;
                    ball_speed_next = 32'd270000 / safe_speed_reg;
                end

                if (ball_x_out <= 0) begin
                    next = RUNNING_RIGHT;
                    ball_counter_next = 0;
                    x_counter_next = 0;
                    safe_speed_next = 1;
                    rand_en_next = 1;
                end else begin
                    if (ball_counter >= ball_speed_reg) begin
                        ball_x_next = ball_x_out - 4;
                        ball_counter_next = 0;

                        if (gravity_counter_reg == 2'd3) begin
                            ball_y_vel_next = ball_y_vel + 1;
                            gravity_counter_next = 0;
                        end else begin
                            gravity_counter_next = gravity_counter_reg + 1;
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
