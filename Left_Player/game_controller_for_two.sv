`timescale 1ns / 1ps

module game_controller_for_two (
    input  logic       clk_25MHZ,
    input  logic       reset,
    input  logic       upscale,
    input  logic       collision_detected,
    output logic [9:0] ball_x_out,
    output logic [9:0] ball_y_out,
    output logic       is_ball_moving_left,
    output logic       is_ball_moving_right,
    input  logic [9:0] estimated_speed,
    input  logic       game_start,
    output logic       game_over,

    //상대 보드에 공 정보 전송 wire
    output logic       ball_send_trigger,
    output logic [7:0] ball_vy,
    output logic [1:0] gravity_counter,
    output logic       is_collusion,

    //상대 보드로 부터 받은 정보//
    input logic        [7:0] slv_reg0_y0,
    input logic        [7:0] slv_reg1_y1,
    input logic signed [7:0] slv_reg2_Yspeed,
    input logic        [7:0] slv_reg3_gravity,
    input logic        [7:0] slv_reg4_ballspeed,
    input logic        [7:0] slv_reg5_win_flag,

    input  logic       is_slave_done,
    output logic       is_you_win,
    output logic       responsing_i2c,
    input  logic       is_i2c_master_done,
    output logic [7:0] contrl_led,
    output logic is_idle,
    output logic is_lose

);

    typedef enum {
        IDLE,
        WAIT,
        WIN_FLAG,
        WAIT_WIN_FLAG,
        RUNNING_RIGHT,
        RUNNING_LEFT,
        STOP,
        SEND_BALL,
        SEND_LOSE
    } state_t;

    state_t state, next;
    logic is_lose_reg, is_lose_next;    
    assign is_lose = is_lose_reg;


    logic [9:0] ball_x_next, ball_y_next;
    logic signed [9:0] ball_y_vel, ball_y_vel_next;
    logic ball_send_trigger_reg, ball_send_trigger_next;
    logic [31:0] ball_counter, ball_counter_next;
    logic [1:0] gravity_counter_reg, gravity_counter_next;
    logic [1:0] x_counter, x_counter_next;
    logic [9:0] safe_speed_reg, safe_speed_next;
    logic is_you_win_reg, is_you_win_next;
    // 속도 갱신용
    logic [19:0] ball_speed_reg, ball_speed_next;
    logic [9:0] y_min = 0;
    logic [9:0] y_max;

    logic game_over_next;


    assign ball_send_trigger = ball_send_trigger_reg;
    assign ball_vy = ball_y_vel;
    assign gravity_counter = gravity_counter_reg;
    //assign ball_speed = ball_speed_reg;
    assign is_you_win = is_you_win_reg;

    always_ff @(posedge clk_25MHZ or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            ball_x_out <= 0;
            ball_y_out <= 220;
            ball_counter <= 0;
            gravity_counter_reg <= 0;
            x_counter <= 0;
            ball_y_vel <= -3;
            ball_speed_reg <= 20'd270000;
            game_over <= 0;
            ball_send_trigger_reg <= 0;
            safe_speed_reg <= 1;
            is_you_win_reg <= 0;
            is_lose_reg <=0;
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
            is_you_win_reg <= is_you_win_next;
            is_lose_reg <= is_lose_next;
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
        is_ball_moving_right = 1'b0;
        ball_speed_next = ball_speed_reg;
        game_over_next = 0;
        ball_send_trigger_next = 1'b0;
        safe_speed_next = safe_speed_reg;
        y_max = upscale ? 479 : 239;
        responsing_i2c = 1'b0;
        is_you_win_next = is_you_win_reg;
        is_idle=0;
        is_lose_next = is_lose_reg;

        case (state)
            IDLE: begin
                contrl_led = 8'b0000_0001;
                game_over_next = 0;
                safe_speed_next = 1;
                ball_x_next = 0;
                ball_y_next = 220;
                ball_speed_next = 20'd270000;
                is_collusion = 1'b0;
                ball_send_trigger_next = 1'b0;
                is_idle=1;
                if (game_start) begin
                    next = RUNNING_RIGHT;
                    is_you_win_next = 0;
                end
                if (is_slave_done) begin
                    next = WAIT;
                    ball_y_next = {slv_reg0_y0[7:6], slv_reg1_y1};
                    ball_x_next = 620;
                    ball_y_vel_next = slv_reg2_Yspeed;
                    gravity_counter_next = slv_reg3_gravity[1:0];
                    ball_speed_next = slv_reg4_ballspeed[0]? 20'd270000 :20'd135000;
                    is_you_win_next = slv_reg5_win_flag[0];
                end
            end

            WAIT: begin
                contrl_led = 8'b0000_0010;
                responsing_i2c = 1'b1;
                is_idle = 1;
                if (!is_slave_done) begin
                    if(is_you_win_reg) begin
                        next = IDLE;
                    end else begin
                        next = RUNNING_LEFT;
                        is_you_win_next =1'b0;
                    end
                end
            end

            WIN_FLAG: begin
                contrl_led = 8'b0000_0100;
                is_idle = 1;
                if(!is_i2c_master_done) begin
                    if (is_slave_done) begin
                        next = WAIT;
                        is_you_win_next = slv_reg5_win_flag[0];
                    end                    
                end
                if (game_start) begin
                    next = IDLE;
                end
            end


            STOP: begin
                contrl_led = 8'b0001_0000;
                game_over_next = 1;
                if (is_slave_done) begin
                    next = IDLE;
                    game_over_next =0;
                end
                if (game_start) begin
                    next = IDLE;
                end            
            end
            SEND_LOSE: begin
                contrl_led = 8'b0000_1000;
                is_lose_next =1'b1;
                game_over_next= 1'b1;
                if (is_slave_done) begin
                    next = IDLE;
                    is_lose_next =0;
                end
                if (game_start) begin
                    next = IDLE;
                end    
            end
            SEND_BALL: begin
                contrl_led = 8'b0010_0000;
                ball_send_trigger_next = 1;
                if (game_start) begin
                    next = IDLE;
                    ball_send_trigger_next = 0;
                end
                if (is_i2c_master_done) begin
                    next = WIN_FLAG;
                    ball_send_trigger_next =0;
                end
            end

            RUNNING_LEFT: begin
                contrl_led = 8'b0100_0000;
                game_over_next = 0;
                is_ball_moving_left = 1'b1;
                if (collision_detected) begin
                    next = RUNNING_RIGHT;
                    ball_counter_next = 0;
                    x_counter_next = 0;
                end else if (ball_x_out <= 0) begin
                    next = SEND_LOSE;
                    ball_send_trigger_next=  1;
                    game_over_next = 1;

                end else begin
                    if (ball_counter >= ball_speed_reg) begin
                        ball_x_next = ball_x_out - 10;
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

            RUNNING_RIGHT: begin  // 원래 left
                is_ball_moving_right = 1'b1;
                game_over_next = 0;
                contrl_led = 8'b1000_0000;

                if (collision_detected) begin
                    safe_speed_next = (estimated_speed < 2) ? 1.3 : estimated_speed;
                    ball_speed_next = 20'd270000 / safe_speed_next;
                    is_collusion = 1'b1;
                end

                if (ball_x_out >= (upscale ? 640 - 20 : 320 - 20)) begin
                    next = SEND_BALL;
                    ball_counter_next = 0;
                    x_counter_next = 0;
                end else begin
                    if (ball_counter >= ball_speed_reg) begin
                        ball_x_next = ball_x_out + 10;
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
