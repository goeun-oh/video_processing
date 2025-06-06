`timescale 1ns / 1ps

module I2C_Controller(
    input  logic       clk,
    input  logic       reset,
    input  logic       ball_send_trigger,
    input  logic [9:0] ball_y,
    input  logic [7:0] ball_vy,
    input  logic       ready,
    output logic       start,
    output logic       stop,
    output logic       i2c_en,
    output logic [7:0] tx_data,
    input  logic       tx_done,
    output logic       is_transfer
);

    typedef enum{
        IDLE,
        WAIT,
        SEND_ADDR,
        SEND_DATA,
        STOP,
        DONE
    } state_t;

    state_t state, state_next;

    logic [7:0]  slv0_data0, slv0_data1, slv1_data0;
    logic [7:0] i2c_addr, tx_data_reg, tx_data_next;
    
    //state 관련//
    logic [1:0] state_cnt_reg, state_cnt_next; 
    //0: send addr, 1: send data, 2: stop
    logic [1:0] state_addr_reg, state_addr_next;

    //i2c 주소관련//
    assign i2c_addr = 8'haa;
    
    //i2c 전송 data 관련//
    assign slv0_data0 = {ball_y[9:8], 6'b0};  // 공 y 좌표의 최상위 2비트
    assign slv0_data1 = ball_y[7:0];  //공 y 좌표 나머지
    assign slv1_data0 = ball_vy;  //공 속도
    assign tx_data =tx_data_reg;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            state_cnt_reg <=0;
            state_addr_reg <=0;
            tx_data_reg <=0;
        end else begin
            state <= state_next;
            state_cnt_reg <= state_cnt_next;
            state_addr_reg <= state_addr_next;
            tx_data_reg <=tx_data_next;
        end
    end

    // 기본값
    always_comb begin
        start         = 0;
        stop          = 0;
        i2c_en        = 0;
        tx_data_next  = tx_data_reg;
        is_transfer = 1;
        state_next    = state;
        state_cnt_next = state_cnt_reg;
        state_addr_next = state_addr_reg;

        case (state)
            IDLE: begin
                state_cnt_next =0;
                state_addr_next =0;
                tx_data_next =0;
                is_transfer = 0;
                if (ball_send_trigger) begin
                    start =1;
                    state_next = WAIT;
                end
            end

            WAIT: begin
                if(ready) begin
                    case(state_cnt_reg)
                        2'd0: begin
                            state_next = SEND_ADDR;
                        end
                        2'd1: begin
                            state_next= SEND_DATA;
                        end
                        2'd2: begin
                            state_next = STOP;
                        end
                    endcase
                end
            end

            SEND_ADDR: begin
                tx_data_next = i2c_addr;
                i2c_en = 1;
                state_next = WAIT;
                state_cnt_next = state_cnt_reg +1;
            end

            SEND_DATA: begin
                i2c_en = 1;
                state_next =WAIT;
                case (state_addr_reg)
                    2'd0: begin
                        tx_data_next = slv0_data0; 
                        state_addr_next = state_addr_reg +1;
                    end
                    2'd1: begin
                        tx_data_next = slv0_data1; 
                        state_addr_next = state_addr_reg +1;
                    end
                    2'd3: begin
                        tx_data_next = slv1_data0;
                        state_addr_next =0;
                        state_cnt_next = state_cnt_reg +1;
                    end
                endcase
            end

            STOP: begin
                stop = 1;
                i2c_en = 1;
                state_next = DONE;
            end

            DONE: begin
                is_transfer = 0;
                state_next = IDLE;
            end
        endcase
    end

endmodule
