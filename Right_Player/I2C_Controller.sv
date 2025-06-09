`timescale 1ns / 1ps

module I2C_Controller (
    input  logic       clk,
    input  logic       reset,
    input  logic       ball_send_trigger,
    input  logic [9:0] ball_y,
    input  logic [7:0] ball_vy,
    input  logic [1:0] gravity_counter,
    input  logic       is_collusion,
    input  logic       ready,
    output logic       start,
    output logic       stop,
    output logic       i2c_en,
    output logic [7:0] tx_data,
    input  logic       tx_done,
    input  logic       is_ball_moving_right,
    output logic       is_transfer,
    output logic [7:0] master_led,

    //상대 플레이어로 LOSE 정보 전송//
    input logic send_lose_information
);


    typedef enum {
        IDLE,
        START_WAIT,
        WAIT,
        SEND_ADDR,
        SEND_DATA,
        SEND_LOSE_DATA,
        STOP,
        DONE
    } state_t;

    state_t state, state_next;

    logic [7:0] slv0_data0, slv0_data0_next;  //vpos
    logic [7:0] slv0_data1, slv0_data1_next;  //vpos
    logic [7:0] slv1_data0, slv1_data0_next;  //vy
    logic [7:0] slv2_data0, slv2_data0_next;  //gravity
    logic [7:0] slv3_data0, slv3_data0_next;  //is collusion
    logic [7:0] slv4_data0, slv4_data0_next;  //send_lose_information
    logic [7:0] slv_addr, slv_addr_next;  //send_lose_information


    logic [7:0] i2c_addr, slv_addr0, slv_addr4, tx_data_reg, tx_data_next;
    //state 관련//
    logic [1:0] state_cnt_reg, state_cnt_next;
    //0: send addr, 1: send data, 2: stop
    logic [2:0] state_addr_reg, state_addr_next;

    //i2c 주소관련//
    assign i2c_addr = 8'haa;
    assign slv_addr0 = 8'h00;
    assign slv_addr4 = 8'h04;

    //i2c 전송 data 관련//

    assign tx_data  = tx_data_reg;

    logic ball_send_to_slave_next;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            state_cnt_reg <= 0;
            state_addr_reg <= 0;
            tx_data_reg <= 0;
            slv0_data0 <= 0;
            slv0_data1 <= 0;
            slv1_data0 <= 0;
            slv2_data0 <= 0;
            slv3_data0 <= 0;
            slv4_data0 <= 0;
            slv_addr <=0;

        end else begin
            state <= state_next;
            state_cnt_reg <= state_cnt_next;
            state_addr_reg <= state_addr_next;
            tx_data_reg <= tx_data_next;
            slv0_data0 <= slv0_data0_next;
            slv0_data1 <= slv0_data1_next;
            slv1_data0 <= slv1_data0_next;
            slv2_data0 <= slv2_data0_next;
            slv3_data0 <= slv3_data0_next;
            slv4_data0 <= slv4_data0_next;
            slv_addr <= slv_addr_next;
        end
    end

    // 기본값
    always_comb begin
        start           = 0;
        stop            = 0;
        i2c_en          = 0;
        tx_data_next    = tx_data_reg;
        is_transfer     = 1;
        state_next      = state;
        state_cnt_next  = state_cnt_reg;
        state_addr_next = state_addr_reg;
        slv0_data0_next = slv0_data0;
        slv0_data1_next = slv0_data1;
        slv1_data0_next = slv1_data0;
        slv2_data0_next = slv2_data0;
        slv3_data0_next = slv3_data0;
        slv4_data0_next = slv4_data0;
        slv_addr_next =slv_addr;

        case (state)
            IDLE: begin
                state_cnt_next = 0;
                state_addr_next = 0;
                tx_data_next = 0;
                is_transfer = 0;
                ball_send_to_slave_next = 0;
                slv_addr_next = 8'h00;
                master_led = 8'h01;  // LED 상태 초기화
                if (ball_send_trigger) begin    
                    ball_send_to_slave_next = 1;
                    start = 1;
                    i2c_en = 1;
                    state_next = START_WAIT;
                    tx_data_next = i2c_addr;
                    slv_addr_next = slv_addr0;
                    slv0_data0_next = {
                        ball_y[9:8], 6'b0
                    };  // 공 y 좌표의 최상위 2비트
                    slv0_data1_next = ball_y[7:0];  //공 y 좌표 나머지
                    slv1_data0_next = ball_vy;  //공 속도
                    slv2_data0_next = {6'b0, gravity_counter};
                    slv3_data0_next = {7'b0, is_collusion};
                end
                if (send_lose_information) begin
                    start = 1;
                    i2c_en = 1;
                    state_next = START_WAIT;
                    tx_data_next = i2c_addr;
                    slv4_data0_next = {7'b0, send_lose_information};
                    slv_addr_next = slv_addr4;
                end
            end

            START_WAIT: begin
                master_led = 8'b0000_0010;
                start  = 1;
                i2c_en = 1;
                if (!ready) begin
                    state_next = WAIT;
                end
            end

            WAIT: begin
                master_led = 8'b0000_0100;
                if (ready) begin
                    case (state_cnt_reg)
                        2'd0: begin
                             state_next = SEND_ADDR;
                         end
                        2'd1: begin
                            state_next = SEND_DATA;
                        end
                        2'd2 : begin
                            state_next = SEND_LOSE_DATA;
                        end
                        2'd3: begin
                            state_next = STOP;
                        end
                    endcase
                end
            end

             SEND_ADDR: begin
                 master_led = 8'b0000_1000;
                 tx_data_next = slv_addr;
                 i2c_en = 1;
                 if(!ready) begin
                     state_next = WAIT;
                     case(slv_addr)
                        8'h00: state_cnt_next = 1;
                        8'h04: state_cnt_next = 2;
                     endcase
                 end
             end

            SEND_DATA: begin
                master_led = 8'b0001_0000;
                i2c_en   = 1;
                if (!ready) begin
                    state_next = WAIT;
                    state_addr_next = state_addr_reg + 1;
                    if (state_addr_reg == 3'd4) begin
                        state_cnt_next  = 3;
                        state_addr_next = 0;
                    end
                end
                case (state_addr_reg)
                    3'd0: begin
                        tx_data_next = slv0_data0;
                    end
                    3'd1: begin
                        tx_data_next = slv0_data1;
                    end
                    3'd2: begin
                        tx_data_next = slv1_data0;
                    end
                    3'd3: begin
                        tx_data_next = slv2_data0;
                    end
                    3'd4: begin
                        tx_data_next = slv3_data0;
                    end
                endcase
                if (is_ball_moving_right) begin
                    state_next = IDLE;
                end
            end

            SEND_LOSE_DATA: begin
                master_led = 8'b0010_0000;
                i2c_en = 1;
                if (!ready) begin
                    state_next = WAIT;
                    state_cnt_next = 3;
                end
                tx_data_next = slv4_data0;
            end

            STOP: begin
                master_led = 8'b0100_0000;
                stop = 1;
                i2c_en = 1;
                if (!ready) begin
                    state_next = DONE;
                end
            end

            DONE: begin
                master_led = 8'b1000_0000;
                is_transfer = 0;
                state_next = IDLE;
            end
        endcase
    end

endmodule
