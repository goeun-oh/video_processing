`timescale 1ns / 1ps

module game_controller (
    input  logic       clk_25MHZ,
    input  logic       reset,
    input  logic       upscale,
    input  logic       collision_detected,
    output logic [9:0] ball_x_out,
    output logic [9:0] ball_y_out,
    output logic       is_ball_moving_right,
    input  logic [9:0] estimated_speed,
    input  logic       game_start,
    output logic       game_over,
    output logic [7:0] score_test,

    //상대 보드에 공 정보 전송 wire
    output logic       ball_send_trigger,
    output logic [7:0] ball_vy,
    output logic [1:0] gravity_counter,
    output logic       is_collusion,

    input logic        [7:0] slv_reg0_y0,
    input logic        [7:0] slv_reg1_y1,
    input logic signed [7:0] slv_reg2_Yspeed,
    input logic        [7:0] slv_reg3_gravity,
    input logic        [7:0] slv_reg4_ballspeed,
    input logic        [7:0] slv_reg5_win_flag,

    input logic is_slave_done,
    output logic responsing_i2c,
    output logic       is_you_win,

    output logic is_idle,
    output logic [7:0] contrl_led,
    input  logic       is_i2c_master_done,
    //상대 보드에 LOSE 정보 전송//
    output logic is_lose,
    input logic ball_send_to_slave
);


    typedef enum {
        IDLE,
        WAIT,
        RUNNING_RIGHT,
        RUNNING_LEFT,
        STOP,
        SEND_LOSE,
        SEND_BALL,
        WIN_FLAG,
        WAIT_LOSE
    } state_t;

    state_t state, next;

    logic [9:0] ball_x_next, ball_y_next;
    logic signed [9:0] ball_y_vel, ball_y_vel_next;
    logic ball_send_trigger_reg, ball_send_trigger_next;
    logic [31:0] ball_counter, ball_counter_next;
    logic [1:0] gravity_counter_reg, gravity_counter_next;
    logic [1:0] x_counter, x_counter_next;
    logic [9:0] safe_speed_reg, safe_speed_next;
    // 속도 갱신용
    logic [19:0] ball_speed, ball_speed_next;
    logic [19:0] sending_ball_speed;
    logic [9:0] y_min = 20;
    logic [9:0] y_max;
    logic game_over_next;
    logic is_lose_reg, is_lose_next;
    logic [7:0] score_test_next;
    logic is_you_win_reg, is_you_win_next;

    assign is_you_win = is_you_win_reg;

    assign ball_send_trigger = ball_send_trigger_reg;
    assign ball_vy = ball_y_vel;
    assign gravity_counter = gravity_counter_reg;

    assign is_lose = is_lose_reg;

    always_ff @(posedge clk_25MHZ or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            ball_x_out <= 10;
            ball_y_out <= 80;
            ball_counter <= 0;
            gravity_counter_reg <= 0;
            x_counter <= 0;
            ball_y_vel <= -3;
            ball_speed <= 20'd270000;
            game_over <= 0;
            score_test <= 0;
            ball_send_trigger_reg <= 0;
            safe_speed_reg <= 1;
            is_lose_reg <=0;
            is_you_win_reg <= 0;
           
        end else begin
            state <= next;
            ball_x_out <= ball_x_next;
            ball_y_out <= ball_y_next;
            ball_counter <= ball_counter_next;
            gravity_counter_reg <= gravity_counter_next;
            x_counter <= x_counter_next;
            ball_y_vel <= ball_y_vel_next;
            ball_speed <= ball_speed_next;
            game_over <= game_over_next;
            score_test <= score_test_next;
            ball_send_trigger_reg <= ball_send_trigger_next;
            safe_speed_reg <= safe_speed_next;
            is_lose_reg <= is_lose_next;
            is_you_win_reg <= is_you_win_next;

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
        is_ball_moving_right = 1'b0;
        ball_speed_next = ball_speed;
        game_over_next = game_over;
        score_test_next = score_test;
        ball_send_trigger_next = 1'b0;
        responsing_i2c = 1'b0;
        safe_speed_next = safe_speed_reg;
        is_idle =1'b0;
        is_lose_next = is_lose_reg;
        is_you_win_next = is_you_win_reg;

        y_max = upscale ? 479 : 239;

        case (state)
            IDLE: begin
                contrl_led = 8'h01;
                game_over_next = 0;
                score_test_next = 0;
                safe_speed_next = 1;
                is_idle = 1'b1;
                is_collusion = 1'b0;

                if (is_slave_done) begin
                    next = WAIT;
                    ball_y_next = {slv_reg0_y0[7:6], slv_reg1_y1};
                    ball_x_next = 20;
                    ball_y_vel_next = slv_reg2_Yspeed;
                    gravity_counter_next = slv_reg3_gravity[1:0];
                    ball_speed_next = slv_reg4_ballspeed[0]? 20'd270000 :20'd200000;
                    is_you_win_next = slv_reg5_win_flag[0];
                end
            end

            WAIT: begin
                contrl_led = 8'b0000_0010;
                responsing_i2c = 1'b1;
                if (!is_slave_done) begin
                    responsing_i2c = 1'b0;
                    if(is_you_win_reg) begin
                        next = IDLE;
                    end else begin
                        next = RUNNING_RIGHT;
                        is_you_win_next =1'b0;
                    end
                end
            end

            WIN_FLAG: begin
                contrl_led = 8'b0000_0100;
                if(!is_i2c_master_done) begin
                    if (is_slave_done) begin
                        next = WAIT;
                        is_you_win_next = slv_reg5_win_flag[0];
                    end                    
                end
            end

            STOP: begin
                contrl_led = 8'b0000_1000;
                game_over_next = 1;
                if (!is_i2c_master_done) begin
                    next = IDLE;
                    game_over_next =0;
                end
            end

            WAIT_LOSE: begin
                responsing_i2c = 1'b1;
                if(!is_slave_done) begin
                    next= IDLE;
                    responsing_i2c = 1'b0;
                end
            end

            SEND_LOSE: begin
                contrl_led = 8'b0000_1000;
                is_lose_next =1'b1;
                game_over_next= 1'b1;
                if(!ball_send_to_slave) begin
                    ball_send_trigger_next = 1;
                end else begin
                    ball_send_trigger_next = 0;
                end
                if(is_i2c_master_done) begin
                    next= STOP;
                    is_lose_next = 1'b0;
                    game_over_next= 1'b0;
                end
            end

            SEND_BALL: begin
                contrl_led = 8'b0001_0000;
                if(!ball_send_to_slave) begin
                    ball_send_trigger_next = 1;
                end else begin
                    ball_send_trigger_next = 0;
                end
                //next = STOP;
                if (is_i2c_master_done) begin
                    next = WIN_FLAG;
                    ball_send_trigger_next =0;
                end
            end

            RUNNING_RIGHT: begin
                is_ball_moving_right = 1'b1;
                contrl_led = 8'b0010_0000;

                game_over_next = 0;
                if (collision_detected) begin
                    next = RUNNING_LEFT;
                    ball_counter_next = 0;
                    x_counter_next = 0;
                    is_collusion = 1'b1;
                end else if (ball_x_out >= (upscale ? 640 - 20 : 320 - 20)) begin
                    if(!ball_send_to_slave) begin
                        ball_send_trigger_next = 1;
                    end else begin
                        ball_send_trigger_next = 0;
                    end                    
                    next = SEND_LOSE;
                    game_over_next = 1;
                    is_lose_next =1'b1;
                end else begin
                    if (ball_counter >= ball_speed) begin
                        ball_x_next = ball_x_out + 8;
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
                contrl_led = 8'b0100_0000;

                game_over_next = 0;
                if (collision_detected) begin
                    safe_speed_next = (estimated_speed < 2) ? 1.3 : estimated_speed;
                    ball_speed_next = 20'd270000 / safe_speed_next;
                    is_collusion = 1'b1;
                end
                if (ball_x_out <= 0) begin
                    next = SEND_BALL;
                end else begin
                    if (ball_counter >= ball_speed) begin
                        ball_x_next = ball_x_out - 8;
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
