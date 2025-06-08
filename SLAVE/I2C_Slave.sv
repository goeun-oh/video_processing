`timescale 1ns/1ps

module I2C_Slave(
    input  logic clk,
    input  logic reset,
    input  logic SCL,
    inout  logic SDA,
    output logic  [7:0] slv_reg0,
    output logic  [7:0] slv_reg1,
    output logic  [7:0] slv_reg2,
    output logic  [7:0] slv_reg3,
    output logic  [7:0] slv_reg4,
    output logic go_right,
    input logic responsing_i2c
);

    typedef enum { 
        IDLE,
        ADDR,
        ACK,
        DATA,
        DATA_ACK,
        STOP,
        WAIT
    } state_e;

    state_e state, state_next;
    reg [7:0] temp_rx_data_reg, temp_rx_data_next;
    reg [7:0] temp_tx_data_reg, temp_tx_data_next;
    reg [7:0] temp_addr_reg, temp_addr_next;
    reg [3:0] bit_counter_reg, bit_counter_next;
    reg [2:0] slv_count_reg, slv_count_next;
    reg en;
    reg o_data;



    reg sclk_sync0, sclk_sync1;
    wire sclk_rising, sclk_falling;

    reg sda_sync0, sda_sync1;
    wire sda_rising, sda_falling;

    reg [7:0] slv_reg0_reg, slv_reg0_next;
    reg [7:0] slv_reg1_reg, slv_reg1_next;
    reg [7:0] slv_reg2_reg, slv_reg2_next;
    reg [7:0] slv_reg3_reg, slv_reg3_next;
    reg [7:0] slv_reg4_reg, slv_reg4_next;

    assign SDA= en? o_data: 1'bz;
    
    assign slv_reg0 = slv_reg0_reg;
    assign slv_reg1 = slv_reg1_reg;
    assign slv_reg2 = slv_reg2_reg;
    assign slv_reg3 = slv_reg3_reg;
    assign slv_reg4 = slv_reg4_reg;


     always @(posedge clk or posedge reset) begin
         if(reset) begin
             state <= IDLE;
             sclk_sync0 <=1;
             sclk_sync1 <=1;
             sda_sync0 <=1;
             sda_sync1 <=1;
             temp_rx_data_reg <=0;
             bit_counter_reg <=0;
             temp_addr_reg <=0;
         end else begin
             state <= state_next;
             sclk_sync0 <= SCL;
             sclk_sync1 <= sclk_sync0;
             sda_sync0 <= SDA;
             sda_sync1  <= sda_sync0;
             temp_rx_data_reg <= temp_rx_data_next;
             bit_counter_reg <= bit_counter_next;
             temp_addr_reg <= temp_addr_next;
         end
     end

     always @(posedge clk or posedge reset) begin
        if(reset) begin
            slv_reg0_reg <=0;
            slv_reg1_reg <=0;
            slv_reg2_reg <=0;
            slv_count_reg <=0;
            slv_reg3_reg <= 0;
            slv_reg4_reg <= 0;
        end else begin
            slv_reg0_reg <= slv_reg0_next;
            slv_reg1_reg <= slv_reg1_next;
            slv_reg2_reg <= slv_reg2_next;
            slv_count_reg <= slv_count_next;
            slv_reg3_reg <= slv_reg3_next;
            slv_reg4_reg <= slv_reg4_next;
        end
     end

    assign sclk_rising = sclk_sync0 & ~sclk_sync1;
    assign sclk_falling = ~sclk_sync0 & sclk_sync1;

    assign sda_rising = sda_sync0 & ~sda_sync1;
    assign sda_falling = ~sda_sync0 & sda_sync1;

    always @(*) begin
        state_next = state;
        en = 1'b0;
        o_data = 1'b0;
        temp_rx_data_next = temp_rx_data_reg;
        bit_counter_next = bit_counter_reg;
        temp_addr_next = temp_addr_reg;
        slv_count_next = slv_count_reg;
        slv_reg0_next = slv_reg0_reg;
        slv_reg1_next = slv_reg1_reg;
        slv_reg2_next = slv_reg2_reg;
        slv_reg3_next = slv_reg3_reg;
        slv_reg4_next = slv_reg4_reg;
        go_right =0;
        case (state)
            IDLE: begin
                if(sclk_falling && ~SDA) begin
                    state_next = ADDR;
                    bit_counter_next = 0;
                    slv_count_next =0;
                end
            end
            ADDR: begin
                if(sclk_rising) begin
                    temp_addr_next = {temp_addr_reg[6:0], SDA};
                end
                if(sclk_falling) begin
                    if (bit_counter_reg == 8-1) begin
                        bit_counter_next = 0;
                        state_next = ACK;
                    end else begin
                        bit_counter_next = bit_counter_reg + 1;
                    end
                end
            end
            ACK: begin
                if (temp_addr_reg[7:1] == 7'b1010101) begin
                    en = 1'b1;
                    o_data =1'b0;
                    if(sclk_falling) begin
                        if(!temp_addr_reg[0]) begin
                            state_next=DATA;
                        end
                    end
                end else begin
                    state_next= IDLE;
                end
            end

            DATA: begin
                if(sclk_rising) begin
                    temp_rx_data_next = {temp_rx_data_reg[6:0], SDA};
                end
                if (sclk_falling) begin
                    if (bit_counter_reg == 8-1) begin
                        bit_counter_next = 0;
                        state_next = DATA_ACK;
                        slv_count_next= slv_count_reg + 1;
                        case(slv_count_reg)
                            3'd0: begin
                                slv_reg0_next = temp_rx_data_reg;
                            end
                            3'd1: begin
                                slv_reg1_next = temp_rx_data_reg;
                            end
                            3'd2: begin
                                slv_reg2_next = temp_rx_data_reg;
                            end
                            3'd3: begin
                                slv_reg3_next = temp_rx_data_reg;
                            end
                            3'd4: begin
                                slv_reg4_next = temp_rx_data_reg;
                            end
                        endcase
                    end else begin
                        bit_counter_next = bit_counter_reg + 1;
                    end
                end
                if(SCL && sda_rising) begin
                    state_next = STOP;
                end
            end
            DATA_ACK: begin
                en=1'b1;
                o_data =1'b0;
                if(sclk_falling) begin
                    state_next= DATA;
                end
            end
            STOP: begin
                if(SDA && SCL) begin
                    state_next = WAIT;
                    go_right = 1'b1;
                end
            end
            WAIT: begin
                go_right = 1'b1;
                if (responsing_i2c) begin
                    state_next = IDLE;
                end
            end
        endcase
    end

endmodule