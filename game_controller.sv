`timescale 1ns / 1ps

module game_controller(
    input logic clk_25MHZ,
    input logic reset,
    output logic [9:0] ball_x_out,    // 공의 X 좌표
    output logic [9:0] ball_y_out,     // 공의 Y 좌표 (고정)

    input logic upscale,
    input logic collision_detected,

    input logic [9:0] estimated_speed
    );


    // 상태 정의
    typedef enum logic [1:0] {
        IDLE          = 0,
        RUNNING_RIGHT = 1,
        RUNNING_LEFT  = 2
    } state_t;

    state_t state, next;

    // 공 위치
    logic [9:0] ball_x_next, ball_y_next;

    logic [19:0] ball_counter, ball_counter_next;
    logic [19:0] ball_speed = (estimated_speed > 20) ? 20'd125000 : 20'd270000;

    // 상태 레지스터 및 위치 업데이트
    always_ff @(posedge clk_25MHZ or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            ball_x_out <= 100;
            ball_y_out <= 80;
            ball_counter <= 0;
        end
        else begin
            state <= next;
            ball_x_out <= ball_x_next;
            ball_y_out <= ball_y_next;
            ball_counter <= ball_counter_next;
        end
    end

    // 다음 상태 결정
    always_comb begin
        next = state;
        ball_x_next = ball_x_out;
        ball_y_next = ball_y_out;
        ball_counter_next = ball_counter;
        case (state)
            IDLE: begin
                next = RUNNING_LEFT;
            end

            RUNNING_RIGHT: begin
                if (upscale) begin
                    if ((ball_x_out >= 640 - 20) || collision_detected) begin
                        next = RUNNING_LEFT;
                        ball_counter_next = 0;
                    end
                    else begin
                        if (ball_counter >= ball_speed) begin
                            ball_x_next = ball_x_out + 1;
                            ball_counter_next = 0;
                        end
                        else begin
                            ball_counter_next = ball_counter + 1;
                        end
                    end
                end

                else begin
                    if ((ball_x_out >= 320 - 20) || collision_detected) begin
                        next = RUNNING_LEFT;
                        ball_counter_next = 0;
                    end
                    else begin
                        if (ball_counter >= ball_speed) begin
                            ball_x_next = ball_x_out + 1;
                            ball_counter_next = 0;
                        end
                        else begin
                            ball_counter_next = ball_counter + 1;
                        end
                    end
                end
            end

            RUNNING_LEFT: begin
                if (ball_x_out == 0) begin
                    next = RUNNING_RIGHT;
                    ball_x_next = ball_x_out + 1; // 반사 직후 이동
                    ball_counter_next = 0;
                end
                else begin
                    if (ball_counter >= ball_speed) begin
                        ball_x_next = ball_x_out - 1;
                        ball_counter_next = 0;
                    end
                    else begin
                        ball_counter_next = ball_counter + 1;
                    end
                end
            end
        endcase
    end

endmodule

