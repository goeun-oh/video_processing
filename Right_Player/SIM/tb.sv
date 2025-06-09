// i2c_game_sim_tb.sv
// Right Player용 통합 시뮬레이션 Testbench: game_controller → i2c_controller → i2c_master

`timescale 1ns / 1ps

module i2c_game_sim_tb;

    // 클럭 및 리셋
    logic clk;
    logic reset;
    initial clk = 0;
    always #10 clk = ~clk;  // 50MHz

    // 내부 연결 신호
    logic ball_send_trigger;
    logic [9:0] ball_y;
    logic [7:0] ball_vy;
    logic [1:0] gravity_counter = 2'b01;
    logic is_collusion = 0;
    logic ready;
    logic start, stop, i2c_en;
    logic [7:0] tx_data;
    logic tx_done;
    logic is_ball_moving_right;
    logic is_transfer;
    logic [7:0] master_led;
    logic send_lose_information;
    logic responsing_i2c;
    // SDA/SCL 시뮬레이션 (I2C 버스)
    logic scl;
    wire sda;


    // DUT 인스턴스 2: I2C_Controller
    I2C_Controller i2c_ctrl (
        .clk(clk),
        .reset(reset),
        .ball_send_trigger(ball_send_trigger),
        .ball_y(ball_y),
        .ball_vy(ball_vy),
        .gravity_counter(gravity_counter),
        .is_collusion(is_collusion),
        .ready(ready),
        .start(start),
        .stop(stop),
        .i2c_en(i2c_en),
        .tx_data(tx_data),
        .tx_done(tx_done),
        .is_ball_moving_right(is_ball_moving_right),
        .is_transfer(is_transfer),
        .master_led(master_led),
        .send_lose_information(send_lose_information)
    );

    // DUT 인스턴스 3: I2C_Master
    I2C_Master i2c_master (
        .clk(clk),
        .reset(reset),
        .start(start),
        .stop(stop),
        .i2c_en(i2c_en),
        .tx_data(tx_data),
        .SDA(sda),
        .SCL(scl),
        .ready(ready),
        .tx_done(tx_done)
    );

    // 초기 조건 및 시나리오
    initial begin
        reset = 1;
        #50;
        reset = 0;

        // 테스트: 공이 왼쪽 벽에 닿은 상황 유도 (ball_send_trigger 조건 만족)
        // game_controller 내부에서 처리된다는 가정하에 시뮬 진행

        #2000; // 충분히 FSM이 돌도록 대기
    end
endmodule
