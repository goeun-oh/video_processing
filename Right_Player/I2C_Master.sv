`timescale 1ns / 1ps

module I2C_Master (
    input   logic          clk,
    input   logic          reset,
    input   logic   [ 7:0] tx_data,
    output  logic          tx_done,      //곧 ACK 같은 역할?
    output   logic         ready,
    input    logic         start,
    input    logic         i2c_en,
    input    logic         stop,
    output   logic         SCL,
    inout    logic         SDA
);

    logic [7:0] master_led;
    
    typedef enum { 
        IDLE,
        START1,
        START2,
        HOLD,
        WRITE,
        WRITE_ACK,
        STOP1,
        STOP2
    } state_e;

    parameter FCOUNT = 500;
    state_e state, state_next;
    reg tx_done_reg, tx_done_next;
    reg [$clog2(FCOUNT)-1:0] sclk_counter_reg, sclk_counter_next;
    reg [7:0] temp_tx_data_reg, temp_tx_data_next;
    reg [3:0] bit_counter_reg, bit_counter_next;
    reg write_ack_reg, write_ack_next;
    reg [2:0] slv_count_reg, slv_count_next;

    //SCL//
    reg tick_sample;
    reg scl_en;
    reg internal_scl;
    reg gen_scl;
    reg sclk_sync0, sclk_sync1;
    wire sclk_rising = sclk_sync0 & ~sclk_sync1;
    wire sclk_falling = ~sclk_sync0 & sclk_sync1;
    
    //SDA//
    reg  sda_en;
    reg  o_data;

    assign SCL = scl_en ? gen_scl : internal_scl;
    assign SDA = sda_en ? o_data : 1'bz;
    assign tx_done = tx_done_reg;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            sclk_counter_reg <= 0;
            temp_tx_data_reg <= 8'b1111_1111;
            bit_counter_reg <= 0;
            tx_done_reg <= 0;
            write_ack_reg <=1'bz;
        end else begin
            state <= state_next;
            sclk_counter_reg <= sclk_counter_next;
            temp_tx_data_reg <= temp_tx_data_next;
            bit_counter_reg <= bit_counter_next;
            tx_done_reg <= tx_done_next;
            write_ack_reg <= write_ack_next;
        end
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            sclk_sync0 <= 1;
            sclk_sync1 <= 1;
            slv_count_reg <=0;
        end else begin
            sclk_sync0 <= SCL;
            sclk_sync1 <= sclk_sync0;
            slv_count_reg <= slv_count_next;
        end
    end

    always @(*) begin
        state_next = state;
        sclk_counter_next = sclk_counter_reg;
        temp_tx_data_next = temp_tx_data_reg;
        bit_counter_next = bit_counter_reg;
        tx_done_next = tx_done_reg;
        ready = 0;
        slv_count_next  = slv_count_reg;
        write_ack_next = write_ack_reg;
        //SCL//

        internal_scl = 1'b1;
        scl_en = 1'b0;

        //SDA//

        sda_en = 1'b1;
        o_data = 1'b1;

        case (state)
            IDLE: begin
                master_led = 8'h01;
                o_data = 1'b1;
                ready = 1;
                if (start && i2c_en) begin
                    state_next = START1;
                    sclk_counter_next = 0;
                    temp_tx_data_next = tx_data;
                    bit_counter_next = 0;
                    slv_count_next =0;
                end
            end
            START1: begin
                master_led = 8'b0000_0010;
                o_data = 1'b0;
                if (sclk_counter_reg == FCOUNT - 1) begin
                    state_next = START2;
                    sclk_counter_next = 0;
                end else begin
                    sclk_counter_next = sclk_counter_reg + 1;
                end
            end
            START2: begin
                master_led = 8'b0000_0100;

                o_data = 1'b0;
                internal_scl = 1'b0;

                if (sclk_counter_reg == FCOUNT - 1) begin
                    sclk_counter_next = 0;
                    state_next = HOLD;
                end else begin
                    sclk_counter_next = sclk_counter_reg + 1;
                end
            end
            HOLD: begin
                master_led = 8'b0000_1000;

                state_next = HOLD;
                internal_scl = 1'b0;
                o_data = 1'b0;
                ready = 1;
                write_ack_next = 1'bz;

                if (i2c_en) begin
                    case ({
                        start, stop
                    })
                        2'b00: begin
                            state_next = WRITE;
                            tx_done_next = 0;
                            temp_tx_data_next = tx_data;
                            scl_en = 1'b1;
                        end
                        //2'b10: state_next = START1;

                        2'b01: begin
                            state_next   = STOP1;
                            tx_done_next = 0;
                        end
                        default: state_next = HOLD;
                    endcase
                end
            end
            WRITE: begin
                master_led = 8'b0001_0000;

                o_data = temp_tx_data_reg[7];
                scl_en = 1'b1;
                if (tick_sample) begin
                    temp_tx_data_next = {temp_tx_data_reg[6:0], 1'b0};
                    if (bit_counter_reg == 8 - 1) begin
                        bit_counter_next = 0;
                        state_next = WRITE_ACK;
                        tx_done_next =1'b1;
                    end else begin
                        bit_counter_next = bit_counter_reg + 1;
                    end
                end
            end
    
            WRITE_ACK: begin
                master_led = 8'b0010_0000;

                scl_en = 1'b1;
                sda_en = 1'b0;
                if (sclk_rising) begin
                    write_ack_next = SDA;
                end
                if(tick_sample) begin
                    if(write_ack_reg == 1'b0)
                        state_next = HOLD;
                end
            end

            STOP1: begin
                master_led = 8'b0100_0000;

                o_data = 1'b0;
                internal_scl = 1'b1;
                ready = 0;
                tx_done_next = 0;

                if (sclk_counter_next == FCOUNT - 1) begin
                    state_next = STOP2;
                    sclk_counter_next = 0;
                end else begin
                    sclk_counter_next = sclk_counter_reg + 1;
                end
            end
            STOP2: begin
                master_led = 8'b1000_0000;

                o_data = 1'b1;
                internal_scl = 1'b1;
                ready = 0;
                tx_done_next = 0;

                if (sclk_counter_next == FCOUNT - 1) begin
                    state_next = IDLE;
                    sclk_counter_next = 0;
                end else begin
                    sclk_counter_next = sclk_counter_reg + 1;
                end
            end
        endcase
    end

    parameter CLK3 = 1000, CLK0= 250, CLK1=500, CLK2=750;

    reg [$clog2(CLK3)-1:0] counter_reg, counter_next;
    

    always @(posedge clk or posedge reset) begin
        if(reset) begin
            counter_reg <=0;
            gen_scl <=0;
            tick_sample <=1;
        end else begin
            counter_reg <= counter_next;
            if(scl_en) begin
                if(counter_reg >= 0 && counter_reg < CLK0-1) begin
                    counter_reg <= counter_reg +1;
                    gen_scl <=0;
                    tick_sample <=0;
                end else if(counter_reg >= CLK0-1 && counter_reg < CLK1-1) begin
                    counter_reg <= counter_reg +1;
                    gen_scl <=1;
                    tick_sample <=0;
                end else if(counter_reg >= CLK1-1 && counter_reg < CLK2-1) begin
                    counter_reg <= counter_reg +1;
                    gen_scl <=1;
                    tick_sample <=0;
                end else if (counter_reg >= CLK2-1 && counter_reg < CLK3-1-1) begin
                    counter_reg <= counter_reg +1;
                    gen_scl <=0;
                    tick_sample <=0;
                end else if (counter_reg == CLK3 -1-1)begin
                    counter_reg <= counter_reg +1;
                    gen_scl <=0;
                    tick_sample <=1;
                end else if (counter_reg == CLK3-1) begin
                    counter_reg <= 0;
                    gen_scl <=0;
                    tick_sample <=0;
                end
            end else begin
                counter_reg <= 0;
                gen_scl <=0;
                tick_sample <=1;
            end
        end
    end

endmodule

