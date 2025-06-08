`timescale 1ns / 1ps

module game_controller_for_two (
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
    
    //상대 보드에 공 정보 전송 wire
    output logic       ball_send_trigger,
    output logic [7:0] ball_vy,
    output logic [1:0] gravity_counter,
    output logic [7:0] ball_speed_reg0,
    output logic [7:0] ball_speed_reg1,
    output logic [3:0] ball_speed_reg2,


    // slave 추가
    input logic        [7:0] slv_reg0_y0_pl,
    input logic        [7:0] slv_reg1_y1_pl,
    input logic signed [7:0] slv_reg2_Yspeed_pl,
    input logic        [7:0] slv_reg3_gravity_pl,
    input logic        [7:0] slv_reg4_ballspeed0_pl,
    input logic        [7:0] slv_reg4_ballspeed1_pl,
    input logic        [7:0] slv_reg4_ballspeed2_pl,

    input logic go_left,
    output logic responsing_i2c_pl,
    output logic [7:0] LED,

    output logic is_idle_pl
);

    typedef enum logic [2:0] {
        IDLE = 0,
        RUNNING_RIGHT = 1,
        RUNNING_LEFT = 2,
        STOP = 3,
        SEND_BALL = 4,
        WAIT = 5
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
    logic [19:0] ball_speed_reg, ball_speed_next;
    logic [19:0] sending_ball_speed;
    logic [9:0] y_min = 0;
    logic [9:0] y_max;

    logic game_over_next;

    
    assign ball_send_trigger = ball_send_trigger_reg;
    assign ball_vy = ball_y_vel;
    assign gravity_counter = gravity_counter_reg;
    //assign ball_speed = ball_speed_reg;
    assign ball_speed_reg0 = ball_speed_reg[7:0];
    assign ball_speed_reg1 = ball_speed_reg[15:8];
    assign ball_speed_reg2 = ball_speed_reg[19:16];
    
    assign sending_ball_speed = {slv_reg4_ballspeed2_pl[3:0], slv_reg4_ballspeed1_pl, slv_reg4_ballspeed0_pl};

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
            ball_send_trigger_reg <=0;
            safe_speed_reg <=1;
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

        is_idle_pl = 0;
        responsing_i2c_pl = 1'b0;
        case (state)
            IDLE: begin
                game_over_next  = 0;
                safe_speed_next = 1;
                ball_speed_next = 20'd270000;

                is_idle_pl = 1;
                // if (game_start) begin
                //     next = RUNNING_RIGHT;
                // end

                if (go_left) begin
                    next = WAIT;
                    ball_y_next = {slv_reg0_y0_pl[7:6], slv_reg1_y1_pl};
                    ball_x_next = 20;
                    ball_y_vel_next = slv_reg2_Yspeed_pl;
                    gravity_counter_next = slv_reg3_gravity_pl[1:0];
                    ball_speed_next = (sending_ball_speed == 20'd0) ? 20'd270000:sending_ball_speed;
                end
            end

            WAIT: begin
                responsing_i2c_pl = 1'b1;
                if (!go_left) begin
                    next = RUNNING_RIGHT;
                end
            end

            STOP: begin
                game_over_next = 1;
                if (game_start) begin
                    next = IDLE;
                    ball_send_trigger_next =0;
                end
            end

            SEND_BALL: begin
                ball_send_trigger_next =1;
                if (game_start) begin
                    next = IDLE;
                    ball_send_trigger_next =0;
                end
            end

            RUNNING_RIGHT: begin
                LED = 8'b0000_0100;
                game_over_next = 0;
                if (collision_detected) begin
                    next = RUNNING_LEFT;
                    ball_counter_next = 0;
                    x_counter_next = 0;
                end else if (ball_x_out >= (upscale ? 640 - 20 : 320 - 20)) begin
                    next = STOP;
                end else begin
                    if (ball_counter >= ball_speed_reg) begin
                        ball_x_next = ball_x_out + 10;
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
                LED = 8'b0000_1000;
                is_ball_moving_left = 1'b1;
                game_over_next = 0;

                if (collision_detected) begin
                    safe_speed_next = (estimated_speed < 2) ? 1.6 : estimated_speed;
                    ball_speed_next = 20'd270000 / safe_speed_next;
                end

                if (ball_x_out <= 0) begin
                    next = SEND_BALL;
                    ball_counter_next = 0;
                    x_counter_next = 0;
                    ball_speed_next = 20'd270000;  // 속도 초기화
                end else begin
                    if (ball_counter >= ball_speed_reg) begin
                        ball_x_next = ball_x_out - 10;
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
